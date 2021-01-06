#!/bin/bash

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
git clone https://github.com/k8-proxy/k8-rebuild.git --recursive && cd k8-rebuild && git submodule foreach git pull origin main

# build docker images
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io -y

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

sudo apt-get install -y linux-image-4.15.0-1087 
sudo apt-get purge --allow-remove-essential linux-image-5.
