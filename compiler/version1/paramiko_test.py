#!/usr/bin/env python3
import paramiko, os, json, sys, socket, select, threading, traceback, subprocess, time, getpass, tempfile, pathlib, argparse, base64

parser = argparse.ArgumentParser()
parser.add_argument('--verbose', '-v', action='store_true', help='Verbose Mode')
parser.add_argument('--test', '-t', action='store_true', help='Test Mode')
parser.add_argument('--debug', '-d', action='store_true', help='Debug Mode')
parser.add_argument('--playProcessor', '-pp', action='store_true', help='Play Processor')
parser.add_argument('--whmcs-config-file', '-wcf', action='store', help='WHMCS Configuration File', dest='whmcs_config_file')
args = parser.parse_args()


CMD = 'cat /var/log/nagios/status.dat'

hostname = os.environ['XP_h']
username = os.environ['XP_ru']
password = os.environ['XP_rp']

if args.test:
    print("OK")
    sys.exit(0)

client = paramiko.SSHClient()
client.load_system_host_keys()
client.set_missing_host_key_policy(paramiko.WarningPolicy())
#key = paramiko.RSAKey(data=base64.b64decode(b'AAA...'))
#client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
#client.get_host_keys().add('ssh.example.com', 'ssh-rsa', key)
client.connect(hostname,username=username,password=password)

stdin, stdout, stderr = client.exec_command(CMD)

if not args.debug:
    print(''.join(stdout).strip())
    sys.exit(0)


for line in stdout:
    print(' stdout>             {}'.format(line.strip()))
for line in stderr:
    print(' stderr>             {}'.format(line.strip()))

client.close()

print("OK")


