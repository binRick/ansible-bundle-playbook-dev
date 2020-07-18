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

class defaults:
    DEFAULT_DEBUG_MODE = True
    DEFAULT_DEBUG_CMD_MODE = True
    DEFAULT_DEBUG_ADDED_FILES_MODE = True
    DEFAULT_DEBUG_PIP_MODE = True
    DEFAULT_DEBUG_SCRIPTS_DIR_MODE = True
    DEFAULT_VIEW_PYINSTALLER_STATS = True
    DEFAULT_RECURSE_DATA_FILES = True

    DEFAULT_SKIP_EXCLUDED_FILES = False
