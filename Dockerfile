ARG debian_ver=11
FROM debian:${debian_ver}

WORKDIR /install

# General
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y \
        apt-utils software-properties-common  apt-transport-https lsb-release \
        gnupg gnupg2 curl wget unzip sudo \
        zsh nano \
        swig libpcsclite-dev
# Last line for Yubikey manager
        
# Development (git, vim, build, python, ruby)
RUN apt-get -y install \
        git vim build-essential direnv bat \
        python3-dev python3-pip python3-setuptools \
        npm \
        ruby-full zlib1g-dev \
        podman buildah skopeo \
        prometheus prometheus-alertmanager \
        conntrack
# conntrack is a Kubernetes 1.20.2 requirement

# Kubectl
RUN apt-get install -y apt-transport-https ca-certificates curl && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
    | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/kubernetes.list && \
    apt-get install -y kubectl

# Docker (in Docker)
RUN apt-get install -y lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/docker.list && \
    apt-get install -y docker-ce docker-ce-cli containerd.io 

# Azure cli
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" \
        | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/azure-cli.list && \
    apt-get install azure-cli

# Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install trivy

# Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Terraform, Vagrant
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
    echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/hashicorp.list && \
    apt-get install -y vagrant terraform
# Vagrant will require an additional virtualization hypervisor

# GitHub cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/github-cli.list && \ 
    apt install gh

# Kubectx, Kubens
RUN curl -sLo kubectx https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx && \
    chmod +x kubectx && mv kubectx /usr/local/bin/ && \
    curl -sLo kubens https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens && \
    chmod +x kubens && mv kubens /usr/local/bin/

# Helm 3
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && rm ./get_helm.sh

# AWS cli 2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -r ./aws awscliv2.zip

# # Sysdig
# RUN curl -s https://s3.amazonaws.com/download.draios.com/stable/install-sysdig | bash

# OpenShift 4 cli
RUN curl -sLo oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar -xvf oc.tar.gz && \
    chmod +x oc && mv oc /usr/local/bin/ && \
    rm README.md kubectl oc.tar.gz

# eksctl
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
        | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# Dotnet
ARG dotnet_ver=6.0
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-${dotnet_ver}
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Minikube
ARG minikube_ver=1.23.2
RUN curl -sLo minikube https://storage.googleapis.com/minikube/releases/v${minikube_ver}/minikube-linux-amd64 \
  && chmod +x minikube && \
    mv minikube /usr/local/bin/

# Minishift
# https://github.com/minishift/minishift/releases
ARG minishift_ver=1.34.3
RUN curl -sLo ms.tgz https://github.com/minishift/minishift/releases/download/v${minishift_ver}/minishift-${minishift_ver}-linux-amd64.tgz && \
    tar -xvf ms.tgz && \
    chmod +x minishift-${minishift_ver}-linux-amd64/minishift && \
    mv minishift-${minishift_ver}-linux-amd64/minishift /usr/local/bin/ && \
    rm -r minishift-${minishift_ver}-linux-amd64

# Kind
ARG kind_ver=0.12.0
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${kind_ver}/kind-linux-amd64 && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/

# Stern
ARG stern_ver=1.11.0
RUN curl -sLo stern https://github.com/wercker/stern/releases/download/${stern_ver}/stern_linux_amd64 && \
    chmod +x stern && \
    mv stern /usr/local/bin/

# Helmfile
ARG helmfile_ver=0.144.0
RUN curl -sLo helmfile https://github.com/roboll/helmfile/releases/download/v0.144.0/helmfile_linux_amd64 && \
    chmod +x helmfile && \
    mv helmfile /usr/local/bin/

# Go
ARG go_ver=1.18
RUN curl -sLo go.tar.gz https://go.dev/dl/go${go_ver}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# 1Password
ARG 1password_ver=2.0.0
RUN curl -sLo op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v2.0.0/op_linux_amd64_v2.0.0.zip && \
    unzip op.zip && mv op /usr/local/bin/ && rm op.zip op.sig
# gpg --verify op.sig op

# StackRox cli
ARG roxctl_ver=3.68.1
RUN curl -O https://mirror.openshift.com/pub/rhacs/assets/${roxctl_ver}/bin/Linux/roxctl && \
    chmod +x roxctl && \
    mv roxctl /usr/local/bin/

# KubeAudit
ARG kubeaudit_ver=0.17.0
RUN curl -sLo kubeaudit.tar.gz https://github.com/Shopify/kubeaudit/releases/download/${kubeaudit_ver}/kubeaudit_${kubeaudit_ver}_linux_amd64.tar.gz && \
    tar -xvf kubeaudit.tar.gz && chmod +x kubeaudit && \
    mv kubeaudit /usr/local/bin/ && rm kubeaudit.tar.gz README.md

# Audit2RBAC
ARG audit2rbac_ver 0.9.0
RUN curl -sLo audit2rbac.tar.gz https://github.com/liggitt/audit2rbac/releases/download/v${audit2rbac_ver}/audit2rbac-linux-amd64.tar.gz && \
    tar -xvf audit2rbac.tar.gz && \
    chmod +x audit2rbac && \
    mv audit2rbac /usr/local/bin/ && rm audit2rbac.tar.gz

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

# Clean APT cache
RUN apt clean

# ------------------------------------------------------------------------------------

# Set user and group
ARG user=vicente
ARG group=developer
ARG uid=1000
ARG gid=1000
ARG pass=changeme
ARG shell=/usr/bin/fish

RUN groupadd -g ${gid} ${group} && \
    useradd -u ${uid} -g ${group} -s ${shell} -m ${user} && \
    usermod -aG sudo ${user} && \
    usermod -aG docker ${user} && newgrp docker && \
    echo "${user}:${pass}" | chpasswd

RUN mkdir -p /home/${user}/.config/fish/completions \
        /home/${user}/.config/fish/conf.d \
        /home/${user}/.config/fish/functions && \
    chown -R ${user}:${group} /home/${user}

# Switch to user
USER ${uid}:${gid}
WORKDIR /home/${user}
RUN mkdir -p "$HOME/.local/bin" "$HOME/.go/bin" "$HOME/.keys"

# --------------------------------------------------------------------------------------

# Fish shell configuration files
COPY --chown=${user}:${group} config/fish/config.fish ./.config/fish/config.fish
COPY --chown=${user}:${group} config/fish/config-alias.fish ./.config/fish/config-alias.fish
COPY --chown=${user}:${group} config/starship.toml ./.config/starship.toml

# Z for the fish shell
RUN git clone https://github.com/jethrokuan/z.git && \
    mv ./z/conf.d/z.fish ./.config/fish/conf.d/z.fish && \
    mv ./z/functions/* ./.config/fish/functions && \
    rm -rf ./z

# Kubectl completions for fish
# Kubens completions for fish
# Kubectx completions for fish

# Bash shell specifics

# Kubectl completions for bash
RUN echo 'source <(kubectl completion bash)' >>/home/${user}/.bashrc && \
    echo 'alias k=kubectl' >>/home/${user}/.bashrc && \
    echo 'complete -F __start_kubectl k' >>/home/${user}/.bashrc

# Zsh shell specifics

# Programs that install on user profile

# Krew

# GCloud cli
ARG gcloud_ver=378.0.0
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    tar -xf google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --usage-reporting false -q && \
    rm -r ./google-cloud-sdk google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Pyenv
RUN curl https://pyenv.run | bash

# Poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -

# Kube-hunter
RUN pip install kube-hunter

# detect-secrets
RUN pip install detect-secrets

# Yubikey Manager
RUN pip install --user yubikey-manager

# Thef*ck
RUN pip install thefuck --user

# Install Jekyll
# RUN gem install jekyll bundler

ENV DEBIAN_FRONTEND=
ENV DEFAULT_SHELL="${shell}"
CMD $DEFAULT_SHELL
