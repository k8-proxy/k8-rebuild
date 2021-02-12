#!/bin/bash
# Agent install
sudo apt-get update
wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
echo 'deb https://packages.fluentbit.io/ubuntu/focal focal main' | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y td-agent-bit
sudo service td-agent-bit start
