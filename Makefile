PORT=10070
CMD=corpquery susanne '[word="Mardi"][word="Gras"]'
IMAGE_NAME=nosketch-engine
CONTAINER_NAME=noske


all: build compile run
.PHONY: all


pull:
	docker pull eltedh/nosketch-engine:latest
.PHONY: pull


build:
	docker build -t $(IMAGE_NAME) .
.PHONY: build


# run $(CONTAINER_NAME) image, mount corpora/ and use host port $PORT
run:
	@make -s stop
	docker run -d --rm --name $(CONTAINER_NAME) -p$(PORT):80 --mount type=bind,src=$$(pwd)/corpora,dst=/corpora \
	    $(IMAGE_NAME):latest
	@echo 'URL: http://localhost:$(PORT)/'
.PHONY: run


# stop running $(CONTAINER_NAME) container
stop:
	@if [ "$$(docker container ls -f name=$(CONTAINER_NAME) -q)" ] ; then \
		docker container stop $(CONTAINER_NAME) ; \
	else \
		echo 'no running $(CONTAINER_NAME) container' ; \
	fi
.PHONY: stop


# connect to running $(CONTAINER_NAME) container, start a bash shell
connect:
	docker exec -it $(CONTAINER_NAME) /bin/bash
.PHONY: connect


# execute commmand in CMD variable
execute:
	docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora $(IMAGE_NAME):latest $(CMD)
.PHONY: execute


# compile all corpora
compile:
	@make -s execute IMAGE_NAME=$(IMAGE_NAME) CMD=compile.sh
.PHONY: compile


# stop container, remove image, remove compiled corpora
clean:
	@make -s stop CONTAINER_NAME=$(CONTAINER_NAME)
	docker image rm $(IMAGE_NAME)
	sudo rm -vrf corpora/*/indexed/
.PHONY: clean
