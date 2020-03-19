import re, json, os, requests, urllib3, time, sys, libtmux
from halo import Halo


if __name__ == "__main__":
    spinner = Halo(text='Testing Tmux Integration', spinner='dots')
    spinner.start()
    time.sleep(3)
    try:
        server = libtmux.Server()
        sessions = server.list_sessions()
        spinner.succeed('Tmux Connection Established. Detected {} Sessions'.format(len(sessions)))
        sys.exit(0)
    except Exception as e:
        spinner.fail('Tmux Connection Failed: {}'.format(e))
        sys.exit(1)
