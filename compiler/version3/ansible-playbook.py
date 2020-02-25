
# (c) 2012, Michael DeHaan <michael.dehaan@gmail.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

########################################################
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type



import os
import sys
import os.path as op
try:
    this_file = __file__
except NameError:
    this_file = sys.argv[0]
this_file = op.abspath(this_file)
if getattr(sys, 'frozen', False):
    application_path = getattr(sys, '_MEIPASS', op.dirname(sys.executable))
else:
    application_path = op.dirname(this_file)

sys.path.append(os.path.dirname('{}/lib/file'.format(application_path)))



print('\n         [0]  application_path={}\n'.format(application_path))
print('\n         [0]  sys.path={}\n'.format(sys.path))

import os
import shutil
import sys

if 'LIB_PATH' in os.environ.keys():
    sys.path.append(os.path.dirname(os.environ['LIB_PATH']))

print('         sys.path={}'.format(sys.path))




if getattr(sys, 'frozen', False):
    # If the application is run as a bundle, the pyInstaller bootloader
    # extends the sys module by a flag frozen=True and sets the app 
    # path into variable _MEIPASS'.
    application_path = sys._MEIPASS
else:
    application_path = os.path.dirname(os.path.abspath(__file__))

print('        [application_path]={}'.format(application_path))

#sys.path.insert(0, 'lib')

__requires__ = ['ansible']
import traceback

from ansible import context
from ansible.errors import AnsibleError, AnsibleOptionsError, AnsibleParserError
from ansible.module_utils._text import to_text


# Used for determining if the system is running a new enough python version
# and should only restrict on our documented minimum versions
_PY3_MIN = sys.version_info[:2] >= (3, 5)
_PY2_MIN = (2, 6) <= sys.version_info[:2] < (3,)
_PY_MIN = _PY3_MIN or _PY2_MIN
if not _PY_MIN:
    raise SystemExit('ERROR: Ansible requires a minimum of Python2 version 2.6 or Python3 version 3.5. Current version: %s' % ''.join(sys.version.splitlines()))


class LastResort(object):
    # OUTPUT OF LAST RESORT
    def display(self, msg, log_only=None):
        print(msg, file=sys.stderr)

    def error(self, msg, wrap_text=None):
        print(msg, file=sys.stderr)


if __name__ == '__main__':

    display = LastResort()

    try:  # bad ANSIBLE_CONFIG or config options can force ugly stacktrace
        import ansible.constants as C
        from ansible.utils.display import Display
    except AnsibleOptionsError as e:
        display.error(to_text(e), wrap_text=False)
        sys.exit(5)

    cli = None
    me = os.path.basename(sys.argv[0])

    try:
        display = Display()
        display.debug("starting run")

        sub = None
        target = me.split('-')
        if target[-1][0].isdigit():
            # Remove any version or python version info as downstreams
            # sometimes add that
            target = target[:-1]

        if len(target) > 1:
            sub = target[1]
            myclass = "%sCLI" % sub.capitalize()
        elif target[0] == 'ansible':
            sub = 'adhoc'
            myclass = 'AdHocCLI'
        else:
            raise AnsibleError("Unknown Ansible alias: %s" % me)

        try:
            mycli = getattr(__import__("ansible.cli.%s" % sub, fromlist=[myclass]), myclass)
        except ImportError as e:
            # ImportError members have changed in py3
            if 'msg' in dir(e):
                msg = e.msg
            else:
                msg = e.message
            if msg.endswith(' %s' % sub):
                raise AnsibleError("Ansible sub-program not implemented: %s" % me)
            else:
                raise

        try:
            args = [to_text(a, errors='surrogate_or_strict') for a in sys.argv]
        except UnicodeError:
            display.error('Command line args are not in utf-8, unable to continue.  Ansible currently only understands utf-8')
            display.display(u"The full traceback was:\n\n%s" % to_text(traceback.format_exc()))
            exit_code = 6
        else:
            cli = mycli(args)
            exit_code = cli.run()

    except AnsibleOptionsError as e:
        cli.parser.print_help()
        display.error(to_text(e), wrap_text=False)
        exit_code = 5
    except AnsibleParserError as e:
        display.error(to_text(e), wrap_text=False)
        exit_code = 4
# TQM takes care of these, but leaving comment to reserve the exit codes
#    except AnsibleHostUnreachable as e:
#        display.error(str(e))
#        exit_code = 3
#    except AnsibleHostFailed as e:
#        display.error(str(e))
#        exit_code = 2
    except AnsibleError as e:
        display.error(to_text(e), wrap_text=False)
        exit_code = 1
    except KeyboardInterrupt:
        display.error("User interrupted execution")
        exit_code = 99
    except Exception as e:
        if C.DEFAULT_DEBUG:
            # Show raw stacktraces in debug mode, It also allow pdb to
            # enter post mortem mode.
            raise
        have_cli_options = bool(context.CLIARGS)
        display.error("Unexpected Exception, this is probably a bug: %s" % to_text(e), wrap_text=False)
        if not have_cli_options or have_cli_options and context.CLIARGS['verbosity'] > 2:
            log_only = False
            if hasattr(e, 'orig_exc'):
                display.vvv('\nexception type: %s' % to_text(type(e.orig_exc)))
                why = to_text(e.orig_exc)
                if to_text(e) != why:
                    display.vvv('\noriginal msg: %s' % why)
        else:
            display.display("to see the full traceback, use -vvv")
            log_only = True
        display.display(u"the full traceback was:\n\n%s" % to_text(traceback.format_exc()), log_only=log_only)
        exit_code = 250

    sys.exit(exit_code)
