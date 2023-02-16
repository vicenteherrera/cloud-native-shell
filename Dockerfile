ARG debian_ver=11
FROM debian:${debian_ver} as build

WORKDIR /install
COPY ./scripts/version.sh /usr/local/bin/version
RUN chmod a+rx /usr/local/bin/version

# Many of the installation commands are left as they would be run from a host machine
# so you can copy and paste on your main system, including sudo instruction where needed.

# Do not ask interactive questions while installing using apt or dpkg
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive apt-get update

# Instead of increasing the Debian image version, you may upgrade it,
# but the image size will be larger
# RUN apt-get -y upgrade

# Start with apt-utils so other installations can configure on the fly
RUN DEBIAN_FRONTEND=noninteractive DEBCONF_NOWARNINGS="yes" apt-get install -y --no-install-recommends apt-utils 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common \
        apt-transport-https ca-certificates lsb-release \
        gnupg gnupg2 curl wget unzip sudo \
        zsh nano jq procps \
        swig libpcsclite-dev
        
# Last line for Yubikey manager

# Programming

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
        build-essential direnv \
        python3-dev python3-pip python3-setuptools python3-venv \
        npm \
        ruby-full zlib1g-dev && \
    version python3 pip ruby npm | tee -a sbom.txt

# git, vim, bat, pv, parallel, tmux, screen
# nmap, ncat, netcat
# dnsutils (dig, nslookup, nsupdate), iputils (ping), net-tools (netstat) ,
# podman, buildah, skopeo, yamllint, shellcheck
# tor (torify), apache2-utils (ab)
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
        git vim bat pv parallel tmux screen \
        nmap ncat netcat dnsutils iputils-ping net-tools \
        conntrack \
        podman buildah skopeo yamllint shellcheck \
        tor \
        apache2-utils && \
    version git podman buildah skopeo yamllint shellcheck tor | tee -a sbom.txt && \
    ncat --version | tee -a sbom.txt && \
    nmap --version | grep "Nmap version" | tee -a sbom.txt && \
    bat --version | tee -a sbom.txt && \
    screen --version | tee -a sbom.txt && \
    tmux -V | tee -a sbom.txt && \
    parallel --version | head -n 1 | tee -a sbom.txt && \
    netstat --version | grep "net-tools" | tee -a sbom.txt && \
    ab -V | grep "This is ApacheBench" | xargs -I {} echo "ab: "{} | tee -a sbom.txt
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
    command curl -fsSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    command curl -fsSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -fsSL https://get.rvm.io | bash -s stable --ruby && \
    version ruby | tee -a sbom.txt

# Jekyll, Bundler, Krane
RUN gem install jekyll bundler krane && \
    version jekyll bundler krane | tee -a sbom.txt

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
RUN go_latest_ver=$(curl -fsSL https://go.dev/VERSION?m=text  | cut -c 3-) && \
    curl -fsSLo go.tar.gz https://go.dev/dl/go${go_ver}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && \
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
RUN curl -fsSL -o op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v${one_password_ver}/op_linux_amd64_v${one_password_ver}.zip && \
    unzip op.zip && sudo mv op /usr/local/bin/ && rm op.zip op.sig \
    version op | tee -a sbom.txt

## Install binaries from GitHub

# Requests to GitHub API to know which is the latest version are throttled, 
# if you run this several times you will get 403 errors so this is at beginning
# of the Dockerfile to cache in case of modifications to it

COPY ./scripts/gh_install.sh /usr/local/bin/gh_install
ARG GHTOKEN=""

# heuristic

## Several tools in a single RUN or we will run out of possible layers

RUN REPO="stern/stern"                   gh_install &&\
    REPO="mikefarah/yq"                  gh_install &&\
    REPO="roboll/helmfile"               gh_install &&\
    REPO="andreazorzetto/yh"             gh_install &&\
    REPO="tj/mmake"                      gh_install &&\
    REPO="controlplaneio/badrobot"       gh_install &&\
    REPO="ryane/kfilt"                   gh_install &&\
    REPO="ahmetb/kubectx"                gh_install &&\
    REPO="stackrox/kube-linter"          gh_install &&\
    REPO="controlplaneio/kubesec"        gh_install &&\
    REPO="turbot/steampipe"              gh_install &&\
    REPO="stelligent/config-lint"        gh_install &&\
    REPO="open-policy-agent/conftest"    gh_install &&\
    REPO="fairwindsops/polaris"          gh_install &&\
    REPO="projectdiscovery/httpx"        gh_install &&\
    REPO="datreeio/datree"               gh_install &&\
    REPO="ryane/kfilt"                   gh_install

RUN REPO="gruntwork-io/terragrunt"       gh_install &&\
    REPO="wagoodman/dive"                gh_install &&\
    REPO="noahgorstein/jqp"              gh_install &&\
    REPO="hadolint/hadolint"             gh_install &&\
    REPO="opcr-io/policy"                gh_install &&\
    REPO="wils0ns/tfscan"                gh_install &&\
    REPO="liggitt/audit2rbac"            gh_install &&\
    REPO="instrumenta/kubeval"           gh_install &&\
    REPO="zegl/kube-score"               gh_install &&\
    REPO="Shopify/kubeaudit"             gh_install &&\
    REPO="aquasecurity/chain-bench"      gh_install &&\
    REPO="raesene/eathar"                gh_install &&\
    REPO="genuinetools/bane"             gh_install

RUN REPO="kubernetes/kops"               gh_install &&\
    REPO="weaveworks/eksctl"             gh_install &&\
    REPO="sigstore/cosign"               gh_install &&\
    REPO="projectcalico/calico"          gh_install &&\
    REPO="chainguard-dev/vex"            gh_install &&\
    REPO="GoogleContainerTools/skaffold" gh_install &&\
    REPO="tenable/terrascan"             gh_install

RUN REPO="google/osv-scanner"            gh_install &&\
    REPO="genuinetools/img"              gh_install &&\
    REPO="derailed/k9s"                  gh_install &&\
    REPO="kubeshark/kubeshark"

# compressed inside a directory

# mockgen
RUN REPO="golang/mock" ZFILE="mock_VERSION_linux_amd64.tar.gz" FILE="mock_VERSION_linux_amd64/mockgen" XFILE="mockgen" gh_install

# Minishift
RUN REPO="minishift/minishift" ZFILE="minishift-VERSION-linux-amd64.tgz" FILE="minishift-VERSION-linux-amd64/minishift" XFILE="minishift" gh_install

# k6
RUN REPO="grafana/k6" ZFILE="k6-vVERSION-linux-amd64.tar.gz" FILE="k6-vVERSION-linux-amd64/k6" XFILE="k6" gh_install

# golangci-lint
RUN REPO="golangci/golangci-lint" ZFILE="golangci-lint-VERSION-linux-amd64.tar.gz" FILE="golangci-lint-VERSION-linux-amd64/golangci-lint" XFILE="golangci-lint" gh_install

# istioctl
RUN REPO="istio/istio" ZFILE="istio-VERSION-linux-amd64.tar.gz" FILE="istio-VERSION/bin/istioctl" XFILE="istioctl" gh_install

# promtool (Prometheus CLI)
RUN REPO="prometheus/prometheus" ZFILE="prometheus-VERSION.linux-amd64.tar.gz" FILE="prometheus-VERSION.linux-amd64/promtool" XFILE="promtool" gh_install

# amtool (Prometheus CLI)
RUN REPO="prometheus/alertmanager" ZFILE="alertmanager-VERSION.linux-amd64.tar.gz" FILE="alertmanager-VERSION.linux-amd64/amtool" XFILE="amtool" gh_install


# name on repo not binary to install

# crictl
RUN REPO="kubernetes-sigs/cri-tools" ZFILE="crictl-vVERSION-linux-amd64.tar.gz" FILE="crictl" gh_install

# cmctl
RUN REPO="cert-manager/cert-manager" ZFILE="cmctl-linux-amd64.tar.gz" FILE="cmctl" gh_install

# ah (Artifact Hub cli)
RUN REPO="artifacthub/hub" ZFILE="ah_VERSION_linux_amd64.tar.gz" FILE="ah" gh_install

# karmor (KubeArmor CLI)
RUN REPO="kubearmor/kubearmor-client" ZFILE="karmor_VERSION_linux_amd64.tar.gz" FILE="karmor" gh_install

# gator (GateKeeper CLI)
RUN REPO="open-policy-agent/gatekeeper" ZFILE="gator-vVERSION-linux-amd64.tar.gz" FILE="gator" gh_install

# doppler
RUN REPO="DopplerHQ/cli" ZFILE="doppler_VERSION_linux_amd64.tar.gz" FILE="doppler" gh_install


# not compressed but with version in binary name

# copper
RUN REPO="cloud66-oss/copper" ZFILE="linux_amd64_VERSION" FILE="linux_amd64_VERSION" XFILE="copper" gh_install


# download from source code and not from releases

# Docker-bench
RUN REPO="docker/docker-bench-security" FILE="docker-bench-security-VERSION" XFILE="docker-bench-security" gh_install

# KubiScan
RUN REPO="cyberark/KubiScan" FILE="KubiScan-VERSION" XFILE="kubiscan" gh_install

# testssl.sh
RUN REPO="drwetter/testssl.sh" FILE="testssl.sh-VERSION" XFILE="testssl" gh_install


# other

# JLess
RUN REPO="PaulJuliusMartinez/jless" ZFILE="jless-vVERSION-x86_64-unknown-linux-gnu.zip" FILE="jless" gh_install

# Kubens
RUN REPO="ahmetb/kubectx" ZFILE="kubens_vVERSION_linux_x86_64.tar.gz" FILE="kubens" gh_install

# pint
RUN REPO="cloudflare/pint" ZFILE="pint-VERSION-linux-amd64.tar.gz" FILE="pint-linux-amd64" XFILE="pint" gh_install

# kwctl (Kubewarden cli)
RUN REPO="kubewarden/kwctl" ZFILE="kwctl-linux-x86_64.zip" FILE="kwctl-linux-x86_64" XFILE="kwctl" gh_install

# Inlets ctl
RUN REPO="inlets/inletsctl" ZFILE="inletsctl.tgz" FILE="inletsctl" gh_install


# Custom installation from GitHub

# CloudQuery
# Their "latest" tag wrongfully points to a test install
RUN curl -fsSL -o cq.zip https://github.com/cloudquery/cloudquery/releases/download/cli%2Fv0.32.12/cloudquery_Linux_x86_64.zip && \
    unzip cq.zip && sudo mv cloudquery /usr/bin/cloudquery && rm CHANGELOG.md cq.zip && \
    version cloudquery | tee -a sbom.txt
# TODO: Check again in the future if they have fixed it, and instead use:
# RUN REPO="cloudquery/cloudquery" gh_install

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
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
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
RUN curl -fsSLo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    chmod +x minikube && sudo mv minikube /usr/local/bin/ && \
    version minikube | tee -a sbom.txt

# Kind
RUN curl -fsSLo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
    chmod +x ./kind && sudo mv ./kind /usr/local/bin/ && \
    version kind | tee -a sbom.txt

# OpenShift 4 cli
RUN curl -fsSLO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar -xvf oc.tar.gz && \
    chmod +x oc && sudo mv oc /usr/local/bin/ && \
    rm README.md kubectl oc.tar.gz && \
    version oc | tee -a sbom.txt


# Gitlab CLI
RUN GLREPO="gitlab-org/cli" && GLREPO_ID="gitlab-org%2Fcli" && \
    VERSION=$(curl -s https://gitlab.com/api/v4/projects/${GLREPO_ID}/releases/ | jq '.[]' | jq -r '.name' | head -1 | cut -c2-) && \
    curl -fsSL -o glab.tar.gz https://gitlab.com/${GLREPO}/-/releases/v${VERSION}/downloads/glab_${VERSION}_Linux_x86_64.tar.gz && \
    tar -xvf glab.tar.gz && \
    chmod a+x bin/glab && sudo mv bin/glab /usr/local/bin/ && \
    rm -r LICENSE README.md bin/ && \
    version glab | tee -a sbom.txt

# Kubectl-convert
RUN VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt) && \
    curl -fsSLO "https://dl.k8s.io/release/$VERSION/bin/linux/amd64/kubectl-convert" && \
    sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert && \
    rm kubectl-convert && \
    echo "kubectl-convert $VERSION" | tee -a sbom.txt

# StackRox cli
RUN curl -fsSLO https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl && \
    chmod +x roxctl && \
    sudo mv roxctl /usr/local/bin/ && \
    version roxctl | tee -a sbom.txt

## Install using installers

# AWS cli 2
RUN curl -fsSL -o aws.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && \
    unzip ./aws.zip && ./aws/install && \
    rm -r ./aws aws.zip && \
    version aws | tee -a sbom.txt

# # Sysdig
# RUN curl -s https://s3.amazonaws.com/download.draios.com/stable/install-sysdig | bash

# Grype
RUN curl -fsSL https://raw.githubusercontent.com/anchore/grype/main/install.sh \
        | sudo sh -s -- -b /usr/local/bin && \
    version grype | tee -a sbom.txt

# Syft
RUN curl -fsSL https://raw.githubusercontent.com/anchore/syft/main/install.sh \
        | sudo sh -s -- -b /usr/local/bin && \
    version syft | tee -a sbom.txt

# Helm 3
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
        | sudo -E bash - && \
    version helm | tee -a sbom.txt

# Docker Slim
RUN curl -fsSL https://raw.githubusercontent.com/slimtoolkit/slim/master/scripts/install-slim.sh \
        | sudo -E bash - && \
    version slim | tee -a sbom.txt

# Okteto cli
RUN curl -fsSL https://get.okteto.com \
        | sudo sh && \
    okteto version | tee -a sbom.txt

# Oracle Cloud cli
RUN curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh \
        | sudo bash -s --  --accept-all-defaults && \
    version /root/lib/oracle-cli/bin/oci | tee -a sbom.txt
# Installs to /root/lib/oracle-cli/bin

# Carvel tools
RUN curl -fsSL https://carvel.dev/install.sh \
        | sudo bash - && \
    version kwt kctrl kapp ytt kapp kbld imgpkg vendir | tee -a sbom.txt

# Starship prompt
RUN curl -fsSL https://starship.rs/install.sh \
        | sudo sh -s -- --yes && \
    version starship | tee -a sbom.txt

# Kubescape
RUN curl -fsSL https://raw.githubusercontent.com/armosec/kubescape/master/install.sh \
        | sudo /bin/bash && \
    version kubescape | tee -a sbom.txt

# act
RUN curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh \
        | sudo sh -s -- -b /usr/local/bin && \
    version act | tee -a sbom.txt
# It also requires docker to run

# Crossplane cli (kubectl plugin installer)
RUN curl -fsSL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh \
        | sh && \
    sudo mv kubectl-crossplane /usr/local/bin/ && \
    version kubectl-crossplane | tee -a sbom.txt

# NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_19.x \
        | bash - && \
    apt-get install -y nodejs

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

SHELL ["/usr/bin/fish", "-c"]

# fisher
RUN curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher && \
    fisher --version | tee -a sbom.txt

# bass
RUN fisher install edc/bass

# Z for the fish shell
RUN git clone https://github.com/jethrokuan/z.git && \
    mv ./z/conf.d/z.fish ./.config/fish/conf.d/z.fish && \
    mv ./z/functions/* ./.config/fish/functions && \
    rm -rf ./z

# Kubectl completions for fish
RUN fisher install evanlucas/fish-kubectl-completions

# Kubens completions for fish
RUN curl -fsSL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.fish --output ~/.config/fish/completions/kubens.fish

# Kubectx completions for fish
RUN curl -fsSL https://github.com/ahmetb/kubectx/blob/master/completion/kubectx.fish --output ~/.config/fish/completions/kubectx.fish

# helm completions for fish
RUN helm completion fish > ~/.config/fish/completions/helm.fish

# --------------------------------------------------------------------------------------

# Bash shell specifics

SHELL ["/bin/bash", "-c"]

# Kubectl completions for bash
RUN echo '# Created in Dockerfile' >>/home/${user}/.bashrc && \
    echo 'source <(kubectl completion bash)' >>/home/${user}/.bashrc && \
    echo 'alias k=kubectl' >>/home/${user}/.bashrc && \
    echo 'complete -F __start_kubectl k' >>/home/${user}/.bashrc

# Zsh shell specifics
# ...

# --------------------------------------------------------------------------------------

# Programs that install on user profile

## Krew related user installation

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

# Krew plugins: kubesec-scan, lineage, example, neat, score, popeye,
#               ktop, nsenter, doctor, who-can, rakkess (access-matrix)
RUN kubectl krew install \
    kubesec-scan lineage example neat score popeye ktop nsenter doctor who-can access-matrix && \
    echo "kubectl krew plugins:" | tee -a sbom.txt && \
    script -qc 'kubectl krew list' | tr -s ' ' | tee -a sbom.txt


## Helm related user installations

# Helm plugins: helm-diff
RUN helm plugin install https://github.com/databus23/helm-diff && \
    echo "helm plugins:" | tee -a sbom.txt && \
    helm plugin list | tee -a sbom.txt


## Go related user installations

# Ginkgo
RUN go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo && \
    version ginkgo | tee -a sbom.txt

# govulncheck
RUN go install golang.org/x/vuln/cmd/govulncheck@latest && \
    echo "govulncheck latest" | tee -a sbom.txt

# tfk8s
RUN VERSION=$(curl -fsSL https://api.github.com/repos/jrhouston/tfk8s/releases/latest | jq '.tag_name' | xargs) && \
    go install github.com/jrhouston/tfk8s@${VERSION}  && \
    echo "tfk8s $VERSION" | tee -a sbom.txt

# cfssl and related tools
RUN VERSION=$(curl -fsSL https://api.github.com/repos/cloudflare/cfssl/releases/latest | jq '.tag_name' | xargs) && \
    go install github.com/cloudflare/cfssl/cmd/...@${VERSION}  && \
    echo "cfssl $VERSION" | tee -a sbom.txt


## Python related user installations

# Pyenv
RUN curl -fsSL https://pyenv.run | bash && \
    version pyenv | tee -a sbom.txt

# Poetry
RUN curl -fsSL https://install.python-poetry.org | python3 - && \
    poetry --version | tee -a sbom.txt

# Pipx
RUN python3 -m pip install --user --no-cache pipx && \
    echo "pipx" $(pipx --version) | tee -a sbom.txt

# Pip: Kube-hunter, detect-secrets, Yubikey Manager, Thef*ck, , 
# docker-squash, illuminatio, vault-cli, cve-bin-tool, Cloud Custodian (c7n),
# robusta, in-toto, Anchore cli, swid-generator, ggshield
RUN SOFTWARE="kube-hunter detect-secrets yubikey-manager thefuck docker-squash \
        ansible paramiko illuminatio vault-cli cve-bin-tool c7n \
        robusta in-toto anchorecli swid-generator ggshield" && \
    pip install --user --no-cache $SOFTWARE && \
    pip list | grep -F "$(echo "$SOFTWARE" | tr -s ' ' | tr " " '\n')" - | tr -s ' ' \
        | tee -a sbom.txt

# Autocompletion and alias for Thef*ck on fish
RUN echo -e "\n#The f*ck\nthefuck --alias | source\nalias please fuck" >> $HOME/.config/fish/config.fish

# KubiScan and requirements
RUN pip install --user --no-cache kubernetes PrettyTable urllib3 && \
    python3 /usr/local/bin/kubiscan/KubiScan.py -h | egrep "KubiScan version" | xargs | tee -a sbom.txt

## Pipx installations
# We use pix as these require old incompatible version libraries

# sdc-cli (Sysdig)
RUN pipx install sdccli

# Checkov
RUN pipx install checkov

# Vexy
RUN pipx install vexy

# List pipx packages
RUN pipx list --short | tee -a sbom.txt 


## Node related user installations

# nvm
RUN VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq '.tag_name' | xargs | cut -c2-) && \
    curl -fsSLo- https://raw.githubusercontent.com/nvm-sh/nvm/v${VERSION}/install.sh | bash && \
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm | grep "Node Version Manager" | tee -a sbom.txt

# Configure nvm for fish
RUN echo -e "function nvm\n  bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv\nend" > $HOME/.config/fish/functions/nvm.fish
# Requires bass

# npm: Snyk, npx, yarn, bitwarden cli, artillery, npx
RUN npm install snyk yarn @bitwarden/cli bw npx artillery && \
    version snyk yarn npx | tee -a sbom.txt && \
    echo "bitwarden (bw) $(bw --version)" | tee -a sbom.txt && \
    artillery --version | grep 'Artillery Core' | tee -a sbom.txt && \
    npm cache clean -force


## Other installations

# psa-checker
RUN curl -fsSL https://raw.githubusercontent.com/vicenteherrera/psa-checker/main/install/install.sh | INSTALL_DIR="$(go env GOPATH)/bin" bash && \
    version psa-checker | tee -a sbom.txt

# Lazydocker
RUN curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh \
        | bash && \
    version lazydocker | tee -a sbom.txt


# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------

SHELL ["/bin/bash", "-c"]
ENV DEFAULT_SHELL="${shell}"
CMD ["$DEFAULT_SHELL"]
