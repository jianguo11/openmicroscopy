#!/usr/bin/env python
"""
   Plugin for our managing the OMERO database.

   Plugin read by omero.cli.Cli during initialization. The method(s)
   defined here will be added to the Cli class for later use.

   Copyright 2008 Glencoe Software, Inc. All rights reserved.
   Use is subject to license terms supplied in LICENSE.txt

"""

from exceptions import Exception
from omero.cli import Arguments, BaseControl, VERSION
import omero.java
import time

HELP=""" omero db [ script ]

Database tools:

     script - Generates a script for creating an OMERO database

"""
class DatabaseControl(BaseControl):

    def help(self, args = None):
        self.ctx.out(HELP)

    def _lookup(self, data, data2, key, map, hidden = False):
        """
        Read values from data and data2. If value is contained in data
        then use it without question. If the value is in data2, offer
        it as a default
        """
        map[key] = data.properties.getProperty("omero.db."+key)
        if not map[key] or map[key] == "":
            if data2:
                default = data2.properties.getProperty("omero.db."+key)
            else:
                default = ""
            map[key] = self.ctx.input("Please enter omero.db.%s [%s]: " % (key, default), hidden)
            if not map[key] or map[key] == "":
                map[key] = default
        if not map[key] or map[key] == "":
                self.ctx.die(1, "No value entered")

    def _get_password_hash(self, root_pass = None):

        root_pass = self._ask_for_password(" for OMERO root user", root_pass)

        server_jar = self.ctx.dir / "lib" / "server" / "server.jar"
        p = omero.java.popen(["-cp",str(server_jar),"ome.security.PasswordUtil",root_pass])
        rc = p.wait()
        if rc != 0:
            self.ctx.die(rc, "PasswordUtil failed: %s" % p.communicate() )
        value = p.communicate()[0]
        if not value or len(value) == 0:
            self.ctx.die(100, "Encoded password is empty")
        return value.strip()

    def _copy(self, input_path, output, func, cfg = None):
            input = open(str(input_path))
            try:
                for s in input.xreadlines():
                        try:
                            if cfg:
                                output.write(func(s) % cfg)
                            else:
                                output.write(func(s))
                        except Exception, e:
                            self.ctx.die(154, "Failed to map line: %s\nError: %s" % (s, e))
            finally:
                input.close()

    def _make_replace(self, root_pass, db_vers, db_patch):
        def replace_method(str_in):
                str_out = str_in.replace("@ROOTPASS@",root_pass)
                str_out = str_out.replace("@DBVERSION@",db_vers)
                str_out = str_out.replace("@DBPATCH@",db_patch)
                return str_out
        return replace_method

    def _db_profile(self):
        import re
        server_lib = self.ctx.dir / "lib" / "server"
        model_jars = server_lib.glob("model-*.jar")
        if len(model_jars) != 1:
            self.ctx.die(200, "Invalid model-*.jar state: %s" % ",".join(model_jars))
        model_jar = model_jars[0]
        model_jar = str(model_jar.basename())
        match = re.search("model-(.*?).jar", model_jar)
        return match.group(1)

    def _sql_directory(self, db_vers, db_patch):
        """
        See #2689
        """
        dbprofile = self._db_profile()
        sql_directory = self.ctx.dir / "sql" / dbprofile / ("%s__%s" % (db_vers, db_patch))
        if not sql_directory.exists():
            self.ctx.die(2, "Invalid Database version/patch: %s does not exist" % sql_directory)
        return sql_directory

    def _create(self, sql_directory, db_vers, db_patch, password_hash, location = None):
        sql_directory = self._sql_directory(db_vers, db_patch)
        if not sql_directory.exists():
            self.ctx.die(2, "Invalid Database version/patch: %s does not exist" % sql_directory)

        script = "%s__%s.sql" % (db_vers, db_patch)
        if not location:
            location = path().getcwd() / script

        output = open(location, 'w')
        print "Saving to " + location

        try:
            cfg = {"TIME":time.ctime(time.time()),
                   "DIR":sql_directory,
                   "SCRIPT":script}
            dbprofile = self._db_profile()
            header = sql_directory / ("%s-header.sql" % dbprofile)
            footer = sql_directory / ("%s-footer.sql" % dbprofile)
            self._copy(header, output, str, cfg)
            self._copy(sql_directory/"schema.sql", output, str)
            self._copy(sql_directory/"views.sql", output, str)
            self._copy(footer, output,
                self._make_replace(password_hash, db_vers, db_patch), cfg)
        finally:
            output.flush()
            output.close()

    def password(self, *args):
        args = Arguments(*args)
        root_pass = None
        try:
            root_pass = args.args[0]
        except Exception, e:
            self.ctx.dbg("While getting arguments:" + str(e))
        password_hash = self._get_password_hash(root_pass)
        self.ctx.out("""UPDATE password SET hash = '%s' WHERE experimenter_id = 0;""" % password_hash)

    def script(self, *args):
        args = Arguments(*args)

        data = self.ctx.initData({})
        try:
            data2 = self.ctx.initData({})
            output = self.ctx.readDefaults()
            self.ctx.parsePropertyFile(data2, output)
        except Exception, e:
            self.ctx.dbg(str(e))
            data2 = None
        map = {}
        root_pass = None
        try:
            data.properties.setProperty("omero.db.version", args.args[0])
            self.ctx.out("Using %s for version" % args.args[0])
            data.properties.setProperty("omero.db.patch", args.args[1])
            self.ctx.out("Using %s for patch" % args.args[1])
            root_pass = args.args[2]
            self.ctx.out("Using password from commandline")
        except Exception, e:
            self.ctx.dbg("While getting arguments:"+str(e))
        self._lookup(data, data2, "version", map)
        self._lookup(data, data2, "patch", map)
        sql = self._sql_directory(map["version"],map["patch"])
        map["pass"] = self._get_password_hash(root_pass)
        self._create(sql,map["version"],map["patch"],map["pass"])

try:
    register("db", DatabaseControl)
except NameError:
    DatabaseControl()._main()
