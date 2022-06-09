ARG debian_ver=11
FROM debian:${debian_ver} as build

WORKDIR /install

# General
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y \
        apt-utils software-properties-common  apt-transport-https lsb-release \
        gnupg gnupg2 curl wget unzip sudo \
        zsh nano jq procps \
        swig libpcsclite-dev
# Last line for Yubikey manager
        
# git, vim, build, python, ruby, podman, prometheus, nmap, ncat, netcat
# dnsutils (dig, nslookup, nsupdate)
RUN apt-get -y install \
        git vim build-essential direnv bat \
        python3-dev python3-pip python3-setuptools python3-venv \
        npm \
        ruby-full zlib1g-dev \
        podman buildah skopeo yamllint shellcheck \
        prometheus prometheus-alertmanager \
        nmap ncat netcat dnsutils iputils-ping \
        conntrack
# conntrack is a Kubernetes 1.20.2 requirement

# Dotnet
ARG dotnet_ver=6.0
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-${dotnet_ver}
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

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
        | tee /usr/share/keyrings/microsoft-archive-keyring.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" \
        | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/azure-cli.list && \
    apt-get install azure-cli

# Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
        | gpg --dearmor | sudo tee /usr/share/keyrings/trivy-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
        | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/trivy.list && \
    apt-get install trivy

# Terraform, Vagrant
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/hashicorp.list && \
    apt-get install -y vagrant terraform
# Vagrant will require an additional virtualization hypervisor

# GitHub cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/github-cli.list && \ 
    apt install gh

# Tekton cli
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA && \
    echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main" \
        | tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list && \
    apt update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/tektoncd-ubuntu-cli.list && \
    apt install -y tektoncd-cli

# Fish shell
RUN echo 'deb [signed-by=/usr/share/keyrings/shells_fish_release_3.gpg] http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' \
    | tee /etc/apt/sources.list.d/shells:fish:release:3.list && \
    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key \
    | gpg --dearmor | tee /usr/share/keyrings/shells_fish_release_3.gpg > /dev/null && \
    apt-get update && \
    apt-get install -y fish

# Dive
ARG dive_ver=0.9.2
RUN wget https://github.com/wagoodman/dive/releases/download/v${dive_ver}/dive_${dive_ver}_linux_amd64.deb && \
    sudo apt install ./dive_${dive_ver}_linux_amd64.deb && \
    rm ./dive_${dive_ver}_linux_amd64.deb

# Clean APT cache
RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# This in fact doesn't decrease image size because cache is inside hidden layers

# Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh \
        | sh -s -- -b /usr/local/bin

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

# Tetragon
RUN wget https://github.com/cilium/tetragon/releases/download/tetragon-cli/tetragon-linux-amd64.tar.gz -O - |\
        tar xz && mv tetragon /usr/bin/tetragon

# Docker Slim
RUN curl -sL https://raw.githubusercontent.com/docker-slim/docker-slim/master/scripts/install-dockerslim.sh | sudo -E bash -

# Okteto cli
RUN curl https://get.okteto.com -sSfL | sh

# Oracle Cloud cli
RUN wget https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh && \
    chmod +x ./install.sh && \
    ./install.sh --accept-all-defaults

# Kubesec (binary)
RUN curl -sLo kubesec.tgz https://github.com/controlplaneio/kubesec/releases/latest/download/kubesec_linux_amd64.tar.gz && \
    tar -xvf kubesec.tgz && \
    chmod +x kubesec && \
    mv kubesec /usr/local/bin/ && rm kubesec.tgz

# Minikube
RUN curl -sLo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube && \
    mv minikube /usr/local/bin/

# Kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/

# Stern
RUN curl -sLo stern https://github.com/wercker/stern/releases/latest/download/stern_linux_amd64 && \
    chmod +x stern && \
    mv stern /usr/local/bin/

# Helmfile
RUN curl -sLo helmfile https://github.com/roboll/helmfile/releases/latest/download/helmfile_linux_amd64 && \
    chmod +x helmfile && \
    mv helmfile /usr/local/bin/

# Go
ARG go_ver=1.18
RUN curl -sLo go.tar.gz https://go.dev/dl/go${go_ver}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# pint (requires go)
RUN git clone https://github.com/cloudflare/pint.git && \
    cd pint && \
    export PATH="/usr/local/go/bin:$PATH" && \
    make && \
    sudo mv pint /usr/local/bin && \
    cd .. && rm -rf pint

# Carvel tools
RUN wget -O- https://carvel.dev/install.sh > install.sh && \
    sudo bash ./install.sh


# Audit2RBAC
RUN curl -sLo audit2rbac.tar.gz https://github.com/liggitt/audit2rbac/releases/latest/download/audit2rbac-linux-amd64.tar.gz && \
    tar -xvf audit2rbac.tar.gz && \
    chmod +x audit2rbac && \
    mv audit2rbac /usr/local/bin/ && rm audit2rbac.tar.gz
    
# yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64.tar.gz -O - |\
        tar xz && mv yq_linux_amd64 /usr/local/bin/yq

# Terrascan
RUN curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest \
        | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && \
        tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz && \
        install terrascan /usr/local/bin && rm terrascan

# kops
RUN curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest \
        | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 && \
    chmod +x kops && sudo mv kops /usr/local/bin/kops

# Minishift
# https://github.com/minishift/minishift/releases
ARG minishift_ver=1.34.3
RUN curl -sLo ms.tgz https://github.com/minishift/minishift/releases/download/v${minishift_ver}/minishift-${minishift_ver}-linux-amd64.tgz && \
    tar -xvf ms.tgz && \
    chmod +x minishift-${minishift_ver}-linux-amd64/minishift && \
    mv minishift-${minishift_ver}-linux-amd64/minishift /usr/local/bin/ && \
    rm -r minishift-${minishift_ver}-linux-amd64

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

# JLess
ARG jless_ver=0.8.0
RUN curl -sLo jless.zip https://github.com/PaulJuliusMartinez/jless/releases/download/v${jless_ver}/jless-v${jless_ver}-x86_64-unknown-linux-gnu.zip && \
    unzip jless.zip && \
    chmod +x jless && \
    mv jless /usr/local/bin/ && \
    rm jless.zip

# crictl
ARG crictl_ver=1.24.1
RUN wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v${crictl_ver}/crictl-v${crictl_ver}-linux-amd64.tar.gz -O - |\
        tar xz && mv crictl /usr/local/bin/

# helmfile
RUN curl -sLo helmfile https://github.com/roboll/helmfile/releases/latest/download/helmfile_linux_amd64 && \
    chmod +x helmfile && mv helmfile /usr/local/bin/

# tfscan
ARG tfscan_ver=0.6.3
RUN wget https://github.com/wils0ns/tfscan/releases/download/v${tfscan_ver}/tfscan_${tfscan_ver}_linux_amd64.tar.gz -O - |\
    tar xz && mv tfscan /usr/local/bin/

# ClamAV
ARG clamav_ver=0.105.0
RUN wget http://www.clamav.net/downloads/production/clamav-${clamav_ver}.linux.x86_64.deb && \
    sudo dpkg -i clamav-${clamav_ver}.linux.x86_64.deb && \
    rm clamav-${clamav_ver}.linux.x86_64.deb

# Starship prompt
RUN curl -sS https://starship.rs/install.sh >./install.sh && \
    sh ./install.sh --yes && \
    rm install.sh

# ------------------------------------------------------------------------------------

# Set user and group
ARG user=vicente
ARG group=developer
ARG uid=1000
ARG gid=1000

ARG shell=/usr/bin/fish

RUN groupadd -g ${gid} ${group} && \
    useradd -u ${uid} -g ${group} -s ${shell} -m ${user} && \
    usermod -aG sudo ${user} && \
    usermod -aG docker ${user} && newgrp docker

# rvm (Ruby Version Manager)
# Needs sudo and installs on user, so we do it before setting password
RUN PATH="$HOME/.gem/bin:$PATH" && \
    command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby

RUN mkdir -p \
        /home/${user}/.config/fish/completions \
        /home/${user}/.config/fish/conf.d \
        /home/${user}/.config/fish/functions \
        /home/${user}/.gem/bin \
        /home/${user}/.local/bin \
        /home/${user}/.go/bin \
        /home/${user}/.keys && \
    chown -R ${user}:${group} /home/${user}

# Switch to user
USER ${uid}:${gid}
WORKDIR /home/${user}

# Tell image to use bash shell so new paths take effect
SHELL ["/bin/bash", "-c"]
# Warning, 'bash' is not completely POSIX as default 'sh' is

# Paths for local bins
ENV PATH="/usr/local/go/bin:$PATH"
ENV PATH="/home/${user}/.local/bin:$PATH" 
ENV GEM_PATH="/home/${user}/.gem/bin"
ENV GEM_HOME="/home/${user}/.gem"
ENV PATH="/home/${user}/.gem/bin:$PATH"
ENV GOPATH="/home/${user}/.go/"
ENV PATH="/home/${user}/.go/bin:$PATH"
ENV PATH="/home/${user}/.pyenv/bin:$PATH"
ENV PATH="/home/${user}/node_modules/.bin:$PATH"

# Fish shell configuration files
COPY --chown=${user}:${group} config/fish/config.fish ./.config/fish/config.fish
COPY --chown=${user}:${group} config/fish/config-alias.fish ./.config/fish/config-alias.fish
COPY --chown=${user}:${group} config/starship.toml ./.config/starship.toml

# --------------------------------------------------------------------------------------

# Fish shell specifics

# Z for the fish shell
RUN git clone https://github.com/jethrokuan/z.git && \
    mv ./z/conf.d/z.fish ./.config/fish/conf.d/z.fish && \
    mv ./z/functions/* ./.config/fish/functions && \
    rm -rf ./z

# Kubectl completions for fish
# Kubens completions for fish
# Kubectx completions for fish
# ...

# Bash shell specifics

# Kubectl completions for bash
RUN echo '# Created in Dockerfile' >>/home/${user}/.bashrc && \
    echo 'source <(kubectl completion bash)' >>/home/${user}/.bashrc && \
    echo 'alias k=kubectl' >>/home/${user}/.bashrc && \
    echo 'complete -F __start_kubectl k' >>/home/${user}/.bashrc

# Zsh shell specifics
# ...

# --------------------------------------------------------------------------------------

# Programs that install on user profile

# Krew
RUN ( \
    set -x; cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew \
    )
ENV PATH="/home/${user}/.krew/bin:$PATH"

# Kubesec (Krew plugin)
RUN kubectl krew install kubesec-scan

# GCloud cli
ARG gcloud_ver=378.0.0
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    tar -xf google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --usage-reporting false -q && \
    rm -r ./google-cloud-sdk google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz

# golangci-lint
ARG golangci_lint_ver=1.46.2
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v${golangci_lint_ver}

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Pyenv
RUN curl https://pyenv.run | bash

# Poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -

# Pipx
RUN python3 -m pip install --user pipx

# Jekyll, Bundler
RUN gem install jekyll bundler
# This takes long to install, you may want to skip it

# tfk8s
RUN go install github.com/jrhouston/tfk8s@latest 

# kubelinter
RUN go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest

# Kube-hunter, detect-secrets, Yubikey Manager, Thef*ck, sdc-cli (Sysdig), robusta, 
# docker-squash, checkov, illuminatio, vault-cli
RUN pip install --user --no-cache \
    kube-hunter \
    detect-secrets \ 
    yubikey-manager \
    thefuck \
    docker-squash \
    ansible paramiko \
    illuminatio \
    vault-cli

# Robusta
# pipx because it requires old packages incompatible with previous installations
ARG robusta_minver=0.9.11
RUN pipx install "robusta-cli>=${robusta_minver}"

# Sysdig cli
# We specify minimum versions to avoid downloading full history of binaries
ARG sdccli_minver=0.7.14
RUN pipx install "sdccli>=${sdccli_minver}"

# Checkov
ARG checkov_minver=2.0.1184
RUN pipx install "checkov>=${checkov_minver}"

# Snyk
RUN npm install snyk

# --------------------------------------------------------------------------------------


# Squash all layers in a single one
FROM scratch
COPY --from=build / /

RUN sudo apt clean && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /install

ARG user=vicente
ARG uid=1000
ARG gid=1000
ARG pass=changeme
ARG shell=/usr/bin/fish

RUN echo "${user}:${pass}" | chpasswd
USER ${uid}:${gid}
WORKDIR /home/${user}

ENV PATH="/usr/local/go/bin:$PATH"
ENV PATH="/home/${user}/.local/bin:$PATH" 
ENV GEM_PATH="/home/${user}/.gem/bin"
ENV GEM_HOME="/home/${user}/.gem"
ENV PATH="/home/${user}/.gem/bin:$PATH"
ENV GOPATH="/home/${user}/.go/"
ENV PATH="/home/${user}/.go/bin:$PATH"
ENV PATH="/home/${user}/.pyenv/bin:$PATH"
ENV PATH="/home/${user}/node_modules/.bin:$PATH"

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=
ENV DEFAULT_SHELL="${shell}"
CMD $DEFAULT_SHELL
