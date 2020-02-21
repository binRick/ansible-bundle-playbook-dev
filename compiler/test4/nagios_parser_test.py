#!/usr/bin/env python3
import os, sys, setproctitle, time, paramiko, parse_nagios, json

print(json.dumps(parse_nagios.read_status()))
print("OK")
print("DONE")
