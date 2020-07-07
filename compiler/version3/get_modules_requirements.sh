pip freeze|cut -d'=' -f1|while read -r  module ; do
echo -ne "$module:"
pip show $module|grep Requires|cut -d':' -f2 || echo -e ""
done
