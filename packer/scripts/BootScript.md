# Script that ask during first boot for network parameters, password and hostanme

 -   sudo su -

 -   vi /usr/bin/initconfig.sh

```bash
#!/bin/bash

sleep 10
clear
echo "



InitConfig

"

#nowe haslo dla uzytkownika glasswall
while ! sudo passwd glasswall; do
	sleep 1
done

#hostname
echo -n 'Hostname: '
read hostname
hostnamectl set-hostname $hostname

#IP komputera
#Maska podsieci
#Gateway
#DNSY moga byc po przecinku.

until echo $ipaddr | egrep '(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9]\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])/[1-2][0-9]|3[0-1]'; do
	echo -n 'IP address with prefix (ex. 192.168.1.1/24): '
	read ipaddr
done

until echo $gateway | egrep '(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9]\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'; do
	echo -n 'Default gateway address (ex. 192.168.1.254): '
	read gateway
done

until echo $dns | egrep '(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9]\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'; do
	echo -n 'DNS address (ex. 8.8.8.8[,...]): '
	read dns
done

ifname=`ip l | awk '/^[1-9]/ {sub(":","",$2);if ($2=="lo") next; print $2;nextfile}'`

rm /etc/netplan/*

echo "
network:
  ethernets:
    $ifname:
      addresses:
        - $ipaddr
      gateway4: $gateway
      nameservers:
        addresses: [ $dns ]
" > /etc/netplan/config.yaml

netplan apply

systemctl disable initconfig

reboot

exit
```

 -   chmod 755 /usr/bin/initconfig.sh
	
 -   vi /etc/systemd/system/initconfig.service
	
```bash
[Unit]
Description=InitConfig

[Service]
Type=oneshot
ExecStart=/usr/bin/openvt -s -w /usr/bin/initconfig.sh

RemainAfterExit=yes
TimeoutSec=0

# Output needs to appear in instance console output
StandardOutput=journal+console

[Install]
WantedBy=cloud-init.target
```
 -   systemctl daemon-reload
	
 -   systemctl enable initconfig
 
 To reanable First Boot experience you can issue only the last command.
