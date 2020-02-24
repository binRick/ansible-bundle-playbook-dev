load_vars(){
    >&2 ansi --cyan "  Loading $(wc -l vars.sh) Vars.."
    source vars.sh
}

