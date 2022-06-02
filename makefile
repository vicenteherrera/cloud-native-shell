.PHONY: all

BASH_SHELL=/bin/bash
FISH_SHELL=/usr/bin/fish
ZSH_SHELL=/usr/bin/zsh

DEFAULT_SHELL=${FISH_SHELL}
PASSWORD=changeme

all: build run

build:
	sudo docker build . -t cli-dev-shell \
		--build-arg debian_ver=11.3 \
		--build-arg minikube_ver=1.23.2 \
		--build-arg minishift_ver=1.34.3 \
		--build-arg kind_ver=0.12.0 \
		--build-arg stern_ver=1.11.0 \
		--build-arg gcloud_ver=378.0.0 \
		--build-arg jless_ver=0.8.0 \
		--build-arg yq_version=4.25.1 \
		--build-arg 1password_ver=2.0.0 \
		--build-arg roxctl_ver=3.68.1 \
		--build-arg kubeaudit_ver=0.17.0 \
		--build-arg helmfile_ver=0.144.0 \
		--build-arg audit2rbac_ver=0.9.0 \
		--build-arg crictl_ver=1.24.1 \
		--build-arg tfscan_ver=0.6.3 \
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

run:
	sudo docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$(pwd):/home/$$(id -un)/data \
		-v /dev/bus/usb:/dev/bus/usb \
		-v /sys/bus/usb/:/sys/bus/usb/ \
		-v /sys/devices/:/sys/devices/ \
		-v /dev/hidraw1:/dev/hidraw1 \
		--privileged \
		--hostname awing --name cli-dev-shell cli-dev-shell

# /dev/hidraw1 mounted to access Yubikey, with /dev/bus/usb, /sys/bus/usb and /sys/devices
# May be in a different number for you, check https://forum.yubico.com/viewtopic61c9.html?p=8058
