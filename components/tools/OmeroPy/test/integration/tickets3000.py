#!/usr/bin/env python

"""
   Integration tests for tickets between 2000 and 2999
   a running server.

   Copyright 2010 Glencoe Software, Inc. All rights reserved.
   Use is subject to license terms supplied in LICENSE.txt

"""
import unittest, time
import integration.library as lib
from omero.rtypes import *

class TestTickets3000(lib.ITest):

    def test2396(self):
        uuid = self.uuid()

        # create image
        img = self.new_image()
        img.setName(rstring('test2396-img-%s' % (uuid)))
        img = self.update.saveAndReturnObject(img)
        img.unload()

        format = "txt"
        binary = "12345678910"
        oFile = omero.model.OriginalFileI()
        oFile.setName(rstring(str("txt-name")));
        oFile.setPath(rstring(str("txt-name")));
        oFile.setSize(rlong(len(binary)));
        oFile.setSha1(rstring("pending"));
        oFile.setMimetype(rstring(str(format)));

        of = self.update.saveAndReturnObject(oFile);

        store = self.client.sf.createRawFileStore()
        store.setFileId(of.id.val);
        store.write(binary, 0, 0)
        of = store.save() # See ticket:1501
        store.close()

        fa = omero.model.FileAnnotationI()
        fa.setFile(of)
        l_ia = omero.model.ImageAnnotationLinkI()
        l_ia.setParent(img)
        l_ia.setChild(fa)
        self.update.saveObject(l_ia)

        # Alternatively, unload the file
        of = self.update.saveAndReturnObject(oFile);
        of.unload()

        store = self.client.sf.createRawFileStore()
        store.setFileId(of.id.val);
        store.write(binary, 0, 0)
        # Don't capture from save, but will be saved anyway.
        store.close()

        fa = omero.model.FileAnnotationI()
        fa.setFile(of)
        l_ia = omero.model.ImageAnnotationLinkI()
        l_ia.setParent(img)
        l_ia.setChild(fa)
        self.update.saveObject(l_ia)

    def test2547(self):
        admin = self.root.sf.getAdminService()
        user = self.new_user()
        grps = admin.containedGroups(user.id.val)
        self.assertEquals(2, len(grps))
        non_user = [x for x in grps if x.id.val != 1][0]
        grp = self.new_group()
        admin.addGroups(user, [grp])
        admin.removeGroups(user, [non_user])
        admin.lookupExperimenters()

if __name__ == '__main__':
    unittest.main()