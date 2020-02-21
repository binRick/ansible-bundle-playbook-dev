#!/home/whmcs/public_html/whmcs/modules/addons/vpntech/submodules/ansible-bundle-playbook-dev/compiler/test4/.venv/bin/python3
# EASY-INSTALL-ENTRY-SCRIPT: 'tmuxp==1.5.4','console_scripts','tmuxp'
import tmuxp
#__requires__ = 'tmuxp==1.5.4'
import re
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(
        load_entry_point('tmuxp==1.5.4', 'console_scripts', 'tmuxp')()
    )
