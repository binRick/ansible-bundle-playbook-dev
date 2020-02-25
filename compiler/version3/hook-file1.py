import os, sys
print('\n\n        hook-file1.py\n\n');
def pre_safe_import_module(api):
    api.add_alias_module('_ansible', 'ansible')
    global __DATA_PATHS
    __GLOBAL_PATHS.append('data')
    os.environ['__GLOBAL_PATHS'] = 'xxxxxxxxxxxxxx'
    print('         [pre_safe_import_module]     os.environ[\'__GLOBAL_PATHS\']={}'.format(os.environ.get('__GLOBAL_PATHS','unknown')))
print('\n\n        hook-file1.py   OK\n\n')

