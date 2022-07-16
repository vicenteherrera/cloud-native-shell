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

## Install using custom apt sources

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
RUN dive_ver=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | jq ".tag_name" | xargs | cut -c2-) && \
    wget https://github.com/wagoodman/dive/releases/download/v${dive_ver}/dive_${dive_ver}_linux_amd64.deb && \
    sudo apt install ./dive_${dive_ver}_linux_amd64.deb && \
    rm ./dive_${dive_ver}_linux_amd64.deb

## Go and go required global installation

# Go
ARG go_ver=1.18
RUN go_latest_ver=$(curl -s https://golang.org/VERSION?m=text) && \
    curl -sLo go.tar.gz https://go.dev/dl/go${go_ver}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# pint (requires go)
RUN git clone https://github.com/cloudflare/pint.git && \
    cd pint && \
    export PATH="/usr/local/go/bin:$PATH" && \
    make && \
    sudo mv pint /usr/local/bin && \
    cd .. && rm -rf pint

## Installed binaries from GitHub

COPY ./gh_install.sh .

# Kubectx, Kubens
RUN REPO="ahmetb/kubectx" ZFILE="kubectx_vVERSION_linux_x86_64.tar.gz" FILE="kubectx" ./gh_install.sh
RUN REPO="ahmetb/kubectx" ZFILE="kubens_vVERSION_linux_x86_64.tar.gz" FILE="kubens" ./gh_install.sh

# eksctl
RUN REPO="weaveworks/eksctl" ZFILE="eksctl_$(uname -s)_amd64.tar.gz" FILE="eksctl" ./gh_install.sh

# Kubesec (binary)
RUN REPO="controlplaneio/kubesec" ZFILE="kubesec_linux_amd64.tar.gz" FILE="kubesec" ./gh_install.sh

# Stern
RUN REPO="wercker/stern" ZFILE="stern_linux_amd64" XFILE="stern" ./gh_install.sh

# helmfile
RUN REPO="roboll/helmfile" ZFILE="helmfile_linux_amd64" XFILE="helmfile" ./gh_install.sh

# Audit2RBAC
RUN REPO="liggitt/audit2rbac" ZFILE="audit2rbac-linux-amd64.tar.gz" FILE="audit2rbac" ./gh_install.sh

# yq
RUN REPO="mikefarah/yq" ZFILE="yq_linux_amd64.tar.gz" FILE="yq_linux_amd64" XFILE="yq" ./gh_install.sh

# Terrascan
RUN REPO="tenable/terrascan" ZFILE="terrascan_VERSION_Linux_x86_64.tar.gz" FILE="terrascan" ./gh_install.sh

# kops
RUN REPO="kubernetes/kops" ZFILE="kops-linux-amd64" XFILE="kops" ./gh_install.sh

# Minishift
RUN REPO="minishift/minishift" ZFILE="minishift-VERSION-linux-amd64.tgz" FILE="minishift-VERSION-linux-amd64/minishift" XFILE="minishift" ./gh_install.sh

# KubeAudit
RUN REPO="Shopify/kubeaudit" ZFILE="kubeaudit_VERSION_linux_amd64.tar.gz" FILE="kubeaudit" ./gh_install.sh

# JLess
RUN REPO="PaulJuliusMartinez/jless" ZFILE="jless-vVERSION-x86_64-unknown-linux-gnu.zip" FILE="jless" ./gh_install.sh

# crictl
RUN REPO="kubernetes-sigs/cri-tools" ZFILE="crictl-vVERSION-linux-amd64.tar.gz" FILE="crictl" ./gh_install.sh

# tfscan
RUN REPO="wils0ns/tfscan" ZFILE="tfscan_VERSION_linux_amd64.tar.gz" FILE="tfscan" ./gh_install.sh

# chain-bench
RUN REPO="aquasecurity/chain-bench" ZFILE="chain-bench_VERSION_Linux_64bit.tar.gz" FILE="chain-bench" ./gh_install.sh

# cmctl
RUN REPO="cert-manager/cert-manager" OS=$(go env GOOS) ARCH=$(go env GOARCH) ZFILE="cmctl-$OS-$ARCH.tar.gz" FILE="cmctl" ./gh_install.sh

# polaris
RUN REPO="fairwindsops/polaris" ZFILE="polaris_linux_amd64.tar.gz" FILE="polaris" ./gh_install.sh

# kube-score
RUN REPO="zegl/kube-score" ZFILE="kube-score_VERSION_linux_amd64.tar.gz" FILE="kube-score" ./gh_install.sh

# kwctl (Kubewarden cli)
RUN REPO="kubewarden/kwctl" ZFILE="kwctl-linux-x86_64.zip" FILE="kwctl-linux-x86_64" XFILE="kwctl" ./gh_install.sh

# KubiScan
RUN REPO="cyberark/KubiScan" ZFILE="source.code.zip" FILE="KubiScan-master" XFILE="kubiscan" ./gh_install.sh
# Will additional require install: pip install --user --no-cache kubernetes PrettyTable urllib3

## Custom origin binaries

# Minikube
RUN curl -sLo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube && mv minikube /usr/local/bin/

# Kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
    chmod +x ./kind && mv ./kind /usr/local/bin/

# OpenShift 4 cli
RUN curl -sLo oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar -xvf oc.tar.gz && \
    chmod +x oc && mv oc /usr/local/bin/ && \
    rm README.md kubectl oc.tar.gz

# Kubectl-convert
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert" && \
    sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert && \
    rm kubectl-convert

# Tetragon
RUN wget https://github.com/cilium/tetragon/releases/download/tetragon-cli/tetragon-linux-amd64.tar.gz -O - |\
        tar xz && mv tetragon /usr/bin/tetragon

# StackRox cli
RUN curl -O https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl && \
    chmod +x roxctl && \
    mv roxctl /usr/local/bin/

# testssl.sh
RUN wget https://testssl.sh/testssl.sh && chmod +x testssl.sh && mv testssl.sh /usr/local/bin

## Installers

# Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh \
        | sh -s -- -b /usr/local/bin

# Syft
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \
        | sh -s -- -b /usr/local/bin

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

# Docker Slim
RUN curl -sL https://raw.githubusercontent.com/docker-slim/docker-slim/master/scripts/install-dockerslim.sh | sudo -E bash -

# Okteto cli
RUN curl https://get.okteto.com -sSfL | sh

# Oracle Cloud cli
RUN wget https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh && \
    chmod +x ./install.sh && \
    ./install.sh --accept-all-defaults

# Carvel tools
RUN wget -O- https://carvel.dev/install.sh > install.sh && sudo bash ./install.sh

# Crossplane cli
RUN curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh

# act
RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Starship prompt
RUN curl -sS https://starship.rs/install.sh >./install.sh && \
    sh ./install.sh --yes && \
    rm install.sh

## Fixed versioned

# 1Password
ARG one_password_ver=2.0.0
RUN curl -sLo op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v${one_password_ver}/op_linux_amd64_v${one_password_ver}.zip && \
    unzip op.zip && mv op /usr/local/bin/ && rm op.zip op.sig

# ClamAV
ARG clamav_ver=0.105.0
RUN wget http://www.clamav.net/downloads/production/clamav-${clamav_ver}.linux.x86_64.deb && \
    sudo dpkg -i clamav-${clamav_ver}.linux.x86_64.deb && \
    rm clamav-${clamav_ver}.linux.x86_64.deb

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

RUN echo "${user}:${pass}" | chpasswd

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

# GCloud cli
ARG gcloud_ver=378.0.0
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    tar -xf google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --usage-reporting false -q && \
    rm -r ./google-cloud-sdk google-cloud-sdk-${gcloud_ver}-linux-x86_64.tar.gz

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

# Krew plugins: kube-scan, lineage, example, neat, score, popeye
#               example, ktop, nsenter, doctor
RUN kubectl krew install kubesec-scan lineage example neat score popeye \
        ktop nsenter doctor

# Krew plugin: Nodeshell
RUN kubectl krew index add kvaps https://github.com/kvaps/krew-index && \
    kubectl krew install kvaps/node-shell

# Helm plugins: helm-diff
RUN helm plugin install https://github.com/databus23/helm-diff

# golangci-lint
RUN golangci_lint_ver=$(curl -s https://api.github.com/repos/golangci/golangci-lint/releases/latest | jq ".tag_name" | xargs | cut -c2- ) && \
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v${golangci_lint_ver}

# Ginkgo
RUN go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo

# Gomock
RUN go install github.com/golang/mock/mockgen@latest

# tfk8s
RUN go install github.com/jrhouston/tfk8s@latest 

# kubelinter
RUN go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Pyenv
RUN curl https://pyenv.run | bash

# Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Pipx
RUN python3 -m pip install --user pipx

# Jekyll, Bundler
RUN gem install jekyll bundler
# This takes long to install, you may want to skip it

# Kube-hunter, detect-secrets, Yubikey Manager, Thef*ck, sdc-cli (Sysdig), robusta, 
# docker-squash, checkov, illuminatio, vault-cli, cve-bin-tool
RUN pip install --user --no-cache \
    kube-hunter \
    detect-secrets \ 
    yubikey-manager \
    thefuck \
    docker-squash \
    ansible paramiko \
    illuminatio \
    vault-cli \
    cve-bin-tool

# For KubiScan
RUN pip install --user --no-cache kubernetes PrettyTable urllib3

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

# Snyk, npx, yarn
RUN npm install snyk npx yarn

# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=
ENV DEFAULT_SHELL="${shell}"
CMD $DEFAULT_SHELL
