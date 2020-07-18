#!/usr/bin/env python3
import sys, os, pathlib, importlib, subprocess, glob, datetime, time, re, shutil, io
SCRIPT_DIR = pathlib.Path(__file__).parent.absolute()
VENV_PATH = './.venv-1/lib/python3.6/site-packages'
sys.path.append('./.venv-1/lib/python3.6/site-packages')
import os, sys, traceback, json, socket, click, yaml, pip
from setuptools import find_packages
from pkgutil import iter_modules
from blessed import Terminal
term = Terminal()

VENV_DIR = '{}/{}'.format(pathlib.Path(__file__).parent.absolute(), '.venv-1/lib/python3.6/site-packages')
SCRIPTS_DIR = '{}/{}'.format(pathlib.Path(__file__).parent.absolute(), '_scripts')
SPECS_DIR = '{}/{}'.format(pathlib.Path(__file__).parent.absolute(), '.specs_{}'.format(int(time.time())))
DIST_DIR = '{}/{}'.format(pathlib.Path(__file__).parent.absolute(), '.dist_{}'.format(int(time.time())))
CLEANUP_DIR = '{}/{}'.format(SCRIPT_DIR,'.cleanup_{}'.format(int(time.time())))
PY_INSTALLER_WORK_PATH = '{}/{}'.format(pathlib.Path(__file__).parent.absolute(), '.build_{}'.format(int(time.time())))



def PRE_PY_INSTALLER_CALLBACK():
    print('PRE_PY_INSTALLER_CALLBACK...........')

    if False:
      for d in [SCRIPT_DIR, SCRIPTS_DIR]:
        PYC_FILES_GLOB = '{}/*/*.pyc'.format(d)
        PYC_FILES = glob.glob(PYC_FILES_GLOB, recursive=True)
        print('Removing {} pyc files from python path, PYC_FILES_GLOB={}, dir={},  '.format(len(PYC_FILES), PYC_FILES_GLOB, d))

    for ILF in ['importlib_resources/version.txt']:
      if os.path.exists('{}/{}'.format(VENV_DIR, ILF)):
        with open('{}/{}'.format(VENV_DIR, ILF), 'w') as f:
          f.write('3.0.0')



def find_modules(path):
    modules = set()
    for pkg in find_packages(path):
        modules.add(pkg)
        pkgpath = path + '/' + pkg.replace('.', '/')
        if sys.version_info.major == 2 or (sys.version_info.major == 3 and sys.version_info.minor < 6):
            for _, name, ispkg in iter_modules([pkgpath]):
                if not ispkg:
                    modules.add(pkg + '.' + name)
        else:
            for info in iter_modules([pkgpath]):
                if not info.ispkg:
                    modules.add(pkg + '.' + info.name)
    return modules

#print('VENV_PATH modules=', find_modules(VENV_PATH))
#sys.exit()

class SilencedOutput():
    def __init__(self, LOG_FILE=None):
        if LOG_FILE == None:
            LOG_FILE = '/tmp/.stdout.txt'
        self.LOG_FILE = LOG_FILE
        self.LOG_FILE_ERR = '{}.err'.format(LOG_FILE)
        #self.STDOUT = io.StringIO
    def __enter__(self):
        self.saved_stdout = sys.stdout
        self.saved_stderr = sys.stderr
        sys.stdout = open(self.LOG_FILE,'w')
        #sys.stdout = self.STDOUT
        sys.stderr = open(self.LOG_FILE_ERR,'w')
        return self.saved_stdout
    def __exit__(self, type, value, traceback):
        sys.stdout = self.saved_stdout
        sys.stderr = self.saved_stderr
    
def deltree(target):
    for d in os.listdir(target):
        try:
            deltree(target + '/' + d)
        except OSError:
            os.remove(target + '/' + d)
    os.rmdir(target)

def cleanup_dirs():
    if not os.path.exists(CLEANUP_DIR):
        os.mkdir(CLEANUP_DIR)
    #print('CLEANUP_DIR=', CLEANUP_DIR)
    shutil.move(SPECS_DIR, '{}/{}'.format(CLEANUP_DIR,os.path.basename(SPECS_DIR)))
    shutil.move(PY_INSTALLER_WORK_PATH, '{}/{}'.format(CLEANUP_DIR,os.path.basename(PY_INSTALLER_WORK_PATH)))
    deltree(CLEANUP_DIR)

def test_compiled_script(script_name, **kwargs):
    SCRIPT_PATH = '{}/{}'.format(SCRIPT_DIR, script_name)
    print(f'        test compiled script -> SCRIPT_PATH={SCRIPT_PATH},              ')


def pyinstaller(script_name, **kwargs):
    import PyInstaller.__main__
    DEBUG_MODE = False
    PY_INSTALLER_CLEAN = False
    PY_LOG_LEVEL = kwargs['log_level']
    PY_PATHS = [VENV_DIR]
    CEMF = get_CommonExcludedModuleFiles()
    print('get_CommonExcludedModuleFiles...................',              f'{len(CEMF)} CEMF items...',  )
    yaml.dump(CEMF[-5:], sys.stdout)
    yaml.dump(CEMF[:5], sys.stdout)
    #sys.exit()

    if 'name' in kwargs.keys():
        PY_NAME = kwargs['name']
    else:
        PY_NAME = os.path.basename(script_name)
        if '.' in os.path.basename(script_name):
            PY_NAME = os.path.basename(script_name).split('.')[0]
        while PY_NAME.startswith('_'):
            PY_NAME = PY_NAME[1:]
    PY_STRIP_MODE = kwargs['strip_mode']
    if 'debug_mode' in kwargs.keys():
        DEBUG_MODE = bool(kwargs['debug_mode'])
    if 'clean_mode' in kwargs.keys():
        PY_INSTALLER_CLEAN = bool(kwargs['clean_mode'])

    PY_HIDDEN_IMPORTS = []
    PY_HIDDEN_IMPORTS = []
    PY_EXCLUDED_MODULES = []
    PY_ADD_DATAS = []

    for em in kwargs['CommonExcludedModules']:
      if not '.*' in em:
        PY_EXCLUDED_MODULES.append('--exclude-module=%s' % em)

    HIDDEN_IMPORTS = []
    for hi in kwargs['hidden_imports'] + kwargs['CommonHiddenImports']:
        if hi.endswith('.*'):
            hi_name = hi.replace('.*','')
            for pp in PY_PATHS:
              VENV_MODULES = find_modules(pp)
              for vm in VENV_MODULES:
                if vm.startswith('{}.'.format(hi_name)):
                  if vm not in HIDDEN_IMPORTS:
                      HIDDEN_IMPORTS.append(vm)                            
        else:
            HIDDEN_IMPORTS.append(hi)
    for r in CEMF:
      for hi in HIDDEN_IMPORTS:
        if r in hi:
          MSG = f'  Removing hidden import {hi} => match => {r}'
          if DEBUG_MODE:
              print(MSG)
          HIDDEN_IMPORTS.remove(hi)
    for hi in HIDDEN_IMPORTS:
            PY_HIDDEN_IMPORTS.append('--hidden-import=%s' % hi)

    for df in kwargs['data_files']:
        DEST_DATA_FILE = '{}'.format(os.path.dirname(df))
        if DEST_DATA_FILE == '':
            DEST_DATA_FILE = '.'
        SRC_DATA_FILE = '{}/{}'.format(VENV_DIR,df)
        PY_ADD_DATAS.append('--add-data={}:{}'.format(SRC_DATA_FILE, DEST_DATA_FILE))

    PY_INSTALLER_ARGS = [
      '--name=%s' % PY_NAME,
      '--workpath=%s' % PY_INSTALLER_WORK_PATH,
      '--log-level=%s' % PY_LOG_LEVEL,
      '--specpath=%s' % SPECS_DIR,
      '--distpath=%s' % DIST_DIR,
      '--paths=%s' % PY_PATHS,
      '--noconfirm',
      '--onedir',
    ]
    if PY_STRIP_MODE:
         PY_INSTALLER_ARGS.append('--strip')
    if PY_INSTALLER_CLEAN:
         PY_INSTALLER_ARGS.append('--clean')
    for ad in PY_ADD_DATAS:
        PY_INSTALLER_ARGS.append(ad)
    for em in PY_EXCLUDED_MODULES:
        PY_INSTALLER_ARGS.append(em)

    excluded_module_wildcards = [i.replace('*','') for i in kwargs['CommonExcludedModules'] if i.endswith('.*') and len(i.split('.*')) == 2]
    print('excluded_module_wildcards=', excluded_module_wildcards)

    for hi in PY_HIDDEN_IMPORTS:
      #for excluded_module_wildcard in excluded_module_wildcards:
        if hi not in kwargs['CommonExcludedModules']:  # and not hi.startswith(excluded_module_wildcard):
            PY_INSTALLER_ARGS.append(hi)
    PY_INSTALLER_ARGS = list(set(PY_INSTALLER_ARGS))
    PY_INSTALLER_ARGS.append(os.path.join(SCRIPTS_DIR, script_name))
    MSG = f'SPECS_DIR={SPECS_DIR},          '
    if kwargs['debug_cmd']:
        msg = yaml.dump(PY_INSTALLER_ARGS)
        msg = term.bold_black_on_darkkhaki(msg)
        print(msg)
    if kwargs['dry_run']:
        sys.exit()
    if kwargs['debug_mode']:
        print('PY_INSTALLER_ARGS=', PY_INSTALLER_ARGS, 'DEBUG_MODE=', DEBUG_MODE, 'PY_LOG_LEVEL=', PY_LOG_LEVEL, MSG)

    
    PY_ARGS = {
      'excluded_modules': [a for a in PY_INSTALLER_ARGS if a.startswith('--exclude-module')],
      'hidden_imports': [a for a in PY_INSTALLER_ARGS if a.startswith('--hidden-import')],
    }
    PY_INSTALLER_ARGS_SUMMARY = {
      'hidden_imports_qty': len(PY_ARGS['hidden_imports']),
      'hidden_imports_bytes': int(sum([123 for f in PY_ARGS['hidden_imports'] if os.path.exists('{}/{}/{}'.format(SCRIPT_DIR,VENV_PATH, f))])),
      'build_mode': 'onedir' if '--onedir' in ' '.join(PY_INSTALLER_ARGS) else 'onefile',
      'unique_switches': list(set([a.split('=')[0] for a in PY_INSTALLER_ARGS if '=' in a])),
      'excluded_modules_qty': len(PY_ARGS['excluded_modules']),
      'added_datas_qty': len([a for a in PY_INSTALLER_ARGS if a.startswith('--add-data')]),
    }
    
    yaml.dump(PY_INSTALLER_ARGS_SUMMARY, sys.stdout)
    PRE_PY_INSTALLER_CALLBACK()
    PyInstaller.__main__.run(PY_INSTALLER_ARGS)
    

def get_modes():
    with open('modes.yaml','r') as f:
        return yaml.safe_load(f.read())

def get_common_modules():
    modes = get_modes()
    return modes['CommonModules']

def get_CommonExcludedModuleFiles():
    RR = []
    for _f in  get_modes()['CommonExcludedModuleFiles']:
      SP = '{}/{}'.format(SCRIPT_DIR,_f)
      if os.path.exists(SP):
        FN, EXT = os.path.splitext(SP)
        with open(SP) as f:
          dat = f.read()
          lines = dat.splitlines()
          print(f'read {len(dat)} bytes ', type(dat), f'  extension={EXT}, ',  f' {len(lines)} lines, ')
          if EXT == '.txt':
            for l in lines:
              RR.append(l)
    return RR


def get_CommonExcludedModules():
    modes = get_modes()
    return modes['CommonExcludedModules']
def get_SkipModuleImports():
    modes = get_modes()
    return modes['SkipModuleImports']

def get_translations():
    modes = get_modes()
    return modes['Translations']

def get_scripts():
    return glob.glob('{}/*.py'.format(SCRIPTS_DIR))

def get_script_names():
    return [os.path.basename(i) for i in get_scripts()]

def install_and_import(packages):
 with SilencedOutput():
  Translations = get_translations()
  SkipModuleImports = get_SkipModuleImports()
  CommonExcludedModules = get_CommonExcludedModules()
  for package in packages:
    import importlib
    try:
        importlib.import_module(package)
    except ImportError:
        try:
            import pip
            pip.main(['install', package])
        except:
            subprocess.check_call([sys.executable, "-m", "pip3", "install", package])
    finally:
        if '=' in package:
            package = package.split('=')[0]
        if '[' in package:
            package = package.split('[')[0]
        if package in Translations['modules'].keys():
            package = Translations['modules'][package]
        if package not in SkipModuleImports:
            globals()[package] = importlib.import_module(package)


@click.command()
@click.option('--import-all-venv-modules', default=False, help='Import all venv modules during compilation.')
@click.option('--strip/--no-strip', default=False, help='Apply a symbol-table strip to the executable and shared libs.')
@click.option('--clean/--no-clean', default=False, help='Clean PyInstaller cache and remove temporary files before building.')
@click.option('--debug/--no-debug', default=False, help='Debug Mode')
@click.option('--debug-cmd/--no-debug-cmd', default=False, help='Debug Pyinstaller command')
@click.option('--dry-run/--no-dry-run', default=False, help='Do not execute pyinstaller command')
@click.option('--log-level', default='INFO', type=click.Choice(['TRACE','DEBUG','INFO','WARN','ERROR','CRITICAL'], case_sensitive=False))
@click.option('--mode', prompt='Compile Mode',type=click.Choice(['test', 'ansible', 'borg'], case_sensitive=True))
def compile(mode, clean, debug, log_level, strip, debug_cmd, dry_run, import_all_venv_modules):
    modes = get_modes()
    Mode = modes['Modes'][mode]
    CommonHiddenImports = modes['CommonHiddenImports']
    Translations = modes['Translations']
    Scripts = get_scripts()
    ScriptNames = get_script_names()
    if debug:
        print('get_scripts=', Scripts)
        print('get_script_names=', ScriptNames)
    install_and_import(Mode['modules'] + get_common_modules())
    for script in Mode['scripts']:
        click.echo('Compiling :: Mode={}, SCRIPTS_DIR={}, script={}, '.format(
            mode,
            SCRIPTS_DIR,
            script,
        ))
        pyinstaller(        script, 
                            clean_mode=clean, debug_mode=debug, log_level=log_level,
                            strip_mode=strip, 
                            data_files=Mode['data_files'],
                            hidden_imports=Mode['hidden_imports'],
                            CommonHiddenImports=CommonHiddenImports,
                            CommonExcludedModules=modes['CommonExcludedModules'],
                            debug_cmd=debug_cmd,
                            dry_run=dry_run,
                            import_all_venv_modules=import_all_venv_modules,
        )
    for script in Mode['scripts']:
        test_compiled_script(script)
    cleanup_dirs() 

if __name__ == '__main__':
    compile()
