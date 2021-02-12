# Script that ask during first boot for network parameters, password

## TUI Configuration Wizard

Configuration wizard, currently features the following configuration

- Change current user password

- Change network configuration

### Environment dependencies

**wizard.sh** must be run in an environment that provides the following:

- Operating system is Ubuntu server, with netplan as network configuration manager (which is the default in latest Ubuntu LTS)

- The user must be a sudoer (or **root** ), must be able to execute sudo without a passwor, this can be done as follows
  
  ```bash
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
  ```
  
  if your user is not a sudoer, you must run it as root user while replacing **`$USER`** with your username

  You'll have to configure netplan file(s) to replace interfaces names for predictable naming, for example:
  
  ```bash
  cat > /etc/netplan/network.yaml <<EOF
  network:
    version: 2
      renderer: networkd
      ethernets:
        eth0:
  #     ^^^^  Notice the interface naming
          dhcp4: false # You can switch it to true then remove following lines
          addresses:
            - 192.168.0.3/24 # Replace this with desired IP address in CIDR format
          gateway4: 192.168.0.1 # Replace this with desired gateway
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1] # Replace DNS servers if needed
  EOF
  ```
  
  You have to reboot after theses changes to apply

### Installation

- Clone the repo
  
  ```bash
  git clone https://github.com/k8-proxy/GW-proxy
  ```

- Install the wizard as following
  
  ```bash
  sudo install GW-proxy/automation/scripts/wizard/wizard.sh -T /usr/bin/wizard -m 0755
  ```

## Boot script configuration

- Create initconfig script file
```
sudo nano /usr/bin/initconfig.sh
#!/bin/bash

sleep 10
clear
echo "

InitConfig

"


/usr/bin/wizard.sh

systemctl disable initconfig

reboot
exit
```

- Change initconfig.sh to execute mode 
```
chmod 755 /usr/bin/initconfig.sh
```	
- Create init service
```
sudo nano /etc/systemd/system/initconfig.service
```
- File initconfig.service looke like below :
```
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
- Reload and enable initconfig
```
systemctl daemon-reload
	
systemctl enable initconfig
```
 
- To reanable First Boot experience you can issue only the last command.
