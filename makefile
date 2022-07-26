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

RUNSUDO := $(shell groups | grep ' docker ' 1>/dev/null || echo "sudo")

# build the image, tag it and run it
all: build tag run

NOCACHE_PARAM=""

# lint Dockerfile using dockerlint
lint:
	hadolint ./Dockerfile

# build the container image cli-dev-shell
build:
	${RUNSUDO} docker build . -t cli-dev-shell \
		$$NOCACHE_PARAM \
		--build-arg GHTOKEN="$$GHTOKEN" \
		--build-arg debian_ver=11.4 \
		--build-arg one_password_ver=2.5.1 \
		--build-arg go_ver=1.18 \
		--build-arg dotnet_ver=6.0 \
		--build-arg user=$$(id -un) \
		--build-arg group=$$(id -un) \
		--build-arg uid=$$(id -u) \
		--build-arg gid=$$(id -g) \
		--build-arg shell=${DEFAULT_SHELL} \
		--build-arg pass=${PASSWORD}
	@echo ""
	${RUNSUDO} docker image ls cli-dev-shell
	@echo ""
	@$(MAKE) -s sbom-cp
	@echo ""
	@$(MAKE) -s layer-size

# extract sbom from the container image
sbom-cp:
	docker create --name cli-dev-shell-test-copy-sbom cli-dev-shell && \
		docker cp cli-dev-shell-test-copy-sbom:/home/$$(id -un)/sbom.txt ./info/sbom.txt ||: && \
		docker rm cli-dev-shell-test-copy-sbom

# rebuild the container image ignoring cache
upgrade:
	@$(MAKE) -s build NOCACHE_PARAM="--no-cache"

# tag the container image for pushing as quay.io/vicenteherrera/cli-dev-shell
tag:
	${RUNSUDO} docker tag cli-dev-shell quay.io/vicenteherrera/cli-dev-shell

# generate file with layer size information
layer-size:
	@ echo "generating layer-size.txt" && \
	  docker history --no-trunc quay.io/vicenteherrera/cli-dev-shell:latest \
			--format "table {{.Size}}\t{{.CreatedBy}}" \
		| ./scripts/str_replace.pl "GHTOKEN=$$GHTOKEN " ""  \
	  | ./scripts/str_replace.pl "dotnet_ver=6.0 " "" | ./scripts/str_replace.pl "go_ver=1.18 " "" | ./scripts/str_replace.pl "clamav_ver=0.105.0 " "" \
		| ./scripts/str_replace.pl "group=vicen gid=1000 " "" | ./scripts/str_replace.pl "one_password_ver=2.5.1 " "" \
		| ./scripts/str_replace.pl "dotnet_ver=6.0 go_ver=1.18 clamav_ver=0.105.0 one_password_ver=2.5.1 " "" \
		| ./scripts/str_replace.pl "user=vicen uid=1000 pass=changeme shell=/usr/bin/fish " "" \
		> info/layer-size.txt

# run the container image, mounting local directories with credentials for CLI tools
run:
	KUBEDIR_PARAM=""  && [ -d "$$HOME/.kube" ]     &&  KUBEDIR_PARAM="-v $$HOME/.kube:/home/$$(id -un)/.kube"; \
	AWS_PARAM=""      && [ -d "$$HOME/.aws" ]      &&      AWS_PARAM="-v $$HOME/.aws:/home/$$(id -un)/.aws"; \
	MINIKUBE_PARAM="" && [ -d "$$HOME/.minikube" ] && MINIKUBE_PARAM="-v $$HOME/.minikube:/home/$$(id -un)/.minikube"; \
	SSH_PARAM=""      && [ -d "$$HOME/.ssh" ]      &&      SSH_PARAM="-v $$HOME/.ssh:/home/$$(id -un)/.ssh"; \
	AZURE_PARAM=""    && [ -d "$$HOME/.azure" ]    &&    AZURE_PARAM="-v $$HOME/.azure:/home/$$(id -un)/.azure"; \
	GCLOUD_PARAM=""   && [ -d "$$HOME/.config/gcloud" ] && GCLOUD_PARAM="-v $$HOME/.config/gcloud:/home/$$(id -un)/.config/gcloud"; \
	${RUNSUDO} docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$$KUBEDIR_PARAM $$AWS_PARAM $$MINIKUBE_PARAM \
		$$SSH_PARAM $$AZURE_PARAM $$GCLOUD_PARAM \
		-v $$(pwd):/home/$$(id -un)/data \
		-v /dev/bus/usb:/dev/bus/usb \
		-v /sys/bus/usb/:/sys/bus/usb/ \
		-v /sys/devices/:/sys/devices/ \
		-v /dev/hidraw1:/dev/hidraw1 \
		--privileged \
		--hostname tardis --name cli-dev-shell \
		quay.io/vicenteherrera/cli-dev-shell \
		${RUN_SHELL}

#-  /dev/hidraw1 mounted to access Yubikey, with /dev/bus/usb, /sys/bus/usb and /sys/devices
#-  May be in a different number for you, check https://forum.yubico.com/viewtopic61c9.html?p=8058

# run the container image without sharing any local file with it
run-no-sharing:
	${RUNSUDO} docker run --rm -it \
		--hostname tardis --name cli-dev-shell \
		quay.io/vicenteherrera/cli-dev-shell \
		${RUN_SHELL}

# push the container image to quay.io/vicenteherrera/cli-dev-shell
push: tag
	${RUNSUDO} docker push quay.io/vicenteherrera/cli-dev-shell

# pull the container image from quay.io/vicenteherrera/cli-dev-shell
pull:
	${RUNSUDO} docker pull quay.io/vicenteherrera/cli-dev-shell
