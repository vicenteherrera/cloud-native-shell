FROM debian:11

WORKDIR /install

# General
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y apt-utils curl gnupg2 apt-transport-https lsb-release sudo unzip
        
# Development (git, vim, build, python, ruby)
RUN apt-get -y install python3-pip git vim build-essential ruby-full zlib1g-dev conntrack
# conntrack is a Kubernetes 1.20.2 requirement

# Kubectl
RUN apt-get install -y apt-transport-https ca-certificates curl && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
    | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl

# Kubectx, Kubens
RUN curl -sLo kubectx https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx && \
    chmod +x kubectx && mv kubectx /usr/local/bin && \
    curl -sLo kubens https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens && \
    chmod +x kubens && mv kubens /usr/local/bin

# Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && rm ./get_helm.sh

# Docker (in Docker)
RUN apt-get install -y lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io 

# AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -r ./aws awscliv2.zip

# Azure cli
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor | \
        tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
        tee /etc/apt/sources.list.d/azure-cli.list && \
        apt-get update && apt-get install azure-cli

# Vagrant
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
    echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
    apt-get -y update && apt-get install -y vagrant
# This will require an additional virtualization hypervisor

# Minikube
ARG minikube_ver=1.23.2
RUN curl -sLo minikube https://storage.googleapis.com/minikube/releases/v${minikube_ver}/minikube-linux-amd64 \
  && chmod +x minikube && \
    mv minikube /usr/local/bin

# Stern
ARG stern_ver=1.11.0
RUN curl -sLo stern https://github.com/wercker/stern/releases/download/${stern_ver}/stern_linux_amd64 && \
    chmod +x stern && \
    mv stern /usr/local/bin

# Fish shell
RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' \
    | tee /etc/apt/sources.list.d/shells:fish:release:3.list && \
    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key \
    | gpg --dearmor | tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null && \
    apt-get update && apt-get install -y fish

# Starship prompt
RUN curl -sS https://starship.rs/install.sh >./install.sh && \
    sh ./install.sh --yes && \
    rm install.sh

# Set user and group
ARG user=vicente
ARG group=developer
ARG uid=1000
ARG gid=1000
ARG pass=changeme

RUN groupadd -g ${gid} ${group} && \
    useradd -u ${uid} -g ${group} -s /usr/bin/fish -m ${user} && \
    usermod -aG sudo ${user} && \
    usermod -aG docker ${user} && newgrp docker && \
    sudo usermod --shell /bin/bash vicente && \
    echo "${user}:${pass}" | chpasswd

# Switch to user
USER ${uid}:${gid}
WORKDIR /home/${user}

# Kubectl completions
RUN echo 'source <(kubectl completion bash)' >>/home/vicente/.bashrc && \
    echo 'alias k=kubectl' >>/home/vicente/.bashrc && \
    echo 'complete -F __start_kubectl k' >>/home/vicente/.bashrc

# GCloud cli
ARG gcloud_ver=378.0.0
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    tar -xf google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --usage-reporting false -q && \
    rm -r ./google-cloud-sdk google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz

# Pyenv
RUN curl https://pyenv.run | bash

# Poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -

# Install Jekyll
# RUN gem install jekyll bundler

ENV DEBIAN_FRONTEND=

CMD /usr/bin/fish
