import re, json, os, requests, urllib3, time
import parse_nagios
from halo import Halo

import otherFile as OF



if __name__ == "__main__":
    OF.something()
    spinner = Halo(text='Loading', spinner='dots')
    spinner.start()
    time.sleep(3)
    spinner.stop()
    OF.something()
    print(json.dumps(parse_nagios.read_status()))
