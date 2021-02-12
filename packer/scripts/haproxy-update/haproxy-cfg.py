import yaml
import os

# Open and Read icap-servers.yaml content
with open("icap-servers.yaml", 'r') as yamlFile:
    data = yaml.safe_load(yamlFile)

# Get servers Values (Name, IP & Port)
target  = data.get("all.icap.glasswall-icap.com")
names   = []
ips     = []
port    = []
for server in target:
    names.append(server.get('name'))
    ips.append(server.get('ip'))
    port.append(server.get('port'))

# Rephrase with haproxy.cfg format
servers         = []
for x, y, z in zip(names, ips, port):
    servers.append("  server " + x + " " + y + ":" + str(z) + " check")
servers         = "\n".join(servers)

# create a new haproxy.cfg from the template file and overwrite the existing one
template_file   = open("haproxy.tmp", "r")
content         = template_file.readlines()
template_file.close()
content.insert(45, servers)
generated_file  = open("/etc/haproxy/haproxy.cfg", "w")
content 		= "".join(content)
generated_file.write(content)
generated_file.close()

# Reload HAproxy Service
os.system("sudo /etc/init.d/haproxy reload")
os.system("sudo /etc/init.d/haproxy status | head -11")