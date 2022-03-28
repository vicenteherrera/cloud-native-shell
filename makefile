.PHONY: all

all: build run

build:
	docker build . -t cli-dev-shell \
		--build-arg minikube_ver=1.23.2 \
		--build-arg stern_ver=1.11.0 \
		--build-arg gcloud_ver=378.0.0 \
		--build-arg user=$$(id -un) \
		--build-arg group=$$(id -un) \
		--build-arg uid=$$(id -u) \
		--build-arg gid=$$(id -g) \
		--build-arg pass=changeme

run:
	docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$(pwd):/data \
		--hostname awing --name cli-dev-shell cli-dev-shell
