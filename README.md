# command-line-env

A command line environment configured with tools for cloud-native development

## Software included

* Debian 11
* Containers and VM
  * Docker
  * Podman
  * Buildah
  * Skopeo
  * Vagrant
* Kubernetes
  * Kubectl, aliases
  * Krew
  * Kubectx
  * Kubens
  * OpenShift 4 cli
  * eksctl
  * [Helmfile](https://github.com/roboll/helmfile)
  * Stern
  * Minikube
  * Minishift
  * Kind
  * Tekton cli
* Cloud
  * AWS cli
  * Google Cloud cli
  * Azure cli
  * Terraform
* Observability
  * Prometheus (promtool)
  * Alertmanager (amtool)
* Programming
  * Python, pip, PyEnv, Poetry
  * node, npm, nvm
  * Go
  * Ruby, Jekyll
  * Dot Net 6
* Local security
  * 1Password cli
  * Yubikey manager
* Cloud Native security
  * [KubeAudit](https://github.com/Shopify/kubeaudit)
  * [Kube-hunter](https://github.com/aquasecurity/kube-hunter)
  * [audit2rbac](https://github.com/liggitt/audit2rbac)
  * [Trivy](https://github.com/aquasecurity/trivy)
  * [Grype](https://github.com/anchore/grype)
  * [detect-secrets](https://github.com/Yelp/detect-secrets)
  * [roxctl](https://docs.openshift.com/acs/3.66/cli/getting-started-cli.html)
* Shells
  * Bash shell
  * Fish shell
  * zsh shell
* Command line utilities, miscelaneous
  * make, curl, wget, git, vim, nano and others
  * jq, [yq](https://github.com/mikefarah/yq)
  * [GitHub cli](https://cli.github.com/)
  * [JLess](https://github.com/PaulJuliusMartinez/jless)
  * [Starship prompt](https://starship.rs/)
  * Thef*ck
  * Batcat
  * direnv
  * z
  * Jekyll, Bundler

# Other Cloud Native tools

The following Cloud Native tools should be installed in the cluster/nodes to be able to use them.

* [Falco](https://github.com/falcosecurity/falco)
* [KubeBench](https://github.com/aquasecurity/kube-bench)
* [Tetragon](https://github.com/cilium/tetragon)
* [Tracee](https://github.com/aquasecurity/tracee)
* [Hubble](https://github.com/cilium/hubble)
* [RBAC-Police](https://github.com/PaloAltoNetworks/rbac-police)
* [Gatekeeper](https://github.com/open-policy-agent/gatekeeper)
