#!/bin/bash

source "$(dirname "$0")/.env"

cd ..

terraform init -backend-config="bucket=$BUCKET_NAME" \
               -backend-config="key=OCI-server-foundation-dev/terraform.tfstate" \
               -backend-config="region=us-east-1"