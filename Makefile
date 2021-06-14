PORT=10070

all: build compile run
.PHONY: all

# pull:
# 	docker pull eltedh/nosketch-engine:latest
# .PHONY: pull


build:
	docker build -t noske .
.PHONY: build


# run noske image, mount corpora/ and use host port $PORT
run:
	@make -s stop
	docker run -d --rm --name noske -p$(PORT):80 --mount type=bind,src=$$(pwd)/corpora,dst=/corpora noske:latest
	@echo 'URL: http://localhost:$(PORT)/crystal'
.PHONY: run


# stop running noske container
stop:
	@if [ "$$(docker container ls -f name=noske -q)" ] ; then \
		docker container stop noske ; \
	else \
		echo 'no running noske container' ; \
	fi
.PHONY: stop


# connect to running noske container, start a bash shell
connect:
	docker exec -it noske /bin/bash
.PHONY: connect


# compile all corpora
compile:
	docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora noske:latest compile.sh
.PHONY: compile


# test command line usage
test_cli:
	docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora noske:latest corpquery susanne '[word="Mardi"][word="Gras"]'
	docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora noske:latest corpinfo -s susanne
.PHONY: test_cli


# stop container, remove image, remove compiled corpora
clean:
	@make -s stop
	# docker image rm noske
	sudo rm -vrf corpora/*/indexed/
.PHONY: clean
