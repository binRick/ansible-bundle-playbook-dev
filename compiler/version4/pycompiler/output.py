import sys, os, json
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



class PySilencedOutput():
    def __init__(self, NAME, kwargs={}):
        if type(kwargs) == {} and 'kwargs' in kwargs.keys():
            kwargs = kwargs['kwargs']
        if 'debug_mode' in kwargs.keys() and kwargs['debug_mode']:
            print('PySilencedOutput kwargs={}'.format(kwargs))
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
