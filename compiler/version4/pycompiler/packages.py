import sys, os, json

def _find_modules(path):
    modules = set()
    for pkg in _find_modules(path):
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

class PyPackageUtils:
    def find_modules(path):
        return _find_modules(path)

class PyPackages():
    def __init__(self, buildmode, base_dir):
        self.buildmode = buildmode
        self.base = base_dir


