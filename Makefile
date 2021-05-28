all:
	@echo 'all'
.PHONY: all

# pull:
# 	docker pull eltedh/nosketch-engine:latest
# .PHONY: pull


build:
	docker build -t mynoske .
.PHONY: build

run:
	docker run --rm --name noske -p10070:80 mynoske
.PHONY: run

# kb ide kene eljutni:
# run:
# 	docker run --rm --name noske -p11070:80 --mount type=bind,src=$$(pwd)/data,dst=/data eltedh/nosketch-engine
# .PHONY: run

connect:
	docker exec -it noske /bin/bash
.PHONY: connect

