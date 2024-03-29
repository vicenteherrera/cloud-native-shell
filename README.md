# Cloud Native Shell

A cloud-native "Tardis" container image... "it's bigger in the inside".

A command line environment configured with many tools for cloud-native development and security. The container is 10+ Gb in size.

Default shell is [fish](https://fishshell.com/) with [starship](https://starship.rs/) prompt requiring a [nerd font](https://www.nerdfonts.com/) to correctly see prompt glyphs.
See `makefile` for more configuration options while building or running the image.

Aim is to include as many cloud-native tools as possible, specially if related with security. 
But the goal isn't to fill it just with plain security tools (you already have Kali Linux for that).

## Examples

Without having to clone this repo:

```bash
# Run without sharing any local directory
docker run --rm -it --hostname tardis --name cloud-native-shell \
  quay.io/vicenteherrera/cloud-native-shell
```

After cloning this repo:

```bash
# Build using currently active user name, id and default password.
# It can take up to 30 minutes, and while installing binaries from GitHub, 
# it may throttle connection and throw 403 errors. 
# Just wait and rerun picking at the last correct layer.
make build

# Run using Fish shell and sharing credential dirs (.ssh, .aws, .kube, ...), 
# and current dir as ./data
make run

# Run same but with bash shell
make run RUN_SHELL=/bin/bash
```

## Notes about users

* If you build the container yourself with the makefile, it will use your current username, userid, and a "changeme" sudo password. See makefile for more info.
* You can use docker-in-docker from within the container using "sudo" before executing docker related commands.

## Software included

* [Debian 11 "Bullseye"](https://www.debian.org/News/2021/20210814)
* Containers and VM
  * [Docker](https://docs.docker.com/engine/reference/commandline/cli/) (includes 'compose' command)
  * [Podman](https://podman.io/): run container images without sudo
  * [Buildah](https://buildah.io/): build container images without sudo
  * [img](https://github.com/genuinetools/img): standalone, daemon-less, unprivileged Dockerfile and OCI compatible container image builder
  * [Skopeo](https://github.com/containers/skopeo): move container images between different types of container storages
  * [Vagrant](https://www.vagrantup.com/): virtual machines manager
  * [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-with-pip), Paramiko
  * [lazydocker](https://github.com/jesseduffield/lazydocker): a simple terminal UI for both docker and docker-compose
  * [slim](https://github.com/slimtoolkit/slim): reduce footprint of container images
  * [docker-squash](https://github.com/goldmann/docker-squash): squash layers of a container image reducing size
  * [dive](https://github.com/wagoodman/dive): explore container image and layers
  * [act](https://github.com/nektos/act): test GitHub actions locally
  * [Docker bench](https://github.com/docker/docker-bench-security): checks for best-practices deploying Docker based on the CIS Benchmark
  * [Hadolint](https://github.com/hadolint/hadolint): dockerfile linter
* Kubernetes
  * [Kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/), [kubectl-convert](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-convert-plugin), aliases
  * [Krane](https://github.com/Shopify/krane): like kubectl, but watches changes, predeploys specific resources, creates secrets, and provides additional information of deployment results
  * [kfilt](https://github.com/ryane/kfilt): filter specific resources from a stream of Kubernetes YAML manifests
  * [Krew](https://krew.sigs.k8s.io/): plugin system for Kubectl
    * [kubectl node-shell](https://github.com/kvaps/kubectl-node-shell): start a root shell in a node    
    * [kubectl example](https://github.com/seredot/kubectl-example): resource example YAMLs
    * [kubectl neat](https://github.com/itaysk/kubectl-neat): remove clutter from manifests
    * [kubectl ktop](https://github.com/vladimirvivien/ktop): top like tool for Kubernetes
    * [kubectl nsenter](https://github.com/towolf/kubectl-nsenter): SSH onto node and spawn an nsenter shell into a pod
    * [kubectl who-can](https://github.com/aquasecurity/kubectl-who-can): shows which subjects have RBAC permissions to VERB
    * [kubectl access-matrix (rakkess)](https://github.com/corneliusweig/rakkess): show an access matrix for server resources
  * Local cluster
    * [Minikube](https://minikube.sigs.k8s.io/docs/start/): deploy a local Kubernetes cluster using different hypervisor drivers
    * [Kind](https://kind.sigs.k8s.io/): deploy a local Kubernetes cluster using Docker
    * [Minishift](https://github.com/minishift/minishift): deploy a local OpenShift cluster
  * [Kubectx, Kubens](https://github.com/ahmetb/kubectx): easely change Kubernetes config context and current namespace
  * [Helm](https://helm.sh/): manage apps in Kubernetes with deploy templates packaged as charts
    * [Helm diff plugin](https://github.com/databus23/helm-diff): plugin to preview what a helm upgrade would change
  * [Helmfile](https://github.com/roboll/helmfile): deploy several Helm charts at once
  * [Stern](https://github.com/stern/stern): tail multiple pod logs on Kubernetes
  * [k9s](https://k9scli.io/): a terminal based UI to interact with your Kubernetes clusters
  * [OpenShift 4 cli (oc)](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html): OpenShift client, equivalent and compatible with kubectl
  * [eksctl](https://eksctl.io/): create and manage EKS clusters on AWS
  * [kops](https://kops.sigs.k8s.io/getting_started/install/): provision Kubernetes clusters on cloud providers
  * [tfk8s](https://github.com/jrhouston/tfk8s): migrate YAML manifests to the [Terraform Kubernetes Provider](https://github.com/hashicorp/terraform-provider-kubernetes)
  * [Carvel tools](https://carvel.dev/ytt/docs/v0.41.0/install/): misc tools (kapp-controller, ytt, kapp, kbld, imgpkg, vendir)
  * [kube-lineage](https://github.com/tohjustin/kube-lineage/): display all dependencies or dependents of an object in a Kubernetes cluster
  * [kfil](https://github.com/ryane/kfilt): filter multidocument YAML like that coming from Helm template to select specific objects for other kubectl commands
  * [skaffold](https://github.com/GoogleContainerTools/skaffold): deploy source code to Kubernetes clusters building, pushing and deploying your application
  * [Artifact Hub cli (ah)](https://github.com/artifacthub/hub): lint packages for publishing them to Artifact Hub for CNCF projects
  * [Tekton cli](https://tekton.dev/docs/cli/): cli to Tekton cloud native CI/CD system
  * [Okteto cli](https://www.okteto.com/docs/cloud/okteto-cli): cli to Okteto shareable preview environments
  * [Crossplane cli](https://crossplane.io/docs/v1.9/getting-started/install-configure.html): provision, compose, and consume infrastructure using the Kubernetes API
  * [crictl](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md): inspect and debug CRI-compatible container runtimes and applications on a Kubernetes node
  * [calicoctl](https://github.com/projectcalico/calico): in order to manage Calico APIs in the `projectcalico.org/v3` API group, calicoctl provides validation and defaulting for these resources that is not available in kubectl
  * [istioctl](https://github.com/istio/istio): configuration command line utility that allows service operators to debug and diagnose their Istio service mesh deployments
  * [inletsctl](https://github.com/inlets/inletsctl): create an exit-server (tunnel server) on public cloud infrastructure
* Cloud
  * [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  * [Google Cloud cli](https://cloud.google.com/sdk/gcloud)
  * [Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  * [Oracle Cloud cli](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
  * [Terraform](https://github.com/hashicorp/terraform): manage cloud assest with a standard language for all providers
  * [Terragrunt](https://github.com/gruntwork-io/terragrunt): Terraform wrapper for keeping configurations DRY, working with multiple Terraform modules, and managing remote state
  * [CloudQuery](https://github.com/cloudquery/cloudquery/): query cloud resources using SQL
  * [SteamPipe](https://github.com/turbot/steampipe/): query cloud resources using SQL
  * [Cloud Custodian](https://cloudcustodian.io/docs/quickstart/index.html): query cloud assests with a standard language for all providers
* Observability
  * [promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/): Prometheus CLI
  * [amtool](https://github.com/prometheus/alertmanager): Alertmanager CLI
  * [pint](https://cloudflare.github.io/pint/): PromQL rule linter
  * [Robusta cli](https://docs.robusta.dev/master/installation.html): cli to Robusta Kubernetes troubleshooting and automation platform
  * [Kubeshark](https://github.com/kubeshark/kubeshark): an API Traffic Viewer for Kubernetes providing real-time, protocol-level visibility into Kubernetes’ internal network, capturing, dissecting and monitoring all traffic and payloads going in, out and across containers, pods, nodes and clusters.
* Cloud Native security
  * Linters
    * [kubeval](https://github.com/instrumenta/kubeval): validate Kubernetes YAML using schemas generated from the Kubernetes OpenAPI specification
    * [kube-linter](https://github.com/stackrox/kube-linter): checks Kubernetes YAML files and Helm charts against a variety of best practices
    * [KubeAudit](https://github.com/Shopify/kubeaudit): audit Kubernetes clusters for security concerns
    * [Bad Robot](https://github.com/controlplaneio/badrobot): Kubernetes Operator static analys for high risk configurations
    * [config-lint](https://github.com/stelligent/config-lint): validate configuration files using YAML rules, including Terraform (built in), Kubernetes (using custom YAML rule files)
    * [copper](cloud66-oss/copper): validate configuration files using JS rules
    * [conftest](open-policy-agent/conftest): validate configuration files using Rego rules
  * Kubernetes general security posture analyzers
    * [Kube-hunter](https://github.com/aquasecurity/kube-hunter): hunt for security weaknesses in Kubernetes clusters
    * [KubeScape](https://github.com/armosec/kubescape): multi-cloud K8s risk analysis, security compliance, RBAC visualizer and image vulnerabilities scanning
    * [polaris](https://github.com/fairwindsops/polaris/): CLI to check Kubernetes pods and controllers using best practices
    * [Eathar](https://github.com/raesene/eathar): pull security related information from Kubernetes clusters about PSS and RBAC
    * [KubeArmor CLI (karmor)](https://github.com/kubearmor/KubeArmor): runtime security enforcement (process execution, file access, networking) containers and node using AppArmor, SELinux or BPF-LSM
    * [Datree](https://github.com/datreeio/datree): automatically validates Kubernetes objects for rule violations, ensuring no misconfigurations reach production
    * [kubectl kubesec-scan](https://github.com/controlplaneio/kubectl-kubesec): security risk analysis
    * [kubectl score](https://github.com/zegl/kube-score): static code analysis for Kubernetes object definitions
    * [kubectl popeye](https://popeyecli.io/): scan cluster for issues
    * [kubectl doctor](https://github.com/emirozer/kubectl-doctor): scan cluster for anomalies
  * RBAC analyzers
    * [KubiScan](https://github.com/cyberark/KubiScan): Scan for risky permissions in RBAC
    * [audit2rbac](https://github.com/liggitt/audit2rbac): generate RBAC based on audit log activity
    * [Eathar](https://github.com/raesene/eathar): pull security related information from Kubernetes clusters about PSS and RBAC
  * Supply chain
     * [cosign](https://github.com/sigstore/cosign): container signing, verification andstorage in an OCI registry
     * [in-toto](https://github.com/in-toto/in-toto): verify signed tasks in a pipeline
     * [chain-bench](https://github.com/aquasecurity/chain-bench): CIS Software Supply Chain benchmark
     * [cfssl](https://github.com/cloudflare/cfssl): CloudFlare's PKI/TLS toolkit, both a command line tool and an HTTP API server for signing, verifying, and bundling TLS certificates
     * Software Bill of Materials (SBOM)
       * [Syft](https://github.com/anchore/syft): generate SBOM from container in different formats
       * [Vexy](https://github.com/madpah/vexy): generate VEX (Vulnerability Exploitability Exchange) in [CycloneDX](https://cyclonedx.org/) format
       * [swid-generator](https://pypi.org/project/swid-generator/): generates [SWID tags](https://csrc.nist.gov/projects/Software-Identification-SWID) from Linux package managers like dpkg, rpm or pacman
       * [vexctl](https://github.com/chainguard-dev/vex): a tool to apply and attest VEX (Vulnerability Exploitability eXchange) data, its purpose is to "turn off" alerts of vulnerabilities known not to affect a product
  * Vulnerability scanners
    * Container vulnerability scanners
      * [Trivy](https://github.com/aquasecurity/trivy): small and fast open source vulnerability and secrets scanner
      * [Grype](https://github.com/anchore/grype): small and fast open source vulnerability scanner
      * [Anchore cli](https://github.com/anchore/anchore-cli): open source vulnerability scanner and Dockerfile analyzer
      * [Snyk](https://docs.snyk.io/snyk-cli/install-the-snyk-cli): small vulnerability scanner
    * Package vulnerability scanning
      * [cve-bin-tool](https://github.com/intel/cve-bin-tool): open source vulnerability scanner using data from [NVD](https://nvd.nist.gov/), from Intel
      * [govulncheck](https://go.dev/security/vuln/): low-noise, reliable way for Go users to learn about known vulnerabilities that may affect their projects
      * [osv-scanner](https://github.com/google/osv-scanner/): officially supported frontend to the OSV.dev database that connects a project’s list of dependencies with the vulnerabilities that affect them
    * Secret Detection
      * [detect-secrets](https://github.com/Yelp/detect-secrets): detecting secrets within a code base
      * [ggshield](https://github.com/GitGuardian/ggshield): detect more than 350+ types of secrets, as well as other potential security vulnerabilities or policy breaks affecting your codebase
  * Infrastructure vulnerability scanners
    * [Checkov](https://www.checkov.io/1.Welcome/Quick%20Start.html): a static code analysis tool for infrastructure as code (IaC) and also a software composition analysis (SCA) tool for images and open source packages
    * [Terrascan](https://github.com/tenable/terrascan#install): OPA based IaC policies for Terraform, Kubernetes, Argo CD, Atlantis and AWS CloudFormation
    * [tfsec](https://github.com/aquasecurity/tfsec): static analysis of your Terraform code to spot potential misconfigurations
    * [TFScan](https://github.com/wils0ns/tfscan): inspect Terraform resources in a state and plan JSON files
  * Security platform's CLI
    * [sdc-cli](https://sysdiglabs.github.io/sysdig-platform-cli/): Sysdig CLI
    * [roxctl](https://docs.openshift.com/acs/3.66/cli/getting-started-cli.html): StackRox CLI
  * Misc
    * [gator](https://open-policy-agent.github.io/gatekeeper/website/docs/gator/): Gatekeeper CLI for evaluating ConstraintTemplates and Constraints
    * [Illuminatio](https://github.com/inovex/illuminatio): automatically testing kubernetes network policies
    * [policy](https://github.com/opcr-io/policy): tool for building, versioning and publishing your authorization policies, using OCI standards to manage artifacts, and the Open Policy Agent (OPA) to compile and run
    * [bane](https://github.com/genuinetools/bane): AppArmor profile generator for docker containers
    * [cmctl](https://cert-manager.io/docs/usage/cmctl/#installation): cert-manager cli
    * [Vault cli](https://www.vaultproject.io/docs/commands): secure, store and control secrets
    * [Tetragon cli](https://github.com/cilium/tetragon): eBPF-based security observability and runtime enforcement
    * [Kubewarden cli](https://github.com/kubewarden/kwctl): policy engine for Kubernetes
* General security and networking
  * [ClamAV](http://www.clamav.net/downloads): Detect malware and virus on Windows or Linux hosts
  * [testssl.sh](https://testssl.sh): checks a server ports for TLS/SSL ciphers, protocols, recent cryptographic flaws, etc
  * [tor, torify](https://gitlab.torproject.org/tpo/team): use a different IP for requests via a p2p connection sharing network
  * [httpx](https://github.com/projectdiscovery/httpx): fast multi-purpose HTTP toolkit to run multiple prober designed to maintain the result reliability with increased threads
  * [Bitwarden cli (bw)](https://github.com/bitwarden/cli): cli to open source Bitwarden secret manager
  * [Doppler cli](https://github.com/DopplerHQ/cli): multi-cloud SecretOps platform
  * [1Password cli](https://1password.com/downloads/command-line/): cli to 1Password secret manager
  * [Yubikey manager](https://github.com/Yubico/yubikey-manager): configure Yubikey
  * [apache2-utils](https://packages.debian.org/es/sid/apache2-utils): includes ab (load testing), logresolve (ip to host name), htpasswd (auth file manipulation), checkgid (test caller can configurate gid), and more.
  * [nmap](https://nmap.org/download), [ncat](https://nmap.org/ncat/), [netcat](https://sectools.org/tool/netcat/), [dig, nslookup, nsupdate](https://packages.debian.org/buster/dnsutils), [ping](https://packages.debian.org/stretch/iputils-ping)
* Load testing:
  * [k6](https://github.com/grafana/k6): load testing tool with javascript plans
  * [artillery](https://github.com/artilleryio/artillery):  load testing and synthetic checks at scale
  * [ab](https://packages.debian.org/es/sid/apache2-utils): included in apache2-utils
* Programming
  * [Python](https://www.python.org/), [pip](https://pypi.org/project/pip/), [pipx](https://github.com/pypa/pipx), [PyEnv](https://github.com/pyenv/pyenv), [Poetry](https://python-poetry.org/docs/)
  * [Node](https://nodejs.org/en/), [npm](https://www.npmjs.com/), [nvm](https://github.com/nvm-sh/nvm), [npx](https://www.npmjs.com/package/npx), [yarn](https://yarnpkg.com/getting-started/)
  * [Go](https://go.dev/), [golangci-lint](https://golangci-lint.run/usage/install/#local-installation), [Ginkgo](https://github.com/onsi/ginkgo), [mockgen (Gomock)](https://github.com/golang/mock)
  * [Ruby](https://www.ruby-lang.org/en/documentation/), [Bundler](https://bundler.io/docs.html)
  * [Dot Net 6](https://docs.microsoft.com/en-us/dotnet/core/install/linux-debian)
  * Tools
    * [Jekyll](https://jekyllrb.com/): static web generator written in Ruby
    * [YAML lint](https://github.com/adrienverge/yamllint): lint YAML files
    * [Shellcheck](https://github.com/koalaman/shellcheck): lint Bash scripts
    * [mmake](https://github.com/tj/mmake): like make but prints help for targets from comments
* Shells
  * [Fish shell](https://fishshell.com/) (default): most feature packed shell
    * [Fisher](https://github.com/jorgebucaran/fisher): a plugin manager for Fish
    * [Bass](https://github.com/edc/bass): bass makes it easy to use utilities written for Bash in fish shell
  * [Bash shell](https://www.gnu.org/software/bash/): most common shell
  * [zsh shell](https://www.zsh.org/): lots of features and compatible with shell
* Command line utilities, miscelaneous
  * make, curl, wget, git, vim, nano and others...
  * [jq](https://stedolan.github.io/jq/), [yq](https://github.com/mikefarah/yq), [yh](https://github.com/andreazorzetto/yh): process and filter json and yaml
  * [jqp (jq playground)](https://github.com/noahgorstein/jqp): text UI playground for exploring jq
  * [JLess](https://github.com/PaulJuliusMartinez/jless): navigate json output with colors, pagination, prettify, and more
  * [GitHub cli (gh)](https://cli.github.com/): cli to GitHub 
  * [GitLab cli](https://gitlab.com/gitlab-org/cli#installation): cli to GitLab
  * [Starship prompt](https://starship.rs/): powerful shell prompt
  * [Thef*ck](https://github.com/nvbn/thefuck): correct errors in the previous console command
  * [Batcat](https://github.com/sharkdp/bat): prettier cat replacement
  * [direnv](https://direnv.net/): load and unload environment variables depending on the current directory
  * [z](https://github.com/rupa/z): smart directory changer
  * [pv](https://ss64.com/bash/pv.html): monitor data being sent through pipe
  * [parallel](https://www.gnu.org/software/parallel/): launch parallel processes from the command line
  * [tmux](https://github.com/tmux/tmux/wiki): a terminal multiplexer, it lets you switch easily between several programs in one terminal, detach them and reattach them to a different terminal
  * [screen](https://ss64.com/bash/screen.html): multiplex a physical terminal between several processes

## Other Cloud Native tools to run in a cluster

The following Cloud Native tools should be installed in the cluster/nodes to be able to use them.

<details>
  <summary>Click to expand!</summary>

* Security
  * Runtime security
    * [Falco](https://github.com/falcosecurity/falco): runtime security based on kernel driver or eBPF
    * [Tracee](https://github.com/aquasecurity/tracee): runtime security based on eBPF
  * Security posture check
    * [KubeBench](https://github.com/aquasecurity/kube-bench): check CIS benchmarks for Kubernetes clusters
    * [Polaris](https://github.com/FairwindsOps/polaris/): admission controller to check Kubernetes pods and controllers using best practices
    * [RBAC-Police](https://github.com/PaloAltoNetworks/rbac-police): evaluate RBAC permissions of serviceAccounts, pods and nodes using Rego policies
    * [gitgat](https://github.com/scribe-public/gitgat): OPA policies that verify SCM (currently GitHub's) organization/repositories/user accounts security
    * [Kube-Scan](https://github.com/octarinesec/kube-scan): Run it on any cluster, gives a risk score from 0 (no risk) to 10 (high risk) for each workload  based on the runtime configuration of based on the open-source framework [Kubernetes Common Configuration Scoring System (KCCSS)](https://github.com/octarinesec/kccss)
  * Security Platforms (inc vulnerability assesment)
    * [ThreatMapper](https://github.com/deepfence/ThreatMapper): open source Kubernetes security platform
    * [Wazuh](https://github.com/wazuh/wazuh-kubernetes/blob/master/instructions.md): open source Kubernetes security platform
    * [SUSE Open Security Platform](https://github.com/neuvector/neuvector): formerly known as NeuVector when it wasn't open source
    * [StackRox](https://www.redhat.com/en/technologies/cloud-computing/openshift/advanced-cluster-security-kubernetes): formerly an independent product, now open source and part of OpenShift, but you can also install it on Kubernetes
    * SELinux and Apparmour related
      * [KubeArmor](https://github.com/kubearmor/KubeArmor): runtime security enforcement (process execution, file access, networking) containers and node using AppArmor, SELinux or BPF-LSM
      * [Security Profiles Operator](https://github.com/kubernetes-sigs/security-profiles-operator): make it easier for users to use SELinux, seccomp and AppArmor in Kubernetes clusters
    * Privative platforms
      * [Sysdig](https://sysdig.com/products/secure/)
      * [Aqua](https://www.aquasec.com/)
      * [Prisma Cloud](https://www.paloaltonetworks.com/prisma/environments/kubernetes): formerly known as Twistlock
      * [Lacework](https://www.lacework.com/)
      * [Anchore](https://anchore.com/): full platform, in addition to its open source tools
      * [Mondoo](https://mondoo.com/platform/)
* Policy / Admission Controller
  * [Gatekeeper](https://github.com/open-policy-agent/gatekeeper): admission controller OPA based
  * [Kyverno](https://github.com/kyverno/kyverno): policy engine and admission controller
  * [Kubewarden](https://github.com/kubewarden): policy engine for Kubernetes
  * [K-rail](https://github.com/cruise-automation/k-rail): workload policy enforcement to secure a multi tenant cluster
* Secret management
  * [Hashicorp Vault](https://www.vaultproject.io/)
  * [Infisical](https://github.com/Infisical/infisical)
* CI/CD / Supply chain
  * [Tekton](https://tekton.dev/docs/getting-started/#tekton-for-kubernetes-cloud-native-cicd-explained)
    * [Chains](https://github.com/tektoncd/chains): observs Tekton tasksruns completion to sign them
  * [Jenkins in Kubernetes](https://github.com/scriptcamp/kubernetes-jenkins)
  * [ArgoCD](https://github.com/argoproj/argo-cd): gitops CD platform
  * [Factory for Repeatable Secure Creation of Artifacts (FRSCA)](https://github.com/buildsec/frsca)  
  * [SPIFFE SPIRE](https://github.com/spiffe/spire): agent and server for establishing trust between software systems
  * [Notary](https://github.com/notaryproject/notary): agent and server to share signed verified content
  * [cert-manager](https://cert-manager.io/docs/usage/cmctl/#installation): open source certificate manager
  * [Jetstack](https://www.jetstack.io/): enterprise solution based on cert-manager
  * [StackHawk](https://www.stackhawk.com/): DAST and API security testing tool that runs in CI/CD
  * [Kaniko](https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster): a tool to build container images from a Dockerfile, inside a container or Kubernetes cluster
  * [Shipit](https://github.com/Shopify/shipit-engine#kubernetes): ynchronize and deploy hundreds of projects across dozens of teams, using Python, Rails, RubyGems, Java, and Go
* Observability
  * [Prometheus, Grafana, Alertmanager](https://github.com/prometheus-community/helm-charts): observability platform
  * [Robusta](https://github.com/robusta-dev/robusta): observability reporting
  * [Fluentd](https://github.com/fluent/fluentd): collects events from various data sources and writes them to files, RDBMS, NoSQL, IaaS, SaaS, Hadoop and so on
  * [Logstash](https://github.com/elastic/logstash): ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite "stash."
* Networking
  * [Calico](https://projectcalico.docs.tigera.io/about/about-calico): network security solution dataplane
  * [Istio](https://github.com/istio/istio): service mesh to integrate microservices and manage traffic flow
  * [Hubble](https://github.com/cilium/hubble): networking and security observability platform built on top of Cilium and eBPF
* Microservices demos
  * [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo): go, c#, node.js, Java; includes Locust synthetic load generator, doesn't include databases
  * [Weaveworks Sock Shop](https://github.com/microservices-demo/microservices-demo): Java, .Net, Go, Node.js, Mongo, MySQL
* Autoscaling
  [Karpenter](https://karpenter.sh/): open-source node provisioning project for Kubernetes
* Cost analysis
  * [OpenCost](https://www.opencost.io/docs/install): vendor-neutral open source project for measuring and allocating infrastructure and container costs in real time
  * [KubeCost](https://www.kubecost.com/): enterprise offering based on OpenCost
* Other
  * [Crossplane](https://crossplane.io/docs/v1.9/getting-started/install-configure.html): provision, compose, and consume infrastructure using the Kubernetes API
  * [Portainer](https://docs.portainer.io/start/install-ce/server/kubernetes/baremetal#deploy-using-helm): a lightweight service delivery platform for containerized applications that can be used to manage Docker, Swarm, Kubernetes and ACI environments, to manage orchestrator resources (containers, images, volumes, networks and more) through a ‘smart’ GUI and/or an extensive API
  * [JFrog Artifactory CE](https://jfrog.com/community/download-artifactory-oss/): binary artifact repositories
  * [GitLab CE](https://gitlab.com/gitlab-org/gitlab): software development platform with version control, issue tracking, code review, CI/CD, and more
  * [Sentry](https://github.com/getsentry/sentry): developer-first error tracking and performance monitoring platform
  * [Graylog](https://github.com/Graylog2/graylog-docker): centralized logging solution that enables aggregating and searching through logs
  * [Locust](https://locust.io/): define user behaviour with Python code, and swarm your system with millions of simultaneous users
  * [Teleport](https://github.com/gravitational/teleport): an identity-aware, multi-protocol access proxy which understands SSH, HTTPS, RDP, Kubernetes API, MySQL, MongoDB and PostgreSQL wire protocols


</details>

## Additional tools not installed

The following tools have big requirements that would make the container image even bigger than it already is, or are meant to run graphical UI.

<details>
  <summary>Click to expand!</summary>

* [Cloud mapper](https://github.com/duo-labs/cloudmapper#installation): analyze AWS environments auditing for security issues
* [Dagda](https://github.com/eliasgranderubio/dagda): static analysis of known vulnerabilities, trojans, viruses, malware in container images and running containers on Docker.
* [Resoto](https://resoto.com/docs/getting-started/install-resoto): maps out your cloud infrastructure, generate reports, automate tasks
* [OpenSCAP base](https://www.open-scap.org/tools/openscap-base/#download): cli to parse and evaluate the SCAP standard
* [SCAP Workbench](https://www.open-scap.org/tools/scap-workbench/#download): graphical utility to perform oscap tasks
* [iamspy](https://github.com/WithSecureLabs/iamspy): load IAM policies and convert them to Z3 prover constraints and a model for querings if actions are allowed
* [cntr](https://github.com/Mic92/cntr): brings all your developers tools to a minimal running docker container by using a FUSE filesystem, similar to ephemeral containers in Kubernetes
* [Finch](https://github.com/runfinch/finch): an open source client for container development for MacOs, integrated with nerdctl for build/run/push/pull, containerd for container management, buildkit for OCI image builds, pulled together and run with a vm managed by [Lima](https://github.com/lima-vm/lima).
* [nerdctl](https://github.com/containerd/nerdctl): docker-compatible CLI for containerd, width rootless image build
* Programming
  * [Miniconda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html): Python package manager
  * GitHub Actions
    * [Golang Vulncheck](https://github.com/Templum/govulncheck-action): scan go code for vulnerabilities

</details>

## Other miscellaneous links:

<details>
  <summary>Click to expand!</summary>

Software

* Security Tools
  * [Yaradare](https://github.com/deepfence/YaRadare): YAR malware container image scanner
  * [SecretScanner](https://github.com/deepfence/SecretScanner): find unprotected secrets in container images or file systems
  * [PacketStreamer](https://github.com/deepfence/PacketStreamer): remote packet capture and collection tool
  * [Defect Dojo](https://github.com/DefectDojo/django-DefectDojo): security orchestration and vulnerability management platform, push findings to systems like JIRA and Slack
  * [OWASP Zed Attack Proxy (ZAP)](https://github.com/zaproxy/zaproxy): automatically find security vulnerabilities in your web applications while you are developing and testing your applications
  * Code Security
    * [SemGrep](https://semgrep.dev/): open source static analysis tool for finding bugs, detecting vulnerabilities in third-party dependencies, and enforcing code standards
    * [GitGuardian](https://www.gitguardian.com/): SaaS to scan your source code to detect api keys, passwords, certificates, encryption keys and other sensitive data in real-time
    * [CodeQL](https://codeql.github.com/): semantic code analysis engine. CodeQL lets you query code as though it were data, to find all variants of a vulnerability, and eradicate it 
    * [SonarQube](https://www.sonarsource.com/products/sonarqube/): code quality and code security analysis for up to 27 programming languages; find bugs, vulnerabilities, security hotspots and code smells throughout your workflow
    * [Checkmarx](https://checkmarx.com) static and interactive application security testing (SAST and IAST), Software Composition Analysis (SCA), infrastructure as code security testing (KICS), and application security and training development (Codebashing)
    * [Veracode](https://www.veracode.com/): a SaaS application security solution, DAST test tool for application security testing
* Kubernetes installation and distributions
  * [KubeAdm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/): official Kubernetes installation tool
  * [Kubespray](https://github.com/kubernetes-sigs/kubespray): deploy a production ready Kubernetes cluster on AWS, GCE, Azure, OpenStack, vSphere, Equinix Metal (bare metal), Oracle Cloud Infrastructure (Experimental), or Baremetal
  * [OKD](https://www.okd.io/installation/): Kubernetes distribution base for OpenShift
  * [k3s](https://k3s.io): lightweight Kubernetes distribution based on Rancher
  * [k3d](https://k3d.io): lightweight wrapper to run k3s on Docker
  * [k0s](https://docs.k0sproject.io/v1.24.2+k0s.0/install/): lightweight Kubernetes installation tool
  * SaaS
    * [AWS EKS](https://aws.amazon.com/eks/): Elastic Kubernetes Service, by AWS
    * [GCP GKE](https://cloud.google.com/kubernetes-engine): Google Kubernetes Engine
    * [Azure AKS](https://azure.microsoft.com/es-mx/products/kubernetes-service/): Azure Kubernetes Service, by Microsoft
    * [Suse RKE](https://www.suse.com/products/rancher-kubernetes-engine/): Rancher Kubernetes Engine, by Suse
    * [Oracle OKE](https://www.oracle.com/es/cloud/cloud-native/container-engine-kubernetes/): Oracle Kubernetes Engine
    * [Alibaba ACK](https://www.alibabacloud.com/product/kubernetes): Alibaba Cloud Container Service for Kubernetes
    * [DigitalOcean DOKS](https://www.digitalocean.com/products/kubernetes): DigitalOcean Kubernetes
* Isolation of nodes
  * [Kata containers](https://katacontainers.io/)
  * [Confidential Containers](https://github.com/confidential-containers)
  * [Confidential GKE Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes)
  * [Firecraker](https://firecracker-microvm.github.io/)
  * [gVisor](https://gvisor.dev/)
* Cloud provider's security tools
  * AWS
    * [Security Hub](https://aws.amazon.com/security-hub/)
    * [Guard Duty](https://docs.aws.amazon.com/guardduty/latest/ug/malware-protection.html)
    * [Control Tower](https://aws.amazon.com/controltower/)
  * Google
    * [Security Command Center](https://cloud.google.com/security-command-center)
  * Azure
    * [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction)
* Other security platforms
  * [Open VAS](https://www.openvas.org/): centralized network vulnerability scanner server
  * [Qualys](https://www.qualys.com/): identify assets on your global hybrid-IT—on prem, endpoints, clouds, containers, mobile, OT and IoT—for a complete, categorized inventory
  * [Checkpoint](https://www.checkpoint.com/): software and combined hardware and software products for IT security, including network security, endpoint security, cloud security, mobile security, data security and security management
  * [Rapid7](https://www.rapid7.com/)
  * [SentinelOne](https://sentinelone.com/)
  * [Splunk](https://www.splunk.com/)
  * [Snyk](https://snyk.io/)
  * [CyberArk](https://www.cyberark.com/)
* SaaS Tools
  * [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
  * [Grafana Cloud](https://grafana.com/products/cloud/)
  * [Amazon Managed Service for Prometheus](https://aws.amazon.com/prometheus/)
  * [DockerHub](https://hub.docker.com): container image and Helm chart registry
  * [Quay.io](https://quay.io/): free container image registry
* Other tools
  * Online
    * [Atlantis](https://github.com/runatlantis/atlantis): listens for Terraform pull request events via webhooks, automatically runs terraform plan and comments back on the pull request
  * Local CLI
    * [markmap](https://markmap.js.org/docs#markmap-cli): markdown mindmap generation
    * [plantuml](https://plantuml.com/starting): markdown UML diagram generation

Links and information

* Security information
  * [MITRE ATT&CK](https://attack.mitre.org/), [ATT&CK navigator](https://mitre-attack.github.io/attack-navigator/), and [D3FEND](https://d3fend.mitre.org/)
  * [MITRE Common Weakness Enumeration (CWE)](https://cwe.mitre.org/): list of software and hardware weakness types
  * [Cloud Security Alliance](https://cloudsecurityalliance.org/): information to define and raise awareness of best practices to ensure a secure cloud computing environment
  * [Open Web Application Security Project (OWASP)](https://owasp.org/): an online community that produces freely-available articles, methodologies, documentation, tools, and technologies in the field of web application security
  * Benchmarks
    * [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/): security standards for hardening IT systems and data against cyberattacks
    * [Security Technical Implementation Guides (STIGs)](https://public.cyber.mil/stigs/): checklist to ensure and enhance security in systems
  * Cloud Best Practices
    * [GCP Security Foundations Blueprint](https://cloud.google.com/architecture/security-foundations)
    * [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
  * Vulnerability databases
    * [MITRE Common Vulnerability and Exposures (CVE)](https://www.cve.org/): a catalog of known security threats
    * [NIST Vulneratibility Database (NVD)](https://nvd.nist.gov/): enhances CVE with scores and exploitation information
    * [osv.dev](https://osv.dev/): open, precise, and distributed approach to producing and consuming vulnerability information for open source
    * [CIRCL hashlookup](https://www.circl.lu/services/hashlookup/): free lookup hash values against known database of files (malicious/non malicious)
    * [GitHub Advisory Database](https://github.com/github/advisory-database): a free and open source community driven database of CVEs and GitHub-originated security advisories affecting the open source world, it powers npm audit
    * [Go Vulnerability Database](https://pkg.go.dev/vuln/): data come directly from Go package maintainers or sources such as MITRE and GitHub, reports are curated by the Go Security team
    * [Virustotal API](https://developers.virustotal.com/reference/overview)    
    * Cloud vuln db
      * [secwiki.cloud](https://www.secwiki.cloud/): cloud vulnerability wiki
      * [cloudvulndb.org](https://www.cloudvulndb.org/): open cloud vulnerability & security issue database
    * Distro specific
      * [Debian Security Advisories](https://www.debian.org/security/)
      * [Red Hat Security Updates](https://access.redhat.com/security/security-updates/#/)
      * [SUSE Update Advisories](https://www.suse.com/support/update/)
      * [Ubuntu Security Notices](https://ubuntu.com/security/notices)
  * Malicious binaries and activity samples
    * [The Zoo](https://github.com/ytisf/theZoo): a live malware repository
    * [Adversary Emulation Library](https://github.com/center-for-threat-informed-defense/adversary_emulation_library): a library of adversary emulation plans to allow organizations to evaluate their defensive capabilities against the real-world threats    
    * [MITRE Common Attack Pattern Enumerations and Classifications (CAPEC)](https://capec.mitre.org/): comprehensive dictionary of known patterns of attack employed by adversaries to exploit known weaknesses
    * [MITRE CALDERA](https://github.com/mitre/caldera): cyber security platform to automate adversary emulation, assist manual red-teams, and automate incident response
* Kernel Hardening
  * [seccomp](https://www.kernel.org/doc/html/v4.19/userspace-api/seccomp_filter.html)
  * [AppArmour](https://apparmor.net/)
  * [SELinux](https://www.redhat.com/en/topics/linux/what-is-selinux)
* Standards and metadata formats
  * [Grafeas](https://grafeas.io/): metadata for software supply chain
  * [Open Security Controls Assessment Language (OSCAL)](https://csrc.nist.gov/Projects/open-security-controls-assessment-language): standarized formats for the publication, implementation, and assessment of security controls
  * [Security Content Automation Protocol (SCAP)](https://csrc.nist.gov/projects/security-content-automation-protocol): interoperable specifications for security controls, [more](https://www.cisecurity.org/insights/blog/secure-configurations-and-the-power-of-scap)
  * [Structured Threat Information Expression (STIX)](https://stixproject.github.io/about/): language to exchange cyber threat intelligent
  * Vulnerability related
    * [Vulnerability Exploitability Exchange (VEX)](https://cyclonedx.org/capabilities/vex/): assess the exploitability of vulnerabilities in products
    * [Exploit Prediction Scoring System (EPSS)](https://www.first.org/epss/): open, data-driven effort for estimating the likelihood that a software vulnerability will be exploited in the wild
  * Software Bill of Materials (SBOM)
    * [CycloneDX](https://cyclonedx.org/): lightweight SBOM standard useful for application security contexts and supply chain component analysis
    * [Software Product Data Exchange (SPDX)](https://spdx.dev/specifications/): international open standard (ISO/IEC 5962:2021) format for communicating the components, licenses, and copyrights associated with a software package
    * [International standard for software identification tags (SWID)](https://nvlpubs.nist.gov/nistpubs/ir/2016/NIST.IR.8060.pdf): a SWID tag is a structured set of data elements that identify and describe a software product

</details>
