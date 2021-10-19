#/bin/sh

set -ex

ansible-playbook servers.yaml -i ansible.cfg
ansible-playbook clients.yaml -i ansible.cfg

exit 0
