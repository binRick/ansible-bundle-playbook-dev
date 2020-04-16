from __future__ import print_function
import os, sys, json, time, subprocess, base64, pprint, traceback, psutil, shutil, tempfile, traceback, psutil, threading,  optparse, re
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





DEFAULT_VERBOSE_MODE = False
REMOTE_EXECUTION_ENV_VAR_KEY = 'REMOTE_PLAYBOOK_EXECUTION'
DEBUG_FILTER = False
HELP = """\
Remote Execution Process Monitor
"""

def get_all_pids():
    return psutil.pids()


def parse_options():
    parser = optparse.OptionParser(
        usage="usage: %prog [options]",
        version="%prog 1.0",
        description=HELP,
    )
    parser.add_option(
        "-k",
        "--env-key",
        dest="env_key",
        default=REMOTE_EXECUTION_ENV_VAR_KEY,
        help="Environment Key",
    )
    parser.add_option(
        "-v",
        "--env-val",
        dest="env_val",
        default=None,
        help="Environment Val",
    )
    parser.add_option(
        "-d",
        "--display-mode",
        dest="display_mode",
        default="stats",
        help="Display Mode (stats or pids)",
    )
    parser.add_option(
        "-o",
        "--output-mode",
        dest="output_mode",
        default="json",
        help="Output Mode",
    )
    parser.add_option(
        "-p",
        "--pid",
        dest="pid",
        default=None,
        help="Restrict to PID",
    )
    parser.add_option(
        "-q",
        "--quiet",
        action="store_false",
        dest="verbose",
        default=DEFAULT_VERBOSE_MODE,
        help="squelch all verbose output",
    )
    options, args = parser.parse_args()
    return options, args


def get_threads_cpu_percent(PID, interval=0.1):
    R = {}
    try:
        try:
            p = psutil.Process(PID)
        except Exception as e:
            return None

        try:
            total_time = sum(p.cpu_times())
            total_percent = p.cpu_percent(interval)
            threads_qty = p.num_threads()
            exe = p.exe()
            status = p.status()

        except Exception as e:
            total_time = None
            total_percent = None
            threads_qty = None
            exe = None
            status = None

        return {
            'pid':PID, 
            'cpu_percent':total_percent,
            'cpu_time':total_time,
            'threads_qty':threads_qty,
            'exe':exe,
            'status':status,
        }

    except Exception as e:
        traceback.print_exc()
        return None

def main():
        options, args = parse_options()
        if options.pid:
            LOCAL_PIDS = [int(options.pid)]
        else:
            LOCAL_PIDS = get_all_pids()

        if options.verbose:
            print('options=', options,'args=', args)
            print('LOCAL_PIDS=', LOCAL_PIDS)

        def filterProcess(pid):
            try:
                pid_env = psutil.Process(pid).environ()
            except psutil.NoSuchProcess as e:
                return False
            except psutil.AccessDenied as e:
                return False
            except Exception as e:
                traceback.print_exc()
                return False

            return options.env_key in pid_env.keys() and (
                (options.env_val != None and str(pid_env[options.env_key]) == options.env_val) or
                (options.env_val == None)
            )


        if DEBUG_FILTER:
            for _p in LOCAL_PIDS:
                print('pid=', _p, 'state=', filterProcess(_p))

        managed_pids = list(filter(filterProcess, LOCAL_PIDS))

        if options.display_mode == 'stats':
            inspected_pids = list(map(get_threads_cpu_percent, managed_pids))
            OUT_LIST = inspected_pids
        elif options.display_mode == 'pids':
            OUT_LIST = managed_pids
        else:
            raise Exception('Unknown display mode type')

        if options.output_mode == 'json':
            print(json.dumps(OUT_LIST))
        else:
            for p in OUT_LIST:
                print("{}".format(json.dumps(p)))


if __name__ == "__main__":
    main()
