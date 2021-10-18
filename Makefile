PORT?=10070
CMD?=corpquery susanne '[word="Mardi"][word="Gras"]'
IMAGE_NAME?=eltedh/nosketch-engine
CONTAINER_NAME?=noske
CORPORA_DIR?=$$(pwd)/corpora
SERVER_NAME?=https://sketchengine.company.com/
SERVER_ALIAS?=sketchengine.company.com
CITATION_LINK?=https://github.com/elte-dh/NoSketch-Engine-Docker


all: build compile run
.PHONY: all


# Pull prebuilt $(IMAGE_NAME) docker image from Dockerhub
pull:
	docker pull $(IMAGE_NAME):latest
.PHONY: pull


# Build $(IMAGE_NAME) docker image
build:
	docker build -t $(IMAGE_NAME) .
.PHONY: build


# Create self-signed certs for Shibboleth
create-cert:
	@if [ ! -f secrets/sp.for.eduid.service.hu-cert.crt -a ! -f secrets/sp.for.eduid.service.hu-key.crt ] ; then \
        openssl req -new -newkey rsa:2048 -x509 -days 3652 -nodes \
         -out secrets/sp.for.eduid.service.hu-cert.crt -keyout secrets/sp.for.eduid.service.hu-key.crt ; \
    else \
        echo 'At least one of the certfiles (secrets/sp.for.eduid.service.hu-cert.crt, '\
         'secrets/sp.for.eduid.service.hu-key.crt) exitst. Delete them (e.g. with make remove-cert) to proceeed!' >&2 \
         && exit 1 ; \
    fi
.PHONY: create-cert


# Remove self-signed certs
remove-cert:
	rm -rf secrets/sp.for.eduid.service.hu-cert.crt secrets/sp.for.eduid.service.hu-key.crt
.PHONY: remove-cert


# Run $(CONTAINER_NAME) container from $(IMAGE_NAME) image, mount $(CORPORA_DIR), use host port $(PORT)
#  and set various environment variables
run:
	@make -s stop
	docker run -d --rm --name $(CONTAINER_NAME) -p$(PORT):80 --mount type=bind,src=$(CORPORA_DIR),dst=/corpora \
     -e SERVER_NAME="$(SERVER_NAME)" -e SERVER_ALIAS="$(SERVER_ALIAS)" -e CITATION_LINK="$(CITATION_LINK)" \
     $(IMAGE_NAME):latest
	@echo 'URL: http://localhost:$(PORT)/'
.PHONY: run


# Stop running $(CONTAINER_NAME) container
stop:
	@if [ "$$(docker container ls -f name=$(CONTAINER_NAME) -q)" ] ; then \
        docker container stop $(CONTAINER_NAME) ; \
    else \
        echo 'No running $(CONTAINER_NAME) container!' >&2 ; \
    fi
.PHONY: stop


# Connect to running $(CONTAINER_NAME) container, start a bash shell
connect:
	docker exec -it $(CONTAINER_NAME) /bin/bash
.PHONY: connect


# Execute commmand in CMD variable and set various environment variables
execute:
	docker run --rm -it --mount type=bind,src=$(CORPORA_DIR),dst=/corpora -e FORCE_RECOMPILE="$(FORCE_RECOMPILE)" \
     -e SERVER_NAME="$(SERVER_NAME)" -e SERVER_ALIAS="$(SERVER_ALIAS)" -e CITATION_LINK="$(CITATION_LINK)" \
     $(IMAGE_NAME):latest "$(CMD)"
.PHONY: execute


# Compile all corpora
compile:
	@make -s execute IMAGE_NAME=$(IMAGE_NAME) FORCE_RECOMPILE=$(FORCE_RECOMPILE) CMD=compile.sh
.PHONY: compile


# Create a strong password with htpasswd command inside the docker image
htpasswd:
	@make -s execute IMAGE_NAME=$(IMAGE_NAME) CMD="htpasswd -nbB \"$(USERNAME)\" \"$(PASSWORD)\""


# Stop container, remove image, remove compiled corpora
clean:
	@make -s stop CONTAINER_NAME=$(CONTAINER_NAME)
	docker image rm -f $(IMAGE_NAME)
	sudo rm -vrf $(CORPORA_DIR)/*/indexed/
.PHONY: clean
