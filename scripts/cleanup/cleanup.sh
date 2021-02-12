#!/bin/bash
DEBIAN_FRONTEND=noninteractive
# Apt clean up
sudo rm -f /var/lib/apt/lists/* 2>/dev/null || true
sudo apt clean all
sudo rm -f /home/*/.ssh/*
# Logs clean up
sudo logrotate --force /etc/logrotate.conf
sudo journalctl --rotate && sudo journalctl --vacuum-size=1
# Network clean up
sudo rm -f /etc/netplan/*.yml /etc/netplan/*.yaml
sudo tee /etc/netplan/network.yaml >/dev/null <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF
# Shell history clean up
history -c && history -w
