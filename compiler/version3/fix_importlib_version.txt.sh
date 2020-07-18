[[ -d .venv-1/lib64/python3.6/site-packages/importlib_resources ]] && \
    echo -e "$(pip show importlib_resources|grep Version|cut -d' ' -f2)" > .venv-1/lib64/python3.6/site-packages/importlib_resources/version.txt

true
