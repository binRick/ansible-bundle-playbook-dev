#!/home/whmcs/public_html/whmcs/modules/addons/vpntech/submodules/ansible-bundle-playbook-dev/compiler/test4/.venv/bin/python3

# -*- coding: utf-8 -*-
import re
import sys

from tcconfig.tcset import main

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(main())
