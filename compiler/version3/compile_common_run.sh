
if [[ "$NUKE_VENV" == "1" ]]; then
  (set +e; command rm -rf .venv-1 _borg)
fi



if [[ "$PANE_MODE" == "1" || $- == *i* ]]; then
    ansi --green "Running in pane mode"
    exec ./run_panes.sh
else
    ansi --yellow "Running in standard mode"
    exec ./run.sh
fi
