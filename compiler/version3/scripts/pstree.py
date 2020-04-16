from __future__ import print_function
import paramiko, os, json, sys, socket, select, threading, traceback, subprocess, time, getpass, tempfile, pathlib, argparse, base64
import collections, sys, psutil




parser = argparse.ArgumentParser()
parser.add_argument('--version', '-V', action='store_true', help='Version')
parser.add_argument('--test', '-t', action='store_true', help='Test Mode')
args = parser.parse_args()


if args.version:
    print("OK")
    sys.exit(0)

if args.test:
    print("OK")
    sys.exit(0)


def print_tree(parent, tree, indent=''):
    try:
        name = psutil.Process(parent).name()
    except psutil.Error:
        name = "?"
    print(parent, name)
    if parent not in tree:
        return
    children = tree[parent][:-1]
    for child in children:
        sys.stdout.write(indent + "|- ")
        print_tree(child, tree, indent + "| ")
    child = tree[parent][-1]
    sys.stdout.write(indent + "`_ ")
    print_tree(child, tree, indent + "  ")


def main():
    # construct a dict where 'values' are all the processes
    # having 'key' as their parent
    tree = collections.defaultdict(list)
    for p in psutil.process_iter():
        try:
            tree[p.ppid()].append(p.pid)
        except (psutil.NoSuchProcess, psutil.ZombieProcess):
            pass
    # on systems supporting PID 0, PID 0's parent is usually 0
    if 0 in tree and 0 in tree[0]:
        tree[0].remove(0)
    PARENT_PID = min(tree)
    print_tree(PARENT_PID, tree)


if __name__ == '__main__':
    main()
