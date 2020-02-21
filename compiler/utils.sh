[[ -f .ansi ]] && source .ansi || source ~/.ansi

getModules(){
    for x in $MODULES; do
        pip install $x -q
        findModules_venv $x | mangleModules
    done
}

replaceModuleName(){
    _M="$1"
    for r in $(echo "$ADDITIONAL_COMPILED_MODULES_REPLACEMENTS"|tr ' ' '\n'); do
        s1="$(echo $r|cut -d'|' -f1)"
        s2="$(echo $r|cut -d'|' -f2)"
        if [[ "$s1" == "$_M" ]]; then
            __M="$_M"
            _M=$(echo $_M|sed "s/^$s1\$/$s2/g")
            >&2 echo -e "        Changed Module name from \"$__M\" -> \"$_M\" based on r=$r, s1=$s1, s2=$s2"
        else
            [[ "0" == "1" ]] && >&2 echo -e "       module \"$_M\" does not match s1 \"$s1\" "
        fi
    done
    echo "$_M"
}

mangleModules(){
    sed 's/\//./g'| xargs -I % echo -e "         --hidden-import=\"%\" "
}







findModules(){
    _M="$1"
    _M="$(replaceModuleName $_M)"
   (
    set -e
        cd $2/
    if [[ ! -d "$_M" ]]; then
        >&2  echo -e "\n\n    Module \"$_M\" Find Failed ->    Directory \"$_M\" Does not exist in $(pwd) !\n\n"
        echo $_M
    else
        find $_M \
                | grep '\.py$'|grep '/'  | sed 's/\.py//g' | sed 's/\/__init__//g'

        find $_M \
                | grep '\.py$'| grep __init__.py$ |grep '/'| grep '/' | sed 's/\/__init__.py$//g'
    fi
   ) | sort | uniq
}

findModules_venv(){
    findModules $1 $VIRTUAL_ENV/lib/python3.6/site-packages
}





