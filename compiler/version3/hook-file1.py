print('\n\n        hook-file1.py\n\n');
def pre_safe_import_module(api):
    api.add_alias_module('_ansible', 'ansible')
print('\n\n        hook-file1.py   OK\n\n')

