# NoSketch Engine Docker

This is a dockerised version of [NoSketch Engine](https://nlp.fi.muni.cz/trac/noske), the open source version of [Sketch Engine](https://www.sketchengine.eu/) corpus manager and text analysis software developed by [Lexical Computing Limited](https://www.lexicalcomputing.com/).

This docker image is based on Debian stable and [the NoSketch Engine build and installation process](https://nlp.fi.muni.cz/trac/noske#Buildandinstallation) contains some additional hacks for convenient install and use.
See [Dockerfile](Dockerfile) for details.

## TL;DR

 1. `git clone https://github.com/ELTE-DH/NoSketch-Engine-Docker`
 2. `make pull` – to download the docker image
 3. `make compile` – to compile sample corpora
 4. `make execute` – to run a CLI query on `susanne` corpus
 5. `make run` – to launch the docker container 
 6. Navigate to `http://localhost:10070/` to try the WebUI

## Features

- Easy to add corpora (just add vertical file and registry file to the appropriate location, and compile the corpus with one command)
- CLI commands can be used directly (outside of the docker image)
- Works on any domain without changing configuration
- Two example corpora included: [`susanne`](corpora/susanne) ([original NoSkE sample corpus](https://corpora.fi.muni.cz/noske/current/src/susanne-example-source.tar.bz2)) and [`emagyardemo`](corpora/emagyardemo)

[Further info](corpora/emagyardemo/vertical/README.md) on how to analyse a plain text corpus by [e-magyar](https://github.com/nytud/emtsv) and convert it to the right format suitable to fit in the system.

## Usage

### 1. Get the Docker image

- Either pull the prebuilt image from [Dockerhub](https://hub.docker.com/r/eltedh/nosketch-engine): `make pull` (or `docker pull eltedh/nosketch-engine:latest`)
- Or build your own image yourself (the process can take 5 minutes or so): `make build IMAGE_NAME=myimage` – be sure to name your image using the `IMAGE_NAME` parameter
    - Optional: enable __password authentication__: Uncomment relevant config lines in [`conf/000-default.conf`](conf/000-default.conf) and set user and password in [`conf/htpasswd`](conf/htpasswd) (e.g. use `htpasswd -c conf/htpasswd USERNAME` command from `apache2-utils` package)

### 2. Compile your corpus

1. Put vert file(s) in: `corpora/CORPUS_NAME/vertical` directory\
(see examples in [`corpora/susanne/vertical`](corpora/susanne/vertical) and [`corpora/emagyardemo/vertical`](corpora/emagyardemo/vertical) directories)
2. Put config in: `corpora/registry/CORPUS_NAME` file\
(see examples in [`corpora/registry/susanne`](corpora/registry/susanne) and [`corpora/registry/emagyardemo`](corpora/registry/emagyardemo))
3. Compile all corpora listed in [`corpora/registry`](corpora/registry) directory using the docker image: `make compile`
    - To compile _one_ corpus at a time, use the following command: `make execute CMD="compilecorp --no-ske CORPUS_REGISTRY_FILE"`

### 3a. Run the container

1. Run docker container: `make run`
2. Navigate to `http://SERVER_NAME:10070/` to use

### 3b. CLI Usage

- To run NoSketch Engine CLI commands run the docker image and add the desired command and its parameters (e.g. `corpinfo -s susanne`) at the end of the command:
    - `make execute CMD="corpinfo -s susanne"`
    - or: `docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora ${IMAGE_NAME}:latest corpinfo -s susanne`
- To get a shell to a running container use `make connect`

### 4. Additional commands

- `make stop`: stops the container
- `make clean`: stops the container, removes indexed corpora and deletes docker image – __use with caution!__

## `make` parameters, multiple images and multiple containers

By default,
 * the name of the docker image is `nosketch-engine`,
 * the name of the docker container is `noske`,
 * the port which the docker container uses is `10070`.

If there is a need to change these, `make` commands can be supplemented
by `IMAGE_NAME=myimage` and/or `CONTAINTER_NAME=mycontainer` and/or `PORT=myport`.

E.g. `make build IMAGE_NAME=myimage` build an image called `myimage`; and
`make run IMAGE_NAME=myimage CONTAINER_NAME=mycontainer PORT=12345` launches the image called `myimage` in a container called `mycontainer` which will use port `12345`.
In the latter case the system will be availabe at `http://SERVER_NAME:12345/`.

See the table below on which `make` command accepts which parameter:

|command|`IMAGE_NAME`|`CONTAINER_NAME`|`PORT`|
|---|:-:|:-:|:-:|
|`make pull`|.|.|.|
|`make build`|✔|.|.|
|`make compile`|✔|.|.|
|`make execute`|✔|.|.|
|`make run`|✔|✔|✔|
|`make connect`|.|✔|.|
|`make stop`|.|✔|.|
|`make clean`|✔|✔|.|

In the rare case of multiple different docker images, be sure to name them differently (by using `IMAGE_NAME`).\
In the more common case of multiple different docker containers running simultaneously,
be sure to name them differently (by using `CONTAINER_NAME`) and also be sure to use different port for each of them (by using `PORT`).

If you want to build your own docker image be sure to include the `IMAGE_NAME` parameter into the build command: `make build IMAGE_NAME=myimage` and also provide `IMAGE_NAME=myimage` for every `make` command which accepts this parameter.

## License

The following files in this repository are from https://nlp.fi.muni.cz/trac/noske and have their own license:
- `noske_files/manatee-open-*.tar.gz` (GPLv2+)
- `noske_files/bonito-open-*.tar.gz` (GPLv2+)
- `noske_files/crystal-open-*.tar.gz` (GPLv3)
- `noske_files/gdex-*.tar.gz` (GPLv3)
- Susanne sample corpus: `data/corpora/susanne/vertical` and `data/registry/susanne`

The rest of the files are licensed under the Lesser GNU GPL version 3 or any later.
