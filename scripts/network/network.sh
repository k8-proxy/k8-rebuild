#!/bin/bash
# Network setup
DEBIAN_FRONTEND=noninteractive
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
update-grub
rm -f /etc/netplan/*.yml /etc/netplan/*.yaml
cat > /etc/netplan/network.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF

