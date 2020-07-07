
if [[ "$NUKE_VENV" == "1" ]]; then
  (set +e; command rm -rf .venv-1 _borg)
fi



if [[ "$PANE_MODE" == "1" || $- == *i* ]]; then
    >&2 ansi --green "Running in pane mode"
    source ./run_panes.sh
else
    >&2 ansi --yellow "Running in standard mode"
    source ./run.sh
fi

