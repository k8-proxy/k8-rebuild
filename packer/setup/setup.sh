#!/bin/bash

# conditionally enable tls
if [ "$ENABLE_TLS" = "true" ]
then
   echo "TLS is enabled"
   sudo mkdir -p /var/lib/rancher/k3s/server/manifests/
   sudo touch /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
   sudo chmod 777 /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
   sudo cat >> /var/lib/rancher/k3s/server/manifests/traefik-config.yaml <<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ssl:
      enabled: true
      enforced: true
      insecureSkipVerify: true
      generateTLS: true
EOF
else
   echo "TLS is disabled"
fi

# install k3s
curl -sfL https://get.k3s.io | sh -
mkdir ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install kubectl and helm
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "Done installing kubectl"

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# get source code
sudo yum install -y git
git clone https://github.com/k8-proxy/k8-rebuild.git --recursive && cd k8-rebuild && git submodule foreach git pull origin main

# build docker images
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo chkconfig docker on
# install local docker registry
sudo docker run -d -p 30500:5000 --restart always --name registry registry:2

# build images
sudo docker build k8-rebuild-rest-api -f k8-rebuild-rest-api/Source/Service/Dockerfile -t localhost:30500/k8-rebuild-rest-api
sudo docker push localhost:30500/k8-rebuild-rest-api
sudo docker build k8-rebuild-file-drop/app -f k8-rebuild-file-drop/app/Dockerfile -t localhost:30500/k8-rebuild-file-drop
sudo docker push localhost:30500/k8-rebuild-file-drop

cat >> kubernetes/values.yaml <<EOF

sow-rest-api:
  image:
    registry: localhost:30500
    repository: k8-rebuild-rest-api
    imagePullPolicy: Never
    tag: latest
sow-rest-ui:
  image:
    registry: localhost:30500
    repository: k8-rebuild-file-drop
    imagePullPolicy: Never
    tag: latest
EOF
# install UI and API helm charts
helm upgrade --install k8-rebuild \
  --set nginx.service.type=ClusterIP \
  --atomic kubernetes/

# create a user
sudo useradd -p $(openssl passwd -1 glasswall) glasswall
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service sshd restart
