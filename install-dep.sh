#!/bin/bash
sudo apt update -yq  && \ 
sudo apt upgrade -yq && \
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    nmon \
    net-tools \
    apache2-utils -yq && \
sudo mkdir -m 0755 -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg && \
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
sudo apt-get update -y && \
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  -yq && \
sudo usermod -aG docker way2admin