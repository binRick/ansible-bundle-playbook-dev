#!/usr/bin/env python3
import os
os.environ['NAGIOS_STATUS_FILE_PATH'] = '.status.dat'

import sys, setproctitle, time, paramiko, parse_nagios, json

print(json.dumps(parse_nagios.read_status()))
sys.exit(0)
