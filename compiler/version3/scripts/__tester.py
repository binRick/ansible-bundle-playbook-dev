import paramiko, os, json, sys, socket, select, threading, traceback, subprocess, time, getpass, tempfile, pathlib, argparse, base64

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



print("OK - test.py. sleeping...")
time.sleep(15)
print("DONE")
