from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os, sys, shutil

__J2__PROC_NAME         = """{{ env('__J2__PROC_NAME') }}"""
__J2__PROC_PATH         = """{{ env('__J2__PROC_PATH') }}"""
__J2__PROC_FILE         = """{{ env('__J2__PROC_FILE') }}"""
__J2__PROC_PATH_SUFFIX  = """{{ env('__J2__PROC_PATH_SUFFIX') }}"""

try:
    this_file = __file__
except NameError:
    this_file = sys.argv[0]

this_file = os.path.abspath(this_file)
if getattr(sys, 'frozen', False):
    application_path = getattr(sys, '_MEIPASS', os.path.dirname(sys.executable))
else:
    application_path = os.path.dirname(this_file)

NEW_PATH = os.path.realpath('{}/{}{}'.format(
            application_path,
            __J2__PROC_PATH_SUFFIX,
            __J2__PROC_FILE,
        ))

if os.environ.get('__DEBUG_ENV', False):
    print('env={}',os.environ.keys())
    
__EXEC = "./{}".format(__J2__PROC_FILE)
__ENV = os.environ.copy()
__ENV['MY_VAR123'] = 'MY_VAL123'
__ARGS = [__EXEC] + sys.argv[1:]

if os.environ.get('__DEBUG_ARGS', False):
    print('__ARGS={}'.format(__ARGS))

sys.argv[0] = __J2__PROC_FILE
os.chdir(os.path.dirname(NEW_PATH))
os.execve(__EXEC, __ARGS, __ENV)


