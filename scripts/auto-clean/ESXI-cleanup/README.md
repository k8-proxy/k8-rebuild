# scripts

## esxi_cleanup.py :

-  This script deletes VMs that it's age exceeds the number of expire days defined in environment variable **ESXI_EXPIRE_DAYS** except for the VMs with note that include **DONT_DELETE_NOTE** variable, Also will delete any VM with note that matches the environment variable **DELETE_NOTE** 
- Required environment variables:

```tex
 	VSPHERE_HOST=
 	VSPHERE_USERNAME=
 	VSPHERE_PASSWORD=
 	DELETE_NOTE=
 	DONT_DELETE_NOTE=
 	ESXI_EXPIRE_DAYS
```