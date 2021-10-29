#!/bin/sh

set -eux

cd terraform
# reconfigure the backend, ignoring any saved config
terraform init -reconfigure
terraform apply --auto-approve
cd ../ansible
./init-agents.sh

exit 0
