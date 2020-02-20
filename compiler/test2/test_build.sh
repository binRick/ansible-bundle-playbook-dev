#!/bin/bash
set -e
BUILD_SCRIPTS="test.py test1.py test2.py" MODULES="psutil setproctitle pyaml paramiko" ./build.sh
