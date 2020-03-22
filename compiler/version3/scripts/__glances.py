# EASY-INSTALL-ENTRY-SCRIPT: 'Glances==3.1.3','console_scripts','glances'
__requires__ = 'Glances==3.1.3'
import re
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    if len(sys.argv) == 2 and (sys.argv[1] == '--help' or sys.argv[1] == '--version'):
        print('Glances OK')
        sys.exit(0)
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(
        load_entry_point('Glances==3.1.3', 'console_scripts', 'glances')()
    )
