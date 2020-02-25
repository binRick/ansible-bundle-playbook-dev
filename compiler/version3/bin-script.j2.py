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


import os
import shutil
import sys

if os.environ.get('__DEBUG_ENV', False):
    print('env={}',os.environ.keys())
    
__J2__PROC_NAME = "{{ env('__J2__PROC_NAME') }}"
__J2__PROC_PATH = "{{ env('__J2__PROC_PATH') }}"
__J2__PROC_FILE = "{{ env('__J2__PROC_FILE') }}"
__EXEC = "./{}".format(__J2__PROC_FILE)
__ENV = os.environ.copy()
__ENV['MY_VAR123'] = 'MY_VAL123'
__ARGS = [__EXEC] + sys.argv[1:]

print('__ARGS={}'.format(__ARGS))

sys.argv[0] = __J2__PROC_FILE
os.chdir(__J2__PROC_PATH)
os.execvpe(__EXEC, __ARGS, __ENV)


