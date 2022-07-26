ARG debian_ver=11
FROM debian:${debian_ver} as build

WORKDIR /install
COPY ./scripts/version.sh /usr/local/bin/version

# Many of the installation commands are left as they would be run from a host machine
# so you can copy and paste on your main system, including sudo instruction where needed.

# Do not ask interactive questions while installing using apt or dpkg
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update

# Instead of increasing the Debian image version, you may upgrade it,
# but the image size will be larger
# RUN apt-get -y upgrade

# Start with apt-utils so other installations can configure on the fly
RUN apt-get install -y apt-utils 
RUN apt-get install -y software-properties-common \
        apt-transport-https ca-certificates lsb-release \
        gnupg gnupg2 curl wget unzip sudo \
        zsh nano jq procps \
        swig libpcsclite-dev
        
# Last line for Yubikey manager
        
# git, vim, build, python, ruby, podman, prometheus, nmap, ncat, netcat
# dnsutils (dig, nslookup, nsupdate), iputils (ping), net-tools (netstat) ,
# python, npm, ruby
# podman, buildah, skopeo, yamllint, shellcheck
# tor, torify
RUN apt-get -y install \
        git vim build-essential direnv bat \
        nmap ncat netcat dnsutils iputils-ping net-tools \
        conntrack \
        python3-dev python3-pip python3-setuptools python3-venv \
        npm \
        ruby-full zlib1g-dev \
        podman buildah skopeo yamllint shellcheck \
        tor && \
    echo "npm" $(npm --version) | tee -a sbom.txt && \
    version python3 pip ruby podman buildah skopeo yamllint shellcheck tor | tee -a sbom.txt
# conntrack is a Kubernetes 1.20.2 requirement
# net-tools installs netstat that is a requirements of kube-hunter?

## Install software that is slow to install or doesn't change so much 
## to cache it on early layers

# rvm installation is greedy trying to create group rvm first which will cosume GID 1000
# so we start creating our first desired group
ARG group=developer
ARG gid=1000
RUN groupadd -g ${gid} ${group}

# rvm (Ruby Version Manager)
# Takes a long time to compile Ruby binary, so we do it at the beginning
# to cache and fasten further modifications of the Dockerfile
RUN PATH="$HOME/.gem/bin:$PATH" && \
    command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby && \
    version ruby | tee -a sbom.txt

# Jekyll, Bundler
RUN gem install jekyll bundler && \
    version jekyll bundler | tee -a sbom.txt

# Dotnet
ARG dotnet_ver=6.0
RUN curl -fsSLo packages-microsoft-prod.deb https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb && \
    sudo dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    sudo apt-get update && \
    sudo apt-get install -y dotnet-sdk-${dotnet_ver} && \
    version dotnet | tee -a sbom.txt
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Golang
ARG go_ver=1.18
RUN go_latest_ver=$(curl -s https://golang.org/VERSION?m=text) && \
    curl -sLo go.tar.gz https://go.dev/dl/go${go_ver}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz && \
    /usr/local/go/bin/go version | tee -a sbom.txt
ENV PATH="/usr/local/go/bin:$PATH"

## Fixed versioned

# ClamAV
ARG clamav_ver=0.105.0
RUN curl -fsSLo clamav.deb https://www.clamav.net/downloads/production/clamav-${clamav_ver}.linux.x86_64.deb && \
    sudo dpkg -i clamav.deb && \
    rm clamav.deb && \
    version clamav-config | tee -a sbom.txt
    
# 1Password
ARG one_password_ver=2.5.1
RUN curl -sSf -o op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v${one_password_ver}/op_linux_amd64_v${one_password_ver}.zip && \
    unzip op.zip && sudo mv op /usr/local/bin/ && rm op.zip op.sig \
    version op | tee -a sbom.txt

## Install binaries from GitHub

# Requests to GitHub API to know which is the latest version are throttled, 
# if you run this several times you will get 403 errors so this is at beginning
# of the Dockerfile to cache in case of modifications to it

COPY ./scripts/gh_install.sh /usr/local/bin/gh_install
ARG GHTOKEN=""

# Docker-bench
RUN REPO="docker/docker-bench-security" FILE="docker-bench-security-VERSION" XFILE="docker-bench-security" gh_install

# KubiScan
RUN REPO="cyberark/KubiScan" FILE="KubiScan-VERSION" XFILE="kubiscan" gh_install

# testssl.sh
RUN REPO="drwetter/testssl.sh" FILE="testssl.sh-VERSION" XFILE="testssl" gh_install

# Dive
RUN REPO="wagoodman/dive" ZFILE="dive_VERSION_linux_amd64.deb" gh_install

# Kubectx, Kubens
RUN REPO="ahmetb/kubectx" ZFILE="kubectx_vVERSION_linux_x86_64.tar.gz" FILE="kubectx" gh_install
RUN REPO="ahmetb/kubectx" ZFILE="kubens_vVERSION_linux_x86_64.tar.gz" FILE="kubens" gh_install

# eksctl
RUN REPO="weaveworks/eksctl" ZFILE="eksctl_$(uname -s)_amd64.tar.gz" FILE="eksctl" gh_install

# Kubesec (binary)
RUN REPO="controlplaneio/kubesec" ZFILE="kubesec_linux_amd64.tar.gz" FILE="kubesec" gh_install

# Stern
RUN REPO="wercker/stern" ZFILE="stern_linux_amd64" XFILE="stern" gh_install

# helmfile
RUN REPO="roboll/helmfile" ZFILE="helmfile_linux_amd64" XFILE="helmfile" gh_install

# Audit2RBAC
RUN REPO="liggitt/audit2rbac" ZFILE="audit2rbac-linux-amd64.tar.gz" FILE="audit2rbac" gh_install

# yq
RUN REPO="mikefarah/yq" ZFILE="yq_linux_amd64" FILE="yq_linux_amd64" XFILE="yq" gh_install

# Terrascan
RUN REPO="tenable/terrascan" ZFILE="terrascan_VERSION_Linux_x86_64.tar.gz" FILE="terrascan" gh_install

# kops
RUN REPO="kubernetes/kops" ZFILE="kops-linux-amd64" XFILE="kops" gh_install

# Minishift
RUN REPO="minishift/minishift" ZFILE="minishift-VERSION-linux-amd64.tgz" FILE="minishift-VERSION-linux-amd64/minishift" XFILE="minishift" gh_install

# KubeAudit
RUN REPO="Shopify/kubeaudit" ZFILE="kubeaudit_VERSION_linux_amd64.tar.gz" FILE="kubeaudit" gh_install

# JLess
RUN REPO="PaulJuliusMartinez/jless" ZFILE="jless-vVERSION-x86_64-unknown-linux-gnu.zip" FILE="jless" gh_install

# crictl
RUN REPO="kubernetes-sigs/cri-tools" ZFILE="crictl-vVERSION-linux-amd64.tar.gz" FILE="crictl" gh_install

# tfscan
RUN REPO="wils0ns/tfscan" ZFILE="tfscan_VERSION_linux_amd64.tar.gz" FILE="tfscan" gh_install

# chain-bench
RUN REPO="aquasecurity/chain-bench" ZFILE="chain-bench_VERSION_Linux_64bit.tar.gz" FILE="chain-bench" gh_install

# cmctl
RUN REPO="cert-manager/cert-manager" ZFILE="cmctl-linux-amd64.tar.gz" FILE="cmctl" gh_install

# polaris
RUN REPO="fairwindsops/polaris" ZFILE="polaris_linux_amd64.tar.gz" FILE="polaris" gh_install

# kube-score
RUN REPO="zegl/kube-score" ZFILE="kube-score_VERSION_linux_amd64.tar.gz" FILE="kube-score" gh_install

# kwctl (Kubewarden cli)
RUN REPO="kubewarden/kwctl" ZFILE="kwctl-linux-x86_64.zip" FILE="kwctl-linux-x86_64" XFILE="kwctl" gh_install

# CloudQuery
RUN REPO="cloudquery/cloudquery" ZFILE="cloudquery_Linux_x86_64.zip" FILE="cloudquery" gh_install

# Steampipe
RUN REPO="turbot/steampipe" ZFILE="steampipe_linux_amd64.tar.gz" FILE="steampipe" gh_install

# Cosign
RUN REPO="sigstore/cosign" ZFILE="cosign-linux-amd64" gh_install

# Kubeval
RUN REPO="instrumenta/kubeval" ZFILE="kubeval-linux-amd64.tar.gz" FILE="kubeval" gh_install

# Skaffold
RUN REPO="GoogleContainerTools/skaffold" ZFILE="skaffold-linux-amd64" XFILE="skaffold" gh_install

# promtool (Prometheus CLI)
RUN REPO="prometheus/prometheus" ZFILE="prometheus-VERSION.linux-amd64.tar.gz" FILE="prometheus-VERSION.linux-amd64/promtool" XFILE="promtool" gh_install

# amtool (Prometheus CLI)
RUN REPO="prometheus/alertmanager" ZFILE="alertmanager-VERSION.linux-amd64.tar.gz" FILE="alertmanager-VERSION.linux-amd64/amtool" XFILE="amtool" gh_install

# pint
RUN REPO="cloudflare/pint" ZFILE="pint-VERSION-linux-x86_64.tar.gz" FILE="pint-linux-amd64" XFILE="pint" gh_install

# kube-linter
RUN REPO="stackrox/kube-linter" ZFILE="kube-linter-linux.tar.gz" FILE="kube-linter" gh_install

# mmake
RUN REPO="tj/mmake" ZFILE="mmake_VERSION_linux_x86_64.tar.gz" FILE="mmake" gh_install

# Bad Robot
RUN REPO="controlplaneio/badrobot" ZFILE="badrobot_linux_amd64.tar.gz" FILE="badrobot" gh_install

# Hadolint
RUN REPO="hadolint/hadolint" ZFILE="hadolint-Linux-x86_64" XFILE="hadolint" gh_install

# mockgen
RUN REPO="golang/mock" ZFILE="mock_VERSION_linux_amd64.tar.gz" FILE="mock_VERSION_linux_amd64/mockgen" XFILE="mockgen" gh_install

# golangci-lint
RUN REPO="golangci/golangci-lint" ZFILE="golangci-lint-VERSION-linux-amd64.deb" gh_install

# Custom installation from GitHub

# Tetragon
RUN curl -fsSL https://github.com/cilium/tetragon/releases/download/tetragon-cli/tetragon-linux-amd64.tar.gz \
        | tar xz && sudo mv tetragon /usr/bin/tetragon && \
   echo "tetragon (initial release)" | tee -a sbom.txt

## Install using custom apt sources

# These includes optiona chmod of keyring file in case you use this on your host computer and
# your system hardening prevents newly created files to have "read all" that is needed on gpg keys.

# Fish shell
RUN curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key \
        | gpg --dearmor | sudo tee /usr/share/keyrings/shells_fish_release_3.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/shells_fish_release_3.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/shells_fish_release_3.gpg] http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' \
        | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list > /dev/null && \
    sudo apt-get update && \
    sudo apt-get install -y fish && \
    version fish | tee -a sbom.txt

# Kubectl
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/kubernetes-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
        | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get install -y kubectl && \
    echo "kubectl" $(kubectl version --short --client 2>/dev/null) | tee -a sbom.txt

# Docker (in Docker)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor | sudo tee /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/docker.list && \
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io  && \
    version docker | tee -a sbom.txt

# Azure cli
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/microsoft-archive-keyring.gpg && \        
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/azure-cli.list && \
    sudo apt-get install -y azure-cli && \
    version az | tee -a sbom.txt

# Trivy
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
        | gpg --dearmor | sudo tee /usr/share/keyrings/trivy-archive-keyring.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/trivy-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
        | sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/trivy.list && \
    sudo apt-get install -y trivy && \
    version trivy | tee -a sbom.txt

# Terraform, Vagrant
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/hashicorp.list && \
    sudo apt-get install -y vagrant terraform && \
    version vagrant | tee -a sbom.txt
# Vagrant will require an additional virtualization hypervisor

# GitHub cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    sudo chmod a+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/github-cli.list && \ 
    sudo apt-get install -y gh && \
    version gh | tee -a sbom.txt

# GCloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | tee /usr/share/keyrings/cloud.google.gpg > /dev/null && \
    sudo chmod a+r /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
        | tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get install -y google-cloud-sdk && \
    version gcloud | tee -a sbom.txt

# Tekton cli
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA && \
    echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main" \
        | sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list > /dev/null && \
    sudo apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/tektoncd-ubuntu-cli.list && \
    sudo apt-get install -y tektoncd-cli && \
    version tkn | tee -a sbom.txt

## Install from custom origin binaries

# Minikube
RUN curl -sLo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube && sudo mv minikube /usr/local/bin/ && \
    version minikube | tee -a sbom.txt

# Kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
    chmod +x ./kind && sudo mv ./kind /usr/local/bin/ && \
    version kind | tee -a sbom.txt

# OpenShift 4 cli
RUN curl -sLO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar -xvf oc.tar.gz && \
    chmod +x oc && sudo mv oc /usr/local/bin/ && \
    rm README.md kubectl oc.tar.gz && \
    version oc | tee -a sbom.txt

# Kubectl-convert
RUN curl -sLO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert" && \
    sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert && \
    rm kubectl-convert && \
    version kubectl-convert | tee -a sbom.txt

# StackRox cli
RUN curl -sLO https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl && \
    chmod +x roxctl && \
    sudo mv roxctl /usr/local/bin/ && \
    version roxctl | tee -a sbom.txt

## Install using installers

# AWS cli 2
RUN curl -sSfL -o aws.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && \
    unzip ./aws.zip && ./aws/install && \
    rm -r ./aws aws.zip && \
    version aws | tee -a sbom.txt

# # Sysdig
# RUN curl -s https://s3.amazonaws.com/download.draios.com/stable/install-sysdig | bash

# Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh \
        | sudo sh -s -- -b /usr/local/bin && \
    version grype | tee -a sbom.txt

# Syft
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \
        | sudo sh -s -- -b /usr/local/bin && \
    version syft | tee -a sbom.txt

# Helm 3
RUN curl -sSfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
        | sudo -E bash - && \
    version helm | tee -a sbom.txt

# Docker Slim
RUN curl -sSfL https://raw.githubusercontent.com/docker-slim/docker-slim/master/scripts/install-dockerslim.sh \
        | sudo -E bash - && \
    version docker-slim | tee -a sbom.txt

# Okteto cli
RUN curl -sSfL https://get.okteto.com -sSfL \
        | sudo sh && \
    okteto version | tee -a sbom.txt

# Oracle Cloud cli
RUN curl -sSfL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh \
        | sudo bash -s --  --accept-all-defaults && \
    version /root/lib/oracle-cli/bin/oci | tee -a sbom.txt
# Installs to /root/lib/oracle-cli/bin

# Carvel tools
RUN curl -sSfL https://carvel.dev/install.sh | sudo bash - && \
    version kapp ytt kapp kbld imgpkg vendir | tee -a sbom.txt

# Starship prompt
RUN curl -sSfL https://starship.rs/install.sh \
        | sudo sh -s -- --yes && \
    version starship | tee -a sbom.txt

# Kubescape
RUN curl -sSfL https://raw.githubusercontent.com/armosec/kubescape/master/install.sh \
        | sudo /bin/bash && \
    version kubescape | tee -a sbom.txt

# act
RUN curl -sSfL https://raw.githubusercontent.com/nektos/act/master/install.sh \
        | sudo sh -s -- -b /usr/local/bin && \
    version act | tee -a sbom.txt
# It also requires docker to run

# Crossplane cli (kubectl plugin installer)
RUN curl -sSfL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh && \
    sudo mv kubectl-crossplane /usr/local/bin/ && \
    version kubectl-crossplane | tee -a sbom.txt

# ------------------------------------------------------------------------------------

# Set user and group
ARG user=vicente
ARG uid=1000
ARG pass=changeme
ARG shell=/usr/bin/fish

RUN useradd -u ${uid} -g ${group} -s ${shell} -m ${user} && \
    usermod -aG sudo ${user}

RUN mkdir -p \
        /home/${user}/.config/fish/completions \
        /home/${user}/.config/fish/conf.d \
        /home/${user}/.config/fish/functions \
        /home/${user}/.gem/bin \
        /home/${user}/.local/bin \
        /home/${user}/.go/bin \
        /home/${user}/.keys && \
    chown -R ${user}:${group} /home/${user}

RUN mv /install/sbom.txt /home/${user}/sbom.txt && \
    chown ${user}:${group} /home/${user}/sbom.txt

RUN echo "${user}:${pass}" | chpasswd

# Add user to RVM group for Ruby Version Manager
RUN sudo usermod -aG rvm ${user}

# Only run if you want to run docker without using sudo
RUN sudo usermod -aG docker ${user} && sudo -H -u ${user} newgrp docker

# Restore dialog apt frontend
RUN echo 'debconf debconf/frontend select Dialog' | sudo debconf-set-selections

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

# Other config files
COPY --chown=${user}:${group} .vimrc ./.vimrc

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
# helm completions
# pipx completions
# ...

# Bash shell specifics

# Kubectl completions for bash
RUN echo '# Created in Dockerfile' >>/home/${user}/.bashrc && \
    echo 'source <(kubectl completion bash)' >>/home/${user}/.bashrc && \
    echo 'alias k=kubectl' >>/home/${user}/.bashrc && \
    echo 'complete -F __start_kubectl k' >>/home/${user}/.bashrc

# Zsh shell specifics
# ohmyzsh
# ...

# --------------------------------------------------------------------------------------

# Programs that install on user profile

# Miniconda
RUN curl -sSfLo install.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x install.sh && ./install.sh -b -p $HOME/miniconda && rm ./install.sh \
    version conda | tee -a sbom.txt 

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

# Krew plugin: Nodeshell
RUN kubectl krew index add kvaps https://github.com/kvaps/krew-index && \
    kubectl krew install kvaps/node-shell

# Krew plugins: kube-scan, lineage, example, neat, score, popeye
#               example, ktop, nsenter, doctor
RUN kubectl krew install \
    kubesec-scan lineage example neat score popeye ktop nsenter doctor && \
    echo "kubectl krew plugins:" | tee -a sbom.txt && \
    script -qc 'kubectl krew list' | tr -s ' ' | tee -a sbom.txt

# Helm plugins: helm-diff
RUN helm plugin install https://github.com/databus23/helm-diff && \
    echo "helm plugins:" | tee -a sbom.txt && \
    helm plugin list | tee -a sbom.txt

# Ginkgo
RUN go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo && \
    version ginkgo | tee -a sbom.txt

# tfk8s
RUN go install github.com/jrhouston/tfk8s@latest  && \
    version tfk8s | tee -a sbom.txt

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    version nvm | tee -a sbom.txt

# Pyenv
RUN curl https://pyenv.run | bash && \
    version pyenv | tee -a sbom.txt

# Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    version poetry | tee -a sbom.txt

# Pipx
RUN python3 -m pip install --user pipx && \
    echo "pipx" $(pipx --version) | tee -a sbom.txt

# Snyk, npx, yarn
RUN SOFTWARE="snyk npx yarn" && \ 
    npm install $SOFTWARE && \
    version $SOFTWARE | tee -a sbom.txt

# Pip: Kube-hunter, detect-secrets, Yubikey Manager, Thef*ck, sdc-cli (Sysdig), 
# docker-squash, checkov, illuminatio, vault-cli, cve-bin-tool, Cloud Custodian
# robusta, in-toto, vexy
RUN SOFTWARE="kube-hunter detect-secrets yubikey-manager thefuck docker-squash \
        ansible paramiko illuminatio vault-cli cve-bin-tool c7n \
        robusta in-toto" && \
    pip install --user --no-cache $SOFTWARE && \
    pip list | grep -F "$(echo "$SOFTWARE" | tr -s ' ' | tr " " '\n')" - | tr -s ' ' \
        | tee -a sbom.txt

# For KubiScan
RUN pip install --user --no-cache kubernetes PrettyTable urllib3 && \
    python3 /usr/local/bin/kubiscan/KubiScan.py --version | tee -a sbom.txt

## Pipx installations
# We use pix as these require old incompatible version libraries

# Sysdig cli
RUN pipx install sdccli

# Checkov
RUN pipx install checkov

# Vexy
RUN pipx install vexy

# List pipx packages
RUN pipx list --short | tee -a sbom.txt 

# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------

SHELL ["/bin/bash", "-c"]
ENV DEFAULT_SHELL="${shell}"
CMD ["$DEFAULT_SHELL"]
