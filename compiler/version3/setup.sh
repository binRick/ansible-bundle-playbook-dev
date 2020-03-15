cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

_SOURCES="../constants.sh ../utils.sh run-constants.sh run-vars.sh run-utils.sh .concurrent.lib.sh"


echo $_SOURCES
for x in $(echo "$_SOURCES"|tr ' ' '\n'); do
 source $x
done

[[ "$ORIG_DIR" != "" && -d "$ORIG_DIR" ]] && cd $ORIG_DIR

