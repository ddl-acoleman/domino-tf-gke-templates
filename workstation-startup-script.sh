#!/bin/sh

#update apt package index
sudo apt-get update -y

#Install packages to allow apt to use a repository over HTTPS
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y

#Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#set up stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

#Install latest version of Docker Engine - Community and containerd
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

#generate kubeconfig entry for domino cluster
gcloud container clusters get-credentials ${cluster}