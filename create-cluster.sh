#!/bin/sh

set -eux

cd terraform
terraform apply --auto-approve
cd ../ansible
./init-agents.sh

exit 0
