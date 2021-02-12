#!/bin/bash

# increase partition size to maximum disk size
partition_name=$(df -h | grep -e /$ | cut -d" " -f1)
disk_name=/dev/$(lsblk -io KNAME,TYPE,SIZE | grep disk | cut -d" " -f1)
partition_number=${partition_name: -1}
sudo growpart $disk_name $partition_number
sudo resize2fs $partition_name

sudo tee -a /etc/init.d/update_partition <<EOF
#!/bin/bash

### BEGIN INIT INFO
# Provides:             update_partition
# Required-Start:       $local_fs $remote_fs $network $syslog $named
# Required-Stop:        $local_fs $remote_fs $network $syslog $named
# Default-Start:        2 3 4 5
# Default-Stop:         
# Short-Description:    updates partition 
# Description:          size to maximum disk size
### END INIT INFO
partition_name=\$(df -h | grep -e /$ | cut -d" " -f1)
disk_name=/dev/\$(lsblk -io KNAME,TYPE,SIZE | grep disk | cut -d" " -f1)
partition_number=\${partition_name: -1}
sudo growpart \$disk_name \$partition_number
sudo resize2fs \$partition_name
growpart \$disk_name \$partition_number
resize2fs \$partition_name
EOF
sudo chmod +x /etc/init.d/update_partition
sudo update-rc.d update_partition defaults
