./paramiko_test.py > .status.dat
NAGIOS_STATUS_FILE_PATH=.status.dat ./nagios_parser_test.py|jq
