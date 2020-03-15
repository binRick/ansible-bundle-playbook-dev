import re, json, os, requests, urllib3, time, sys
import parse_nagios
from halo import Halo

print('OK')
sys.exit(0)

if __name__ == "__main__":
    spinner = Halo(text='Parsing Nagios Status File', spinner='dots')
    spinner.start()
    time.sleep(3)
    try:
        D = parse_nagios.read_status().strip()
        spinner.succeed('Parsed {} Bytes'.format(len(D)))
        print(json.dumps(D))
        sys.exit(0)
    except Exception as e:
        spinner.fail('NAGIOS PARSER FAILED: {}'.format(e))
        sys.exit(1)
