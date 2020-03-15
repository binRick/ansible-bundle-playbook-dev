setupWhile(){
    echo "sleep $INITIAL_SLEEP && while [ 1 ]; do $@; done"
}
setupTail(){
    echo "tail -n0 -f $@"
}

