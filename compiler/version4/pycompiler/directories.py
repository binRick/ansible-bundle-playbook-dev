import sys, os, pathlib, importlib, subprocess, glob, datetime, time, re, shutil, io, inspect, tempfile, json
import ansible_runner

from rich import print
from rich.columns import Columns
from rich.progress import Progress
from rich.console import Console
from rich.syntax import Syntax
from rich.table import Column, Table
from rich.traceback import install as install_rich_traceback
from pygments.styles import get_all_styles
install_rich_traceback()

console = Console(

)
debug_console = Console(
  log_time=True,
  log_path=True,
)


class PyDirectories():
    def __init__(self, buildmode, base_dir):
        self.buildmode = buildmode
        self.base = base_dir
        self.temp_dir_fd, self.temp_dir1 = tempfile.mkstemp(prefix=f'{self.buildmode}__', suffix='__temp_dir', dir=self.base)
        self.temp_dir = '{}/.{}'.format(self.base, os.path.basename(self.temp_dir1))

        if os.path.exists(self.temp_dir1):
            os.unlink(self.temp_dir1)

        if not os.path.exists(self.temp_dir):
            os.mkdir(self.temp_dir)

        self.dirs = None
        self.get_dirs()

#        if os.path.exists(self.project_dir):
#                output.debug("Copying directory tree from {} to {} for working directory isolation".format(self.project_dir,
#                copy_tree(self.project_dir, self.directory_isolation_path, preserve_symlinks=True)

    def get_dirs(self):
        if self.dirs == None:
            #td = tempfile.TemporaryDirectory(prefix=self.buildmode, dir=self.base_buildmode_dir)
            #tf = tempfile.mkdtemp(prefix=self.buildmode, dir=td.fullpath)
            self.dirs = {
                'directory_isolation_path': '{}/{}'.format(self.temp_dir,'directory_isolation_path'),
                'VENV_DIR': '{}/{}'.format(self.base, '.venv-1/lib/python3.6/site-packages'),
                'SCRIPTS_DIR': '{}/{}'.format(self.base, '_scripts'),
                'SPECS_DIR': '{}/{}'.format(self.base, '.specs_{}_{}'.format(self.buildmode, int(time.time()))),
                'DIST_DIR': '{}/{}'.format(self.base, '.dist_{}_{}'.format(self.buildmode,int(time.time()))),
                'CLEANUP_DIR': '{}/{}'.format(self.base, '.cleanup_{}_{}'.format(self.buildmode,int(time.time()))),
                'PY_INSTALLER_WORK_PATH': '{}/{}'.format(self.base, '.build_{}_{}'.format(self.buildmode, int(time.time()))),
            }
        for k in self.dirs.keys():
          v = self.dirs[k]
          pathlib.Path(v).mkdir(parents=True, exist_ok=True)

        return self.dirs
