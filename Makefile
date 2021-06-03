all: build compile run
.PHONY: all

# pull:
# 	docker pull eltedh/nosketch-engine:latest
# .PHONY: pull


build:
	docker build -t noske .
.PHONY: build


# run noske image, mount corpora/ and use host port 10070
run:
	@make -s stop
	docker run -d --rm --name noske -p10070:80 --mount type=bind,src=$$(pwd)/corpora,dst=/corpora noske
	@echo 'URL: http://localhost:10070/crystal'
.PHONY: run


# stop running noske container
stop:
	@if [ "$$(docker container ls -f name=noske -q)" ] ; then \
		docker container stop noske ; \
	else \
		echo 'no running noske container' ; \
	fi
.PHONY: stop


# connect to running noske container
connect:
	@make -s run
	docker exec -it noske /bin/bash
.PHONY: connect


# compile all corpora
compile:
	@make -s run
	docker exec -it noske "/usr/local/bin/compile.sh"
	@make -s stop
.PHONY: compile


# stop container, remove image, remove compiled corpora
clean:
	@make -s stop
	# docker image rm noske
	sudo rm -vrf corpora/*/indexed/
.PHONY: clean
