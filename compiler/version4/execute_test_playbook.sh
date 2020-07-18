#!/bin/bash -e
ANSIBLE_FORCE_COLOR=False ANSIBLE_DEBUG=False ANSIBLE_STDOUT_CALLBACK=yaml exec ./.dist_*/ansible-playbook/ansible-playbook -i localhost, -c local files/test_playbook.yaml
