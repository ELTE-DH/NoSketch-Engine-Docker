#!/usr/bin/python3
# -*- Python -*-
# Copyright (c) 2003-2020  Pavel Rychly, Vojtech Kovar, Milos Jakubicek,
#                          Vit Baisa

import cgitb; cgitb.enable()

import sys, os
if '/usr/local/lib/python3.9/site-packages' not in sys.path:
    sys.path.insert (0, '/usr/local/lib/python3.9/site-packages')

if '/usr/local/lib/python3.9/site-packages/bonito' not in sys.path:
    sys.path.insert (0, '/usr/local/lib/python3.9/site-packages/bonito')

try:
    from wseval import WSEval
except:
    from conccgi import ConcCGI
    from usercgi import UserCGI
    class WSEval(ConcCGI):
        pass

# Following might be needed for CORS compliance if XHR requests are coming from a different domain
# You may also set it in the webserver configuration instead, see the .htaccess file in
# Bonito distribution tarball for an Apache-based example
#
#print('Access-Control-Allow-Origin: http://localhost:3001')
#print('Access-Control-Allow-Credentials: true')
#print('Access-Control-Allow-Headers: content-type')

from conccgi import ConcCGI
from usercgi import UserCGI
# wmap must be imported before manatee

class BonitoCGI (WSEval, UserCGI):

    _anonymous = True
    _data_dir = '/var/lib/bonito'

    # UserCGI options
    _options_dir = _data_dir + '/options'
    _job_dir = _data_dir + '/jobs'

    # ConcCGI options
    _cache_dir = _data_dir + '/cache'
    _tmp_dir = _data_dir + '/tmp'
    subcpath = [_data_dir + '/subcorp/GLOBAL']
    gdexpath = [] # [('confname', '/path/to/gdex.conf'), ...]
    user_gdex_path = "" # /path/to/%s/gdex/ %s to be replaced with username

    # TODO: Read corpora list runtime from registry
    # set available corpora, e.g.: corplist = ['susanne', 'bnc', 'biwec']
    if 'MANATEE_REGISTRY' not in os.environ:
        # TODO: SET THIS APROPRIATELY!
        os.environ['MANATEE_REGISTRY'] = '/corpora/registry'
    corplist = [corp_name for corp_name in os.listdir(os.environ['MANATEE_REGISTRY'])]
    # set default corpus
    if len(corplist) > 0:
        corpname = corplist[0]
    else:
        corpname = 'susanne'
    err_types_select = False

    def __init__ (self, user=None):
        if user:
            self._ca_user_info = None
        UserCGI.__init__ (self, user)
        ConcCGI.__init__ (self)

    def _user_defaults (self, user):
        if user is not self._default_user:
            self.subcpath.append (self._data_dir + '/subcorp/%s' % user)
        self._conc_dir = self._data_dir + '/conc/%s' % user
        self._wseval_dir = self._data_dir + '/wseval/%s' % user


if __name__ == '__main__':
    # use run.cgi <url> <username> for debugging
    if len(sys.argv) > 1:
        from urllib.parse import urlsplit
        us = urlsplit(sys.argv[1])
        os.environ['REQUEST_METHOD'] = 'GET'
        os.environ['REQUEST_URI'] = sys.argv[1]
        os.environ['PATH_INFO'] = "/" + us.path.split("/")[-1]
        os.environ['QUERY_STRING'] = us.query
    if len(sys.argv) > 2:
        username = sys.argv[2]
    else:
        username = None
    if 'MANATEE_REGISTRY' not in os.environ:
        # TODO: SET THIS APROPRIATELY!
        os.environ['MANATEE_REGISTRY'] = '/corpora/registry'
    if ";prof=" in os.environ['QUERY_STRING'] or "&prof=" in os.environ['QUERY_STRING']:
        import cProfile, pstats, tempfile
        proffile = tempfile.NamedTemporaryFile()
        cProfile.run('''BonitoCGI().run_unprotected (selectorname="corpname",
                        outf=open(os.devnull, "w"))''', proffile.name)
        profstats = pstats.Stats(proffile.name)
        print("<pre>")
        profstats.sort_stats('time','calls').print_stats(50)
        profstats.sort_stats('cumulative').print_stats(50)
        print("</pre>")
    else:
        BonitoCGI(user=username).run_unprotected (selectorname='corpname')

# vim: ts=4 sw=4 sta et sts=4 si tw=80:
