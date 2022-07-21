.PHONY: all

BASH_SHELL=/bin/bash
FISH_SHELL=/usr/bin/fish
ZSH_SHELL=/usr/bin/zsh

# Default shell to use when building the image
DEFAULT_SHELL=${FISH_SHELL}
# Password for sudo to use when building the image
PASSWORD=changeme
# Shell to use when running the image, unless a different one state in SHELL environment variable
RUN_SHELL=${FISH_SHELL}

all: build tag run

NOCACHE_PARAM=""

lint:
	dockerlint

build:
	RUNSUDO="" && groups | grep ' docker ' 1>/dev/null || RUNSUDO="sudo" ; \
		$$RUNSUDO docker build . -t cli-dev-shell \
			$$NOCACHE_PARAM \
			--build-arg debian_ver=11.3 \
			--build-arg gcloud_ver=378.0.0 \
			--build-arg one_password_ver=2.0.0 \
			--build-arg go_ver=1.18 \
			--build-arg dotnet_ver=6.0 \
			--build-arg robusta_minver=0.9.11 \
			--build-arg sdccli_minver=0.7.14 \
			--build-arg checkov_minver=2.0.1184 \
			--build-arg user=$$(id -un) \
			--build-arg group=$$(id -un) \
			--build-arg uid=$$(id -u) \
			--build-arg gid=$$(id -g) \
			--build-arg shell=${DEFAULT_SHELL} \
			--build-arg pass=${PASSWORD}
	docker image ls quay.io/vicenteherrera/cli-dev-shell

upgrade:
	@$(MAKE) -s build NOCACHE_PARAM="--no-cache"

tag:
	RUNSUDO="" && groups | grep ' docker ' 1>/dev/null || RUNSUDO="sudo" ; \
		$$RUNSUDO docker tag cli-dev-shell quay.io/vicenteherrera/cli-dev-shell

run:
	RUNSUDO="" && groups | grep ' docker ' 1>/dev/null || RUNSUDO="sudo" ; \
		KUBEDIR_PARAM=""  && [ -d "$$HOME/.kube" ]     && KUBEDIR_PARAM="-v $$HOME/.kube:/home/$$(id -un)/.kube"; \
		AWS_PARAM=""      && [ -d "$$HOME/.aws" ]      && AWS_PARAM="-v $$HOME/.aws:/home/$$(id -un)/.aws"; \
		MINIKUBE_PARAM="" && [ -d "$$HOME/.minikube" ] && MINIKUBE_PARAM="-v $$HOME/.minikube:/home/$$(id -un)/.minikube"; \
		SSH_PARAM=""      && [ -d "$$HOME/.ssh" ]      && MINIKUBE_PARAM="-v $$HOME/.ssh:/home/$$(id -un)/.ssh"; \
		$$RUNSUDO docker run --rm -it \
			-v /var/run/docker.sock:/var/run/docker.sock \
			$$KUBEDIR_PARAM \
			$$AWS_PARAM \
			$$MINIKUBE_PARAM \
			$$SSH_PARAM \
			-v $$(pwd):/home/$$(id -un)/data \
			-v /dev/bus/usb:/dev/bus/usb \
			-v /sys/bus/usb/:/sys/bus/usb/ \
			-v /sys/devices/:/sys/devices/ \
			-v /dev/hidraw1:/dev/hidraw1 \
			--privileged \
			--hostname awing --name cli-dev-shell \
			quay.io/vicenteherrera/cli-dev-shell \
			${RUN_SHELL}

# /dev/hidraw1 mounted to access Yubikey, with /dev/bus/usb, /sys/bus/usb and /sys/devices
# May be in a different number for you, check https://forum.yubico.com/viewtopic61c9.html?p=8058

push:
	RUNSUDO="" && groups | grep ' docker ' 1>/dev/null || RUNSUDO="sudo" ; \
		$$RUNSUDO docker tag cli-dev-shell quay.io/vicenteherrera/cli-dev-shell && \
		$$RUNSUDO docker push quay.io/vicenteherrera/cli-dev-shell

pull:
	RUNSUDO="" && groups | grep ' docker ' 1>/dev/null || RUNSUDO="sudo" ; \
		$$RUNSUDO docker pull quay.io/vicenteherrera/cli-dev-shell
