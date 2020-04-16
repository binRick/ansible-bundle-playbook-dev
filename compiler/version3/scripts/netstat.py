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


import socket, psutil
from socket import AF_INET, SOCK_STREAM, SOCK_DGRAM

AD = "-"
AF_INET6 = getattr(socket, 'AF_INET6', object())
proto_map = {
    (AF_INET, SOCK_STREAM): 'tcp',
    (AF_INET6, SOCK_STREAM): 'tcp6',
    (AF_INET, SOCK_DGRAM): 'udp',
    (AF_INET6, SOCK_DGRAM): 'udp6',
}


def main():
    templ = "%-5s %-30s %-30s %-13s %-6s %s"
    print(templ % (
        "Proto", "Local address", "Remote address", "Status", "PID",
        "Program name"))
    proc_names = {}
    for p in psutil.process_iter(['pid', 'name']):
        proc_names[p.info['pid']] = p.info['name']
    for c in psutil.net_connections(kind='inet'):
        laddr = "%s:%s" % (c.laddr)
        raddr = ""
        if c.raddr:
            raddr = "%s:%s" % (c.raddr)
    
        MSG = templ % (
            proto_map[(c.family, c.type)],
            laddr,
            raddr or AD,
            c.status,
            c.pid or AD,
            proc_names.get(c.pid, '?')[:15],
        )
        print(MSG)


if __name__ == '__main__':
    main()
