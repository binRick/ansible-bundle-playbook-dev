[[ -f ~/.ansi ]] && source ~/.ansi
get_cached_module_dir(){
    _DIR="$CACHED_MODULES_DIR/$1"
    [[ ! -d "$_DIR" ]] && mkdir -p $_DIR
    echo $_DIR
}

get_mangle_vars_file(){
    x="$(basename $1 .py)"
    x_mangle_vars=".${x}_mangled_vars.txt"
    echo $x_mangle_vars
}

get_mangled_var(){
    (source $1 && echo ${!2})
}

load_vars(){
    >&2 ansi --cyan "  Loading $(wc -l vars.sh) Vars.."
    source vars.sh
}

getVenvModules(){

    (
	(cd $VIRTUAL_ENV/lib/python3.6/site-packages && ls *.py|xargs -I % echo %|sed 's/.py$//g'|sort -u)

cmd="    	cd  $VIRTUAL_ENV && \
		find . \
\
\
		| egrep '__init__.py$' \
		| cut -d'/' -f5 \
		| sort -u \
"
	eval $cmd		
	
    ) 2>/dev/null
}

getModules(){
  (
    for x in $MODULES; do
        pip install $x -q
        findModules_venv $x | mangleModules
    done
  ) | egrep -v '^$' | sort -u | tr '\n' ' '
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

mangleModules_xargs(){
    sed 's/\//./g'| xargs -I % echo -e "         --hidden-import=\"%\" "
}

mangleModules_sed(){
    sed 's/^/     --hidden-import="/' \
        | sed 's/$/"/g' \
        | sed 's/\//./g'
}

mangleModules(){
    mangleModules_sed $@ | tr ' ' '\n' | egrep -iv 'pyinstaller' \
       | grep -v '^$'
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
   ) | sort | uniq | sed 's/\//./g'
}

findModules_venv(){
    findModules $1 $VIRTUAL_ENV/lib/python3.6/site-packages
}


_findAllVenvModules(){    
    M=$(mktemp)
   ( for m in $(getVenvModules|egrep -v '^pyinstaller|^pytest|^pygments|^py._|^importlib_metadata|^importlib_resources|^docutils|^coverage|^bleach|^PyInstaller|^_pytest'); do
        findModules_venv $m
    done
   ) | sort -u
# > $M

#    if [[ "$_EXCLUDE_ANSIBLE_MODULES" == "1" ]]; then
#        cat $M | excludeRawAnsibleModules
#    else
#        cat $M
#    if 
#    unlink $M
}

excludeRawAnsibleModules(){
    egrep -v '^ansible\.'
}

findBorgModules(){
    if [[ "$BUILD_BORG" == "1" ]]; then
        if [[ -f borg/__init__.py ]]; then
            >&2 ansi --green BORG FOUND
            findModules borg .
        else
            >&2 ansi --yellow BORG MISSING
        fi
    else
         >&2 ansi --yellow BORG Excluded from build
    fi
}
findAllVenvModules(){    
    a=$(mktemp)
    b=$(mktemp)
    c=$(mktemp)
    _findAllVenvModules  > $a
    getExcludedAnsibleModules > $b
    comm -23 $a $b
}


getExcludedAnsibleModules(){
   echo $EXCLUDED_ANSIBLE_MODULES | tr ' ' '\n' | grep -v '^$' | sort -u
}
    
addAdditionalAnsibleModules(){
    MODULE_TYPE=$1
    MODULE_TYPE_DIR=$2
    __MODULES="$3"
    for m in $(echo "$__MODULES"|tr ' ' '\n'); do
        mFile="$(basename $m)"
        mDir="$(dirname $m)"
        mCmdDir="$(getAnsiblePath)/${MODULE_TYPE}/${MODULE_TYPE_DIR}"
        if [[ ! -f $mCmdDir/$mFile ]]; then
            if [[ ! -d "$mCmdDir" ]]; then mkdir -p $mCmdDir; fi
            if [[ "$m" == http* ]]; then
                    (cd $mCmdDir && curl -ks $m > $mFile)
            else
                mT=$(mktemp -d)
                _m=$mT/$(basename $m)
                m=$_m
                mCmd="cp $mDir/$mFile $mCmdDir/$mFile"
                eval $mCmd
            fi
        fi
    done
}

getSitePackagesPath(){
    echo "$VIRTUAL_ENV/lib/python3.6/site-packages"
}
getAnsiblePath(){
    echo "$VIRTUAL_ENV/lib/python3.6/site-packages/ansible"
}
getAnsiblePluginsPath(){
    echo $(getAnsiblePath)/plugins
}
getAnsibleModulesPath(){
    echo $(getAnsiblePath)/modules
}



customize_ansible_environment(){
    addAdditionalAnsibleModules plugins callback "$ADDITIONAL_ANSIBLE_CALLLBACK_MODULES"
    addAdditionalAnsibleModules modules library "$ADDITIONAL_ANSIBLE_LIBRARY_MODULES"
}



