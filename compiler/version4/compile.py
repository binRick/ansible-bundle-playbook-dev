#!/usr/bin/env python3
import sys, os, pathlib, importlib, subprocess, glob, datetime, time, re, shutil, io, inspect
os.environ['SCRIPT_DIR'] = SCRIPT_DIR = '{}'.format(pathlib.Path(__file__).parent.absolute())
VENV_PATH = './.venv-1/lib/python3.6/site-packages'
sys.path.append('./.venv-1/lib/python3.6/site-packages')
import pycompiler
from contextlib import redirect_stdout
import os, sys, traceback, json, socket, click, yaml, pip, click_threading, rich
from distutils.dir_util import copy_tree
from setuptools import find_packages
from pkgutil import iter_modules
from blessed import Terminal
import ansible_runner
import threading, queue
from jinja2 import Environment, PackageLoader, select_autoescape

from rich import print
from rich.columns import Columns
from rich.progress import Progress
from rich.console import Console
from rich.syntax import Syntax
from rich.table import Column, Table
from rich.traceback import install as install_rich_traceback
from pygments.styles import get_all_styles
install_rich_traceback()

args_console = Console(
  log_time=False,
  log_path=False,
)
console = Console()


from contextlib import contextmanager
import ctypes
import io
import os, sys
import tempfile

libc = ctypes.CDLL(None)
c_stdout = ctypes.c_void_p.in_dll(libc, 'stdout')


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

@contextmanager
def stdout_redirector(stream):
    # The original fd stdout points to. Usually 1 on POSIX systems.
    original_stdout_fd = sys.stdout.fileno()

    def _redirect_stdout(to_fd):
        """Redirect stdout to the given file descriptor."""
        # Flush the C-level buffer stdout
        libc.fflush(c_stdout)
        # Flush and close sys.stdout - also closes the file descriptor (fd)
        sys.stdout.close()
        # Make original_stdout_fd point to the same file as to_fd
        os.dup2(to_fd, original_stdout_fd)
        # Create a new sys.stdout that points to the redirected fd
        sys.stdout = io.TextIOWrapper(os.fdopen(original_stdout_fd, 'wb'))

    # Save a copy of the original stdout fd in saved_stdout_fd
    saved_stdout_fd = os.dup(original_stdout_fd)
    try:
        # Create a temporary file and redirect stdout to it
        tfile = tempfile.TemporaryFile(mode='w+b')
        _redirect_stdout(tfile.fileno())
        # Yield to caller, then redirect stdout back to the saved fd
        yield
        _redirect_stdout(saved_stdout_fd)
        # Copy contents of temporary file to the given stream
        tfile.flush()
        tfile.seek(0, io.SEEK_SET)
        stream.write(tfile.read())
    finally:
        tfile.close()
        os.close(saved_stdout_fd)

f = io.BytesIO()

if False:
  with stdout_redirector(f):
    print('foobar')
    print(12)
    libc.puts(b'this comes from C')
    os.system('echo and this is from echo')
#print('Got stdout: "{0}"'.format(f.getvalue()))

class StdoutBuffer(io.TextIOWrapper):
    def write(self, string):
        try:
            return super(StdoutBuffer, self).write(string)
        except TypeError:
            # redirect encoded byte strings directly to buffer
            return super(StdoutBuffer, self).buffer.write(string)


q = queue.Queue()
sio = io.StringIO()
base_dir = pathlib.Path(__file__).parent.absolute()
SCRIPTS_DIR = '{}/{}'.format(base_dir, '_scripts')

if False:
  with Progress() as progress:

    task1 = progress.add_task("[red]Downloading...", total=1000)
    task2 = progress.add_task("[green]Processing...", total=1000)
    task3 = progress.add_task("[cyan]Cooking...", total=1000)

    while not progress.finished:
        progress.update(task1, advance=0.5)
        progress.update(task2, advance=0.3)
        progress.update(task3, advance=0.9)
        time.sleep(0.02)


check_isolation_executable_installed = ansible_runner.utils.check_isolation_executable_installed('bwrap')

def my_func(modes):
    while True:
#        for l in sio.getvalue().strip().splitlines():
#          q.put(l.strip())
        print('''func..........thread  context = {} , {} modes\n
       qsize={}\n
\n
'''.format(
            {}, len(modes),
            q.qsize(),
        ))
        time.sleep(5.0)

def spawn_thread(ctx, func):
    def wrapper():
        with ctx:
            func()
    t = threading.Thread(target=wrapper)
    t.start()
    return t





def get_current_command_name():
    return click.get_current_context().info_name

def _PRE_PY_INSTALLER_CALLBACK(kwargs):
    if False:
        r = ansible_runner.run(host_pattern='localhost', module='shell', module_args='whoami')
        print("{}: {}".format(r.status, r.rc))
        for each_host_event in r.events:
            print(each_host_event['event'])

        print('PyInstaller Final Stats\n', r.stats)

#    if kwargs['view_pyinstaller_stats']:

def PRE_PY_INSTALLER_CALLBACK(kwargs):
    _PRE_PY_INSTALLER_CALLBACK(kwargs)
    PY_INSTALLER_WORK_PATH = kwargs['dirs']['PY_INSTALLER_WORK_PATH']

    FM = find_modules(kwargs['dirs']['VENV_DIR'])
    FM_PREFIXES = list(set([i.split('.')[0] for i in FM if '.' in i]))
    if kwargs['debug_mode']:
        print(    f'PRE_PY_INSTALLER_CALLBACK...........  venv has {len(FM)} modules,  {len(FM_PREFIXES)} FM_PREFIXES,    FM_PREFIXES={FM_PREFIXES}    get_current_command_name()={get_current_command_name()}      '        )

    if False:
      for d in [SCRIPT_DIR, SCRIPTS_DIR]:
        PYC_FILES_GLOB = '{}/*/*.pyc'.format(d)
        PYC_FILES = glob.glob(PYC_FILES_GLOB, recursive=True)
        print('Removing {} pyc files from python path, PYC_FILES_GLOB={}, dir={},  '.format(len(PYC_FILES), PYC_FILES_GLOB, d))

    for ILF in ['importlib_resources/version.txt']:
      if os.path.exists('{}/{}'.format(kwargs['dirs']['VENV_DIR'], os.path.dirname(ILF))):
        with open('{}/{}'.format(kwargs['dirs']['VENV_DIR'], ILF), 'w') as f:
          f.write('3.0.0')



from pycompiler import PySilencedOutput as SilencedOutput

class __SilencedOutput():
    def __init__(self, NAME, kwargs={}):
        if type(kwargs) == {} and 'kwargs' in kwargs.keys():
            kwargs = kwargs['kwargs']
        if 'debug_mode' in kwargs.keys() and kwargs['debug_mode']:
            print('SilencedOutput kwargs={}'.format(kwargs))
        LOG_FILE = None
        if LOG_FILE == None:
            LOG_FILE = '/tmp/.stdout.txt'
        self.name = NAME
        self.LOG_FILE = LOG_FILE
        self.LOG_FILE_ERR = '{}.err'.format(LOG_FILE)
        self.stdout_lines = []
        self.debug_pip = False
        if 'debug_pip' in kwargs.keys():
           self.debug_pip = bool(kwargs['debug_pip'])

    def __enter__(self):
        self.saved_stdout = sys.stdout
        self.saved_stderr = sys.stderr
        if False:
            sys.stdout = sio
            sys.stdout = q
            sys.stdout = self.stdout_buffer
        if True:
            sys.stdout = open(self.LOG_FILE,'w')
            sys.stderr = open(self.LOG_FILE_ERR,'w')
        return self.saved_stdout
    def __exit__(self, type, value, traceback):
        with open(self.LOG_FILE,'r') as f:
            self.stdout_lines = f.read().strip().splitlines()
        sys.stdout = self.saved_stdout
        sys.stderr = self.saved_stderr
        syntax = Syntax('\n'.join(self.stdout_lines), "bash", theme="paraiso-dark", line_numbers=False)
        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("Type", style="bold", width=12)
        table.add_column("Output", justify="left")
        table.add_row(
            "[red]Pip Install Output[/red]:",
            syntax,
        )
        if self.debug_pip:
            print(f'     PIP      {self.name}           ::       got {len(self.stdout_lines)} lines of stdout content..........')
            console.print(table)
    
def deltree(target):
    for d in os.listdir(target):
        try:
            deltree(target + '/' + d)
        except OSError:
            os.remove(target + '/' + d)
    os.rmdir(target)

def cleanup_dirs(dirs, PYD):
    CLEANUP_DIR = dirs['CLEANUP_DIR']
    PY_INSTALLER_WORK_PATH = dirs['PY_INSTALLER_WORK_PATH']
    SPECS_DIR = dirs['SPECS_DIR']
    if not os.path.exists(CLEANUP_DIR):
        os.mkdir(CLEANUP_DIR)
    if os.path.exists(SPECS_DIR):
        shutil.move(SPECS_DIR, '{}/{}'.format(CLEANUP_DIR,os.path.basename(SPECS_DIR)))
    if os.path.exists(PY_INSTALLER_WORK_PATH):
        shutil.move(PY_INSTALLER_WORK_PATH, '{}/{}'.format(CLEANUP_DIR,os.path.basename(PY_INSTALLER_WORK_PATH)))
    if os.path.exists(PYD.temp_dir):
        shutil.move(PYD.temp_dir, '{}/{}'.format(dirs['DIST_DIR'],os.path.basename(PYD.temp_dir)))
    if os.path.exists(CLEANUP_DIR):
        deltree(CLEANUP_DIR)

def test_compiled_script(script_name, kwargs):
    SCRIPT_PATH = '{}/{}'.format(SCRIPT_DIR, script_name)
    if kwargs['debug_mode']:
        print(f'   {script_name}     test compiled script -> SCRIPT_PATH={SCRIPT_PATH},              ')
        args_console.log('xxxxx', log_locals=True, justify='right', markup=None, emoji=True)



def pyinstaller(script_name, **kwargs):
    import PyInstaller.__main__
    PY_INSTALLER_CLEAN = False
    Scripts = get_scripts()
    ScriptNames = get_script_names()
    VF = kwargs['dirs']
    PY_LOG_LEVEL = kwargs['log_level']
    VENV_DIR = kwargs['dirs']['VENV_DIR']
    PY_PATHS = [VENV_DIR]
    CEMF = get_CommonExcludedModuleFiles()
    if kwargs['debug_mode']:
        print('get_CommonExcludedModuleFiles...................',              f'{len(CEMF)} CEMF items...',  )
        yaml.dump(CEMF[-5:], sys.stdout)
        yaml.dump(CEMF[:5], sys.stdout)

    if 'name' in kwargs.keys():
        PY_NAME = kwargs['name']
    else:
        PY_NAME = os.path.basename(script_name)
        if '.' in os.path.basename(script_name):
            PY_NAME = os.path.basename(script_name).split('.')[0]
        while PY_NAME.startswith('_'):
            PY_NAME = PY_NAME[1:]
    PY_STRIP_MODE = kwargs['strip_mode']
    kwargs['debug_mode'] = bool(kwargs['debug_mode'])
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
          if kwargs['debug_mode']:
              print(MSG)
          HIDDEN_IMPORTS.remove(hi)

    for hi in HIDDEN_IMPORTS:
            PY_HIDDEN_IMPORTS.append('--hidden-import=%s' % hi)

    kwargs['data_files'] = list(set(kwargs['data_files']))
    for AD in kwargs['data_files']:
      if type(AD) == str and AD.startswith('@'):
        kwargs['data_files'].remove(AD)
        AD = AD.replace('@','')
        AD_PATH = '{}/{}'.format(SCRIPT_DIR, AD)
        if os.path.exists(AD_PATH):
          with open(AD_PATH,'r') as f:
            data = f.read().splitlines()
            for df in data:
              if len(df) < 1 or not '/' in df:
                continue
              if os.path.exists('{}/{}'.format(VENV_DIR,df)):
                kwargs['data_files'].append(df)

    for AD in kwargs['data_files']:
      if '*' in AD:
        kwargs['data_files'].remove(AD)
        for pdir in [VENV_DIR, SCRIPT_DIR]:    
            AD_GLOB = '{}/{}'.format(pdir,AD)
            AD_FILES = glob.glob(AD_GLOB, recursive=False)
            M = f'  found glob in file {AD},   AD_GLOB={AD_GLOB}, {len(AD_FILES)} AD_FILES'
            if kwargs['debug_mode']:
                print(M)
            for ADF in AD_FILES:
                if 'site-packages' in ADF:
                    ADF = ADF.split('site-packages')[-1]
                while ADF.startswith('/'):
                    ADF = ADF[1:]
                if not ADF in kwargs['data_files']:
                  kwargs['data_files'].append(ADF)


    """
    for df in kwargs['data_files']:
      continue
      if type(df) != str and type(df) == list:
        l = df
        kwargs['data_files'].remove(df)
        for _l in l:
           kwargs['data_files'].append(_l)
    """
        
    with click.progressbar(kwargs['data_files'],
                           label=f"Adding {len(kwargs['data_files'])} Data Files to PyInstaller Command",
                           length=len(kwargs['data_files'])) as file_processor:
      #for df in kwargs['data_files']:
      for df in file_processor:
        if '*' in df or type(df) != str or len(df) < 1:
            continue


        SRC_DATA_FILE = '{}/{}'.format(VENV_DIR,df)
        SRC_DATA_FILE = df
       
        _SRC_DATA_FILE = '{}/{}'.format(VENV_DIR,SRC_DATA_FILE)
        if os.path.exists(_SRC_DATA_FILE):
            SRC_DATA_FILE = _SRC_DATA_FILE

        if os.path.exists('{}/{}'.format(VENV_DIR,df)):
            DEST_DATA_FILE = '{}'.format(os.path.dirname(df))
        if DEST_DATA_FILE == '':
            DEST_DATA_FILE = '.'

        if os.path.exists(SRC_DATA_FILE):
            NEW_ADD_DATA = '--add-data={}:{}'.format(SRC_DATA_FILE, DEST_DATA_FILE)
        else:
            raise Exception('unable to add data file "{}"\n  SRC_DATA_FILE={}\n  DEST_DATA_FILE={}\n\n\nexception:\n{}\n\n'.format(df,SRC_DATA_FILE, DEST_DATA_FILE, traceback.format_exc()))
        PY_ADD_DATAS.append(NEW_ADD_DATA)

        
    PY_INSTALLER_WORK_PATH = kwargs['dirs']['PY_INSTALLER_WORK_PATH']
    SPECS_DIR = kwargs['dirs']['SPECS_DIR']
    DIST_DIR = kwargs['dirs']['DIST_DIR']
    PY_INSTALLER_WORK_PATH = kwargs['dirs']['PY_INSTALLER_WORK_PATH']
    SCRIPTS_DIR = kwargs['dirs']['SCRIPTS_DIR']

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

    #excluded_module_wildcards = [i.replace('*','') for i in kwargs['CommonExcludedModules'] if i.endswith('*') and len(i.split('*')) == 2]
    #print('excluded_module_wildcards=', excluded_module_wildcards)
    #print(

    for hi in PY_HIDDEN_IMPORTS:
      #for excluded_module_wildcard in excluded_module_wildcards:
        #if hi not in kwargs['CommonExcludedModules']:  # and not hi.startswith(excluded_module_wildcard):
        PY_INSTALLER_ARGS.append(hi)
    PY_INSTALLER_ARGS = list(set(PY_INSTALLER_ARGS))
    PY_INSTALLER_ARGS.append(os.path.join(SCRIPTS_DIR, script_name))
    MSG = f'SPECS_DIR={SPECS_DIR},          '
    if kwargs['debug_cmd']:
        msg = yaml.dump(PY_INSTALLER_ARGS)
        print('PY_INSTALLER_ARGS:', PY_INSTALLER_ARGS)
        #msg = term.bold_black_on_darkkhaki(msg)
        #print(msg)
    if kwargs['debug_mode']:
        print('PY_INSTALLER_ARGS=', PY_INSTALLER_ARGS, 'DEBUG_MODE=', kwargs['debug_mode'], 'PY_LOG_LEVEL=', PY_LOG_LEVEL, MSG)
    
    PY_ARGS = {
      'excluded_modules': [a for a in PY_INSTALLER_ARGS if a.startswith('--exclude-module')],
      'hidden_imports': [a for a in PY_INSTALLER_ARGS if a.startswith('--hidden-import')],
      'added_datas': [a for a in PY_INSTALLER_ARGS if a.startswith('--add-data')],
    }
    PY_INSTALLER_ARGS_SUMMARY = {
      'hidden_imports_qty': len(PY_ARGS['hidden_imports']),
      'hidden_imports_bytes': int(sum([123 for f in PY_ARGS['hidden_imports'] if os.path.exists('{}/{}/{}'.format(SCRIPT_DIR,VENV_PATH, f))])),
      'build_mode': 'onedir' if '--onedir' in ' '.join(PY_INSTALLER_ARGS) else 'onefile',
      'unique_switches': list(set([a.split('=')[0] for a in PY_INSTALLER_ARGS if '=' in a])),
      'excluded_modules_qty': len(PY_ARGS['excluded_modules']),
      'added_datas_qty': len(PY_ARGS['added_datas']),
    }
    
    print(PY_INSTALLER_ARGS_SUMMARY)
    #yaml.dump(PY_INSTALLER_ARGS_SUMMARY, sys.stdout)
    if kwargs['debug_added_files']:
        print(f" {len(PY_ARGS['added_datas'])}debugging added files........")
        yaml.dump(PY_ARGS['added_datas'], sys.stdout)

    my_code1 = f'''{PY_INSTALLER_ARGS}'''.strip()

    syntax = Syntax('\n'.join(PY_INSTALLER_ARGS), "bash", theme="monokai", line_numbers=True)
    if kwargs['debug_scripts_dir']:
        console.print(syntax)
    if not kwargs['dry_run']:
        PRE_PY_INSTALLER_CALLBACK(kwargs)
#        with SilencedOutput():
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
          if EXT == '.txt':
            for l in lines:
              if len(l) > 0:
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

def get_scripts(kwargs={}):
    s = glob.glob('{}/*.py'.format(SCRIPTS_DIR))
    for style in ['vim']:
      for _s in s:
        with open(_s,'r') as f:
            _s_c = f.read().strip().splitlines()
        if 'debug_scripts_dir' in kwargs.keys() and kwargs['debug_scripts_dir']:
            print("    :thumbs_up:          {}   style={}".format(os.path.basename(_s), style))
            print(Syntax('\n'.join(_s_c[0:5]), "bash", theme=style, line_numbers=False, code_width=45))
    return s

def get_script_names():
    return [os.path.basename(i) for i in get_scripts()]

def install_and_import(packages, kwargs):
 with SilencedOutput('install_and_import', kwargs):
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
@click.option('--skip-excluded-files/--no-skip-excluded-files', default=pycompiler.defaults.DEFAULT_SKIP_EXCLUDED_FILES, help='Skip execluded files')
@click.option('--debug/--no-debug', default=pycompiler.defaults.DEFAULT_DEBUG_MODE, help='Debug Mode')
@click.option('--view-pyinstaller-stats/--no-view-pyinstaller-stats', default=pycompiler.defaults.DEFAULT_VIEW_PYINSTALLER_STATS, help='View PyInstaller Stats')
@click.option('--recurse-data-files/--no-recurse-data-files', default=pycompiler.defaults.DEFAULT_RECURSE_DATA_FILES, help='Recurse Data Files')
@click.option('--debug-cmd/--no-debug-cmd', default=pycompiler.defaults.DEFAULT_DEBUG_CMD_MODE, help='Debug Pyinstaller command')
@click.option('--debug-added-files/--no-debug-added-files', default=pycompiler.defaults.DEFAULT_DEBUG_ADDED_FILES_MODE, help='Debug Pyinstaller Added Files')
@click.option('--debug-args/--no-debug-args', default=False, help='Debug Arguments')
@click.option('--debug-pip/--no-debug-pip', default=pycompiler.defaults.DEFAULT_DEBUG_PIP_MODE, help='Debug Pip')
@click.option('--debug-scripts-dir/--no-debug-scripts-dir', default=pycompiler.defaults.DEFAULT_DEBUG_SCRIPTS_DIR_MODE, help='Debug Scripts Directory')
@click.option('--dry-run/--no-dry-run', default=False, help='Do not execute pyinstaller command')
@click.option('--log-level', default='INFO', type=click.Choice(['TRACE','DEBUG','INFO','WARN','ERROR','CRITICAL'], case_sensitive=False))
@click.option('--compilemode', prompt='Compile Mode',type=click.Choice(get_modes()['Modes'].keys(), case_sensitive=True))
def compile(compilemode, clean, debug, log_level, strip, debug_cmd, dry_run, import_all_venv_modules, debug_added_files, skip_excluded_files, recurse_data_files, debug_scripts_dir, debug_pip, debug_args, view_pyinstaller_stats):
    #InspectedArgs = [locals()[arg] for arg in inspect.getargspec(compile).args]
    modes = get_modes()
    Mode = modes['Modes'][compilemode]
    CommonHiddenImports = modes['CommonHiddenImports']
    Translations = modes['Translations']
    PYD = pycompiler.PyDirectories(compilemode, base_dir)
    PYD_DIRS = PYD.get_dirs()
    #t = threading.Thread(target=my_func, args=[modes], daemon=True)
    #t.start()
    if debug_args:
        print('Debugging Arguments')
        #print(locals())
        #print(render_scope(locals(), title="[i]locals", sort_keys=False))
    kw = {
      'debug_mode':debug,
      'debug_pip':debug_pip,
      'debug_cmd':debug_cmd,
      'PyPackages': pycompiler.PyPackages(compilemode, base_dir),
    }
    
    install_and_import(Mode['modules'] + get_common_modules(), kw)
    for script in Mode['scripts']:
        M = f'Compiling {compilemode} :: {os.path.basename(script)}'
        style = "bold green on black"
        if kw['debug_mode']:
            console.print(M, style=style, justify="center")
            args_console.log(M, log_locals=True, justify='left', markup=None, emoji=True)
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
                            debug_added_files=debug_added_files,
                            skip_excluded_files=skip_excluded_files,
                            recurse_data_files=recurse_data_files,
                            compilemode=compilemode,
                            dirs=PYD_DIRS,
                            debug_scripts_dir=debug_scripts_dir,
                            PYD=PYD,
                            debug_pip=debug_pip,
                            debug_args=debug_args,
                            PyPackages=kw['PyPackages'],
                            view_pyinstaller_stats=view_pyinstaller_stats,
        )
    for script in Mode['scripts']:
        test_compiled_script(script, kw)
    #t.join()
    cleanup_dirs(PYD_DIRS, PYD) 

if __name__ == '__main__':
    compile()
