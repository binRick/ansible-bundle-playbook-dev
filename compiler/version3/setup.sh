cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
for x in ../constants.sh ../utils.sh run-constants.sh run-vars.sh run-utils.sh; do
 source $x
done
[[ -d "$ORIG_DIR" ]] && cd $ORIG_DIR

