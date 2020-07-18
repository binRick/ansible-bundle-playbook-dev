#!/bin/bash

while read -r ap; do
    echo -e "$ap --version && \\n$ap -i localhost, files/test_playbook.yaml"
done < <(./find_ansible-playbook.sh)

