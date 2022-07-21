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

# -----------------------------------------------------------------------------------------------

RUNSUDO := $(shell groups | grep ' sudo ' 1>/dev/null && echo "sudo")

all: build tag run

NOCACHE_PARAM=""

lint:
	dockerlint

build:
	${RUNSUDO} docker build . -t cli-dev-shell \
		$$NOCACHE_PARAM \
		--build-arg debian_ver=11.4 \
		--build-arg one_password_ver=2.0.0 \
		--build-arg go_ver=1.18 \
		--build-arg dotnet_ver=6.0 \
		--build-arg user=$$(id -un) \
		--build-arg group=$$(id -un) \
		--build-arg uid=$$(id -u) \
		--build-arg gid=$$(id -g) \
		--build-arg shell=${DEFAULT_SHELL} \
		--build-arg pass=${PASSWORD}
	${RUNSUDO} docker image ls cli-dev-shell

upgrade:
	@$(MAKE) -s build NOCACHE_PARAM="--no-cache"

tag:
	${RUNSUDO} docker tag cli-dev-shell quay.io/vicenteherrera/cli-dev-shell

run:
	KUBEDIR_PARAM=""  && [ -d "$$HOME/.kube" ]     &&  KUBEDIR_PARAM="-v $$HOME/.kube:/home/$$(id -un)/.kube"; \
	AWS_PARAM=""      && [ -d "$$HOME/.aws" ]      &&      AWS_PARAM="-v $$HOME/.aws:/home/$$(id -un)/.aws"; \
	MINIKUBE_PARAM="" && [ -d "$$HOME/.minikube" ] && MINIKUBE_PARAM="-v $$HOME/.minikube:/home/$$(id -un)/.minikube"; \
	SSH_PARAM=""      && [ -d "$$HOME/.ssh" ]      &&      SSH_PARAM="-v $$HOME/.ssh:/home/$$(id -un)/.ssh"; \
	AZURE_PARAM=""    && [ -d "$$HOME/.azure" ]    &&    AZURE_PARAM="-v $$HOME/.azure:/home/$$(id -un)/.azure"; \
	GCLOUD_PARAM=""   && [ -d "$$HOME/.config/gcloud" ] && GCLOUD_PARAM="-v $$HOME/.config/gcloud:/home/$$(id -un)/.config/gcloud "; \
	${RUNSUDO} docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$$KUBEDIR_PARAM $$AWS_PARAM $$MINIKUBE_PARAM \
		$$SSH_PARAM $$AZURE_PARAM $$GCLOUD_PARAM
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

push: tag
	${RUNSUDO} docker push quay.io/vicenteherrera/cli-dev-shell

pull:
	${RUNSUDO} docker pull quay.io/vicenteherrera/cli-dev-shell
