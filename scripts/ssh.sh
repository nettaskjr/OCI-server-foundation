#!/bin/bash

ssh-keygen -f '/home/nestor/.ssh/known_hosts' -R 'ssh.nettask.com.br'
ssh ubuntu@ssh.nettask.com.br
