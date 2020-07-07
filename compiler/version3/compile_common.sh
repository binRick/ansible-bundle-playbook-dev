set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi

EXTRACE_MODE_ENABLED=0

if [[ "$EXTRACE_MODE_ENABLED" == "1" ]]; then
    ansi --yellow --bold "Extrace Mode Enabled"
fi

