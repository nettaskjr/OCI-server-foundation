#!/bin/bash

cd ..

terraform init -backend-config="bucket=terraform-nettask.com.br" \
               -backend-config="key=OCI-server-foundation-dev/terraform.tfstate" \
               -backend-config="region=us-east-1"