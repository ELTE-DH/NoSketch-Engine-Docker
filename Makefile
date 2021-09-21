PORT?=10070
CMD?=corpquery susanne '[word="Mardi"][word="Gras"]'
IMAGE_NAME?=eltedh/nosketch-engine
CONTAINER_NAME?=noske
SERVER_NAME?=https://sketchengine.company.com/
SERVER_ALIAS?=sketchengine.company.com
CITATION_LINK?=https://github.com/elte-dh/NoSketch-Engine-Docker
PRIVATE_KEY?=$$(cat conf/sp.for.eduid.service.hu-key.crt 2> /dev/null)
PUBLIC_KEY?=$$(cat conf/sp.for.eduid.service.hu-cert.crt 2> /dev/null)
HTACCESS?=$$(cat conf/htaccess 2> /dev/null)
HTPASSWD?=$$(cat conf/htpasswd 2> /dev/null)


all: build compile run
.PHONY: all


pull:
	docker pull $(IMAGE_NAME):latest
.PHONY: pull


# Build $(IMAGE_NAME) docker image
build:
	docker build -t $(IMAGE_NAME) .
.PHONY: build


# Create self-signed certs for shibboleth
create-cert:
	@if [ ! -f conf/sp.for.eduid.service.hu-cert.crt -a ! -f conf/sp.for.eduid.service.hu-key.crt ] ; then \
        openssl req -new -newkey rsa:2048 -x509 -days 3652 -nodes -out conf/sp.for.eduid.service.hu-cert.crt -keyout \
         conf/sp.for.eduid.service.hu-key.crt ; \
    else \
        echo 'At least one of the certfiles (conf/sp.for.eduid.service.hu-cert.crt, '\
         'conf/sp.for.eduid.service.hu-key.crt) exitst. Delete them (e.g. with make remove-cert) to proceeed!' \
         && exit 1 ; \
    fi
.PHONY: create-cert


remove-cert:
	rm -rf conf/sp.for.eduid.service.hu-cert.crt conf/sp.for.eduid.service.hu-key.crt
.PHONY: remove-cert


# Run $(CONTAINER_NAME) container from $(IMAGE_NAME) image, mount corpora/, use host port $PORT
#  and set $(SERVER_NAME) & $(SERVER_ALIAS) environment variables for shibboleth
run:
	@make -s stop
	docker run -d --rm --name $(CONTAINER_NAME) -p$(PORT):80 --mount type=bind,src=$$(pwd)/corpora,dst=/corpora \
     -e SERVER_NAME="$(SERVER_NAME)" -e SERVER_ALIAS="$(SERVER_ALIAS)" -e CITATION_LINK="$(CITATION_LINK)" \
     -e PRIVATE_KEY="$(PRIVATE_KEY)" -e PUBLIC_KEY="$(PUBLIC_KEY)" -e HTACCESS="$(HTACCESS)" -e HTPASSWD="$(HTPASSWD)" \
     $(IMAGE_NAME):latest
	@echo 'URL: http://localhost:$(PORT)/'
.PHONY: run


# Stop running $(CONTAINER_NAME) container
stop:
	@if [ "$$(docker container ls -f name=$(CONTAINER_NAME) -q)" ] ; then \
        docker container stop $(CONTAINER_NAME) ; \
    else \
        echo 'no running $(CONTAINER_NAME) container' ; \
    fi
.PHONY: stop


# Connect to running $(CONTAINER_NAME) container, start a bash shell
connect:
	docker exec -it $(CONTAINER_NAME) /bin/bash
.PHONY: connect


# Execute commmand in CMD variable and set $(SERVER_NAME) & $(SERVER_ALIAS) environment variables for shibboleth
execute:
	docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora -e FORCE_RECOMPILE="$(FORCE_RECOMPILE)" \
     -e SERVER_NAME="$(SERVER_NAME)" -e SERVER_ALIAS="$(SERVER_ALIAS)" -e CITATION_LINK="$(CITATION_LINK)" \
     -e PRIVATE_KEY="$(PRIVATE_KEY)" -e PUBLIC_KEY="$(PUBLIC_KEY)" -e HTACCESS="$(HTACCESS)" -e HTPASSWD="$(HTPASSWD)" \
     $(IMAGE_NAME):latest "$(CMD)"
.PHONY: execute


# Compile all corpora
compile:
	@make -s execute IMAGE_NAME=$(IMAGE_NAME) FORCE_RECOMPILE=$(FORCE_RECOMPILE) CMD=compile.sh
.PHONY: compile


# Stop container, remove image, remove compiled corpora
clean:
	@make -s stop CONTAINER_NAME=$(CONTAINER_NAME)
	docker image rm -f $(IMAGE_NAME)
	sudo rm -vrf corpora/*/indexed/
.PHONY: clean
