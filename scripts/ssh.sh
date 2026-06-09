#!/bin/bash

source "$(dirname "$0")/.env"

ssh-keygen -f '/home/nestor/.ssh/known_hosts' -R 'ssh.$VAR_DOMAIN_NAME'
ssh ubuntu@ssh.$VAR_DOMAIN_NAME
