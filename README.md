# command-line-env

A command line environment configured with tools for cloud-native development

## Software included

* Debian 11
* Containers and VM
  * [Docker](https://docs.docker.com/engine/reference/commandline/cli/)
  * [Podman](https://podman.io/)
  * [Buildah](https://buildah.io/)
  * [Skopeo](https://github.com/containers/skopeo)
  * [Vagrant](https://www.vagrantup.com/)
* Kubernetes
  * [Kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/), aliases
  * [Krew](https://krew.sigs.k8s.io/)
  * [Kubectx, Kubens](https://github.com/ahmetb/kubectx)
  * [OpenShift 4 cli (oc)](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html)
  * [eksctl](https://eksctl.io/)
  * [Helm](https://helm.sh/)
  * [Helmfile](https://github.com/roboll/helmfile)
  * [Stern](https://github.com/wercker/stern)
  * [Tekton cli](https://tekton.dev/docs/cli/)
  * [crictl](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)
  * [Minikube](https://minikube.sigs.k8s.io/docs/start/)
  * [Minishift](https://github.com/minishift/minishift)
  * [Kind](https://kind.sigs.k8s.io/)
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
  * [Tetragon cli](https://github.com/cilium/tetragon)
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
  * [Thef*ck](https://github.com/nvbn/thefuck)
  * [Batcat](https://github.com/sharkdp/bat)
  * [direnv](https://direnv.net/)
  * [z](https://github.com/rupa/z)
  * [Jekyll](https://jekyllrb.com/), [Bundler](https://bundler.io/)

# Other Cloud Native tools not installed

The following Cloud Native tools should be installed in the cluster/nodes to be able to use them.

* [Falco](https://github.com/falcosecurity/falco)
* [KubeBench](https://github.com/aquasecurity/kube-bench)
* [Tracee](https://github.com/aquasecurity/tracee)
* [Hubble](https://github.com/cilium/hubble)
* [RBAC-Police](https://github.com/PaloAltoNetworks/rbac-police)
* [Gatekeeper](https://github.com/open-policy-agent/gatekeeper)
