#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


tmux-xpanes -e "tail -f .stderr" "tail -f .combined.std"
