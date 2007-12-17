#!/usr/bin/env twistd -y
#
# NOTES:
# 9090/test seems not to work. check with and without slash
# should do all comparisons by stripping slashes

config = {
    'port':9998,
    'version':'3.0-Beta2.3',
    'agentprefix':'OMERO',
    'redirect':'http://trac.openmicroscopy.org.uk/omero/wiki/UpgradeCheck',
    'upgrade':'Please upgrade to 3.0-Beta2.3 See http://trac.openmicroscopy.org.uk/omero for the latest version'
    }

from twisted.application import internet, service
from twisted.web import static, server
from twisted.web.resource import Resource
from twisted.web.util import redirectTo

import logging, types, re

VALID = re.compile("^[\-\w.]+$")
INVALID = re.compile("\s")

#
# Configure logging for the access items into
# a file separate from the stdout/stderr logging
# done by twistd
#
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                    datefmt='%m-%d %H:%M',
                    filename='access.log',
                    filemode='a')
access = logging.getLogger('OMERO.registry.access')

# Timestamp to twistd.log to correlate with the access.log
print "Starting OMERO.registry"

class ReportResource(Resource):
    """
    Main entity in this file.
    This class is used to render all GET calls made to this host and port.
    See render_GET.
    """

    def __init__(self):
        """
        Currently unused initialization.
        """
        Resource.__init__(self)

    def render_GET(self, request):
        """
        Main method in this file. Uses the GET arguments to determine
        whether or not an upgrade command should be sent. If the user-agent
        for the connection is wrong, or an argument is missing, then
        a redirect will be sent.
        """

        # Debug
        import os
        try:
            if os.environ["DEBUG"] == "1":
                import pdb
                pdb.set_trace()
        except KeyError:
            pass

        #
        # Input
        #

        args = dict(request.args)
        for key in args.keys():
            value = args[key]
            if isinstance(value, types.ListType):
                args[key] = value[0]

        args["ip"] = request.getClientIP()
        if not args.has_key('poll'):
            args['poll'] = 'unknown'
        else:
            try:
                args['poll'] = int(args['poll'])
            except ValueError:
                args['poll'] = 'unknown'

        #
        # Output
        #

        # If the "API" is not adhered to (there are missing
        # parameters, then user will also be redirected.
        if not args.has_key('version'):
            return self.redirect(args, request)
        args['version'] = args['version'].replace("\n","NEWLINE")

        # If not an "OMERO" user-agent, redirect to the page on
        # upgrade checks.
        userAgent = request.getHeader('user-agent')
        if not userAgent.startswith(config['agentprefix']):
            return self.redirect(args, request)

        # Otherwise, return either an upgrade comment or blank
        access.info("Check: %(ip)s %(poll)s %(version)s" % args)
        if args['version'] != config['version']:
                output = config["upgrade"]
        else:
                output = ""
        return (output)


    def redirect(self, args, request):
        access.info("Redirect: %(ip)s" % args)
        return redirectTo(config['redirect'], request)


    def getChild(self, name, request):
        """
        Guarantees that whatever resource is requested
        it will always be handled by the render_GET method.
        """
	return self

#
# This is the standard bit which lets twistd
# do its magic. Should not need to be modified.
#

root = ReportResource()
application = service.Application('web')
site = server.Site(root)
sc = service.IServiceCollection(application)
i = internet.TCPServer(config['port'], site)
i.setServiceParent(sc)

