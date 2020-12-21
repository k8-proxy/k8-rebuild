#!/bin/bash

# This is a placeholder script, you can move your setup script here to install some custom deployment on the VM
# The parent directory of this script will be transferred with its content to the VM under /tmp/setup path
# (i.e: useful for copying configs, scripts, systemd units, etc..)  

# install k3s
curl -sfL https://get.k3s.io | sh -

# install kubectl and helm
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "Done installing kubectl"

# curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
# echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# sudo apt-get update
# sudo DEBIAN_FRONTEND=noninteractive apt-get install helm -y
curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# install helm chart
git clone https://github.com/k8-proxy/k8-rebuild.git --recursive && cd k8-rebuild && git submodule foreach git pull origin main
mkdir ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

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

# install docker registry
helm repo add stable https://charts.helm.sh/stable
helm repo update
helm upgrade --install docker-registry \
  --set service.type=NodePort \
  --set service.nodePort=30500 stable/docker-registry

# build images
sudo docker build sow-rest-api -f sow-rest-api/Source/Service/Dockerfile -t localhost:30500/sow-rest-api
sudo docker push localhost:30500/sow-rest-api
sudo docker build sow-rest-UI/app -f sow-rest-UI/app/Dockerfile -t localhost:30500/sow-rest-ui
sudo docker push localhost:30500/sow-rest-ui

# TODO: remove this
mkdir -p kubernetes/templates
cat > kubernetes/templates/ingress.yaml <<EOF
{{ if (eq .Values.nginx.service.type "ClusterIP") }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: k8-rebuild
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sow-rest
            port:
              number: 80
{{- end -}}
EOF
cat >> kubernetes/values.yaml <<EOF

sow-rest-api:
  image:
    registry: localhost:30500
    repository: sow-rest-api
    imagePullPolicy: Never
    tag: latest
sow-rest-ui:
  image:
    registry: localhost:30500
    repository: sow-rest-ui
    imagePullPolicy: Never
    tag: latest
EOF
# install UI and API helm charts
helm upgrade --install k8-rebuild \
  --set nginx.service.type=ClusterIP \
  --atomic kubernetes/

# delete docker-registry helm chart
helm delete docker-registry
