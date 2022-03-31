.PHONY: all

all: build run

build:
	sudo docker build . -t cli-dev-shell \
		--build-arg minikube_ver=1.23.2 \
		--build-arg kind_ver=0.12.0 \
		--build-arg stern_ver=1.11.0 \
		--build-arg gcloud_ver=378.0.0 \
		--build-arg 1password_ver=2.0.0 \
		--build-arg go_ver=1.18 \
		--build-arg dotnet_ver=6.0 \
		--build-arg user=$$(id -un) \
		--build-arg group=$$(id -un) \
		--build-arg uid=$$(id -u) \
		--build-arg gid=$$(id -g) \
		--build-arg shell=/usr/bin/fish \
		--build-arg pass=changeme

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
