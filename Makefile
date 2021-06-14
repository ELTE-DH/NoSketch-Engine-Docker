PORT=10070
CMD=corpquery susanne '[word="Mardi"][word="Gras"]'
IMAGE_NAME=nosketch-engine


all: build compile run
.PHONY: all


pull:
	docker pull eltedh/nosketch-engine:latest
.PHONY: pull


build:
	docker build -t $(IMAGE_NAME) .
.PHONY: build


# run $(IMAGE_NAME) image, mount corpora/ and use host port $PORT
run:
	@make -s stop
	docker run -d --rm --name $(IMAGE_NAME) -p$(PORT):80 --mount type=bind,src=$$(pwd)/corpora,dst=/corpora \
	    $(IMAGE_NAME):latest
	@echo 'URL: http://localhost:$(PORT)/crystal'
.PHONY: run


# stop running $(IMAGE_NAME) container
stop:
	@if [ "$$(docker container ls -f name=$(IMAGE_NAME) -q)" ] ; then \
		docker container stop $(IMAGE_NAME) ; \
	else \
		echo 'no running $(IMAGE_NAME) container' ; \
	fi
.PHONY: stop


# connect to running $(IMAGE_NAME) container, start a bash shell
connect:
	docker exec -it $(IMAGE_NAME) /bin/bash
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
	@make -s stop
	docker image rm $(IMAGE_NAME)
	sudo rm -vrf corpora/*/indexed/
.PHONY: clean
