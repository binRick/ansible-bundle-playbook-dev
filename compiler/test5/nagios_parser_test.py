#!/usr/bin/env python3
import os, sys, setproctitle, time, paramiko, parse_nagios, json

if not 'NAGIOS_STATUS_FILE_PATH' in os.environ.keys():
    os.environ['NAGIOS_STATUS_FILE_PATH'] = '.status.dat'

print(json.dumps(parse_nagios.read_status()))
sys.exit(0)
