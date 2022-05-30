# command-line-env

A command line environment configured with tools for cloud-native development.

## Software included

* [Debian 11 "Bullseye"](https://www.debian.org/News/2021/20210814)
* Containers and VM
  * [Docker](https://docs.docker.com/engine/reference/commandline/cli/)
  * [Podman](https://podman.io/)
  * [Buildah](https://buildah.io/)
  * [Skopeo](https://github.com/containers/skopeo)
  * [Vagrant](https://www.vagrantup.com/)
  * [Docker slim](https://github.com/docker-slim/docker-slim)
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
  * [Okteto cli](https://www.okteto.com/docs/cloud/okteto-cli)
  * [crictl](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)
  * [Minikube](https://minikube.sigs.k8s.io/docs/start/)
  * [Minishift](https://github.com/minishift/minishift)
  * [Kind](https://kind.sigs.k8s.io/)
* Cloud
  * [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  * [Google Cloud cli](https://cloud.google.com/sdk/gcloud)
  * [Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  * [Terraform](https://github.com/hashicorp/terraform)
* Observability
  * [Prometheus (promtool)](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)
  * [Alertmanager (amtool)](https://github.com/prometheus/alertmanager)
  * [Robusta cli](https://docs.robusta.dev/master/installation.html)
* Programming
  * Python, pip, PyEnv, Poetry
  * node, npm, nvm
  * Go
  * Ruby, Jekyll, Bundler
  * Dot Net 6
  * [YAML lint](https://github.com/adrienverge/yamllint)
  * [Shellcheck](https://github.com/koalaman/shellcheck)
* Local security
  * [1Password cli](https://1password.com/downloads/command-line/)
  * [Yubikey manager](https://github.com/Yubico/yubikey-manager)
* Cloud Native security
  * [KubeAudit](https://github.com/Shopify/kubeaudit)
  * [Kube-hunter](https://github.com/aquasecurity/kube-hunter)
  * [audit2rbac](https://github.com/liggitt/audit2rbac)
  * [Trivy](https://github.com/aquasecurity/trivy)
  * [Grype](https://github.com/anchore/grype)
  * [Snyk](https://docs.snyk.io/snyk-cli/install-the-snyk-cli)
  * [detect-secrets](https://github.com/Yelp/detect-secrets)
  * [Tetragon cli](https://github.com/cilium/tetragon)
  * [sdc-cli (Sysdig cli)](https://sysdiglabs.github.io/sysdig-platform-cli/)
  * [roxctl](https://docs.openshift.com/acs/3.66/cli/getting-started-cli.html)
* Shells
  * Bash shell
  * Fish shell (default)
  * zsh shell
* Command line utilities, miscelaneous
  * make, curl, wget, git, vim, nano and others
  * [jq](https://stedolan.github.io/jq/), [yq](https://github.com/mikefarah/yq)
  * [GitHub cli](https://cli.github.com/)
  * [JLess](https://github.com/PaulJuliusMartinez/jless)
  * [Starship prompt](https://starship.rs/)
  * [Thef*ck](https://github.com/nvbn/thefuck)
  * [Batcat](https://github.com/sharkdp/bat)
  * [direnv](https://direnv.net/)
  * [z](https://github.com/rupa/z)
  * [Jekyll](https://jekyllrb.com/), [Bundler](https://bundler.io/)

## Other open source Cloud Native tools for a cluster

The following Cloud Native tools should be installed in the cluster/nodes to be able to use them.

* [Falco](https://github.com/falcosecurity/falco)
* [KubeBench](https://github.com/aquasecurity/kube-bench)
* [Gatekeeper](https://github.com/open-policy-agent/gatekeeper)
* [Hashicorp Vault](https://www.vaultproject.io/)
* [Notary](https://github.com/notaryproject/notary)
* [Chains](https://github.com/tektoncd/chains)
* [Calico](https://projectcalico.docs.tigera.io/about/about-calico)
* [RBAC-Police](https://github.com/PaloAltoNetworks/rbac-police)
* [Tracee](https://github.com/aquasecurity/tracee)
* [Hubble](https://github.com/cilium/hubble)
* [ThreatMapper](https://github.com/deepfence/ThreatMapper)

## Build locally and launch

```bash
make
```
