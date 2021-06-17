# NoSketch Engine Docker

This is a dockerised version of [NoSketch Engine](https://nlp.fi.muni.cz/trac/noske), the open source version of [Sketch Engine](https://www.sketchengine.eu/) corpus manager and text analysis software developed by [Lexical Computing Limited](https://www.lexicalcomputing.com/).

This docker image is based on Debian stable and [the NoSketch Engine build and installation process](https://nlp.fi.muni.cz/trac/noske#Buildandinstallation) contains some additional hacks for convenient install and use.
See [Dockerfile](Dockerfile) for details

## TL;DR

 1. `git clone https://github.com/ELTE-DH/NoSketch-Engine-Docker`
 2. `make build` – to create the Docker image (5 minutes)
 3. `make compile` – to compile sample corpora
 4. `make run` – to launch the Docker container
 5. `make execute` – to run a CLI query on `susanne` corpus
 6. navigate to `http://localhost:10070/crystal` to try the GUI

## Features

- Easy to add corpora (just add vertical file and registry file to the appropriate location, and compile the corpus with one command)
- CLI commands can be used directly (outside of the docker image)
- Works on any domain without changing configuration
- Two example corpora included: [`susanne`](corpora/susanne) ([original NoSkE sample corpus](https://corpora.fi.muni.cz/noske/current/src/susanne-example-source.tar.bz2)) and [`emagyardemo`](corpora/emagyardemo)

[Further info](corpora/emagyardemo/vertical/README.md) on how to analyse a plain text corpus by [e-magyar](https://github.com/nytud/emtsv) and convert it to the right format suitable to fit in the system.

## Usage

### 1. Get the Docker image

- Either pull the prebuilt image from [Dockerhub](https://hub.docker.com/r/eltedh/nosketch-engine): `docker pull eltedh/nosketch-engine:latest` or `make pull`
- Or build the image yourself (the process can take 5 minutes or so): `make build`
    - Optional: __set different name for the image__ with `IMAGE_NAME` variable: `make build IMAGE_NAME=myimage` (default: `nosketch-engine`)
    - Optional: enable __password authentication__: Uncomment relevant config lines in [`conf/000-default.conf`](conf/000-default.conf) and set user and password in [`conf/htpasswd`](conf/htpasswd) (e.g. use `htpasswd -c conf/htpasswd USERNAME` command from `apache2-utils` package)

### 2. Compile your corpus

1. Put vert file(s) in: `corpora/CORPUS_NAME/vertical` directory (see examples in [`corpora/susanne/vertical`](corpora/susanne/vertical) and [`corpora/emagyardemo/vertical`](corpora/emagyardemo/vertical) directories)
2. Put config in: `corpora/registry/CORPUS_NAME` file (see examples in [`corpora/registry/susanne`](corpora/registry/susanne) and [`corpora/registry/emagyardemo`](corpora/registry/emagyardemo))
3. Compile all corpora listed in [`corpora/registry`](corpora/registry) directory: `make compile` (one must add `IMAGE_NAME` variable if it differs from the default: `make compile IMAGE_NAME=myimage`)
    - To compile one corpus only, use the following command: `make execute CMD="compilecorp --no-ske CORP_REGISTRY_FILE"` (one must add `IMAGE_NAME` variable if it differs from the default: `make execute IMAGE_NAME=myimage CMD="compilecorp --no-ske CORP_REGISTRY_FILE"`)

### 3a. Run the container

1. Run docker container: `make run` (one must add `IMAGE_NAME` variable if it differs from the default: `make run IMAGE_NAME=myimage`)
    - Optional: __set different container name__ with `CONTAINER_NAME` variable: `make run CONTAINER_NAME=mycontainer` (default: `noske`)
    - Optional: __set different port__ with `PORT=DESIRED_PORT_NUMBER` variable: `make run PORT=12345` (default: `10070`)
2. Navigate to http://SERVER_NAME:PORT/ to use

## 3b. CLI Usage

- To run NoSketch Engine CLI commands run the docker and add the desired command and its parameters (e.g. `corpinfo -s susanne`) at the end of the command:
    - `docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora ${IMAGE_NAME}:latest corpinfo -s susanne`
    - Or with shortcut: `make execute CMD="corpinfo -s susanne"` (one must add `IMAGE_NAME` variable if it differs from the default: `make execute IMAGE_NAME=myimage CMD="corpinfo -s susanne"`)
- To get a shell to a running container use `make connect` (one must add `CONTAINER_NAME` variable if it differs from the default: `make connect CONTAINER_NAME=mycontainer`)

## Additional commands

- `make stop` (one must add `CONTAINER_NAME` variable if it differs from the default: `make stop CONTAINER_NAME=mycontainer`): stops the container
- `make clean`(one must add `IMAGE_NAME` and `CONTAINER_NAME` variables if they differ from the default: `make stop IMAGE_NAME=myimage CONTAINER_NAME=mycontainer`): stops the container removes indexed corpora and docker image

# License

The following files in this repository are from https://nlp.fi.muni.cz/trac/noske and have their own license:
- `noske_files/manatee-open-*.tar.gz` (GPLv2+)
- `noske_files/bonito-open-*.tar.gz` (GPLv2+)
- `noske_files/crystal-open-*.tar.gz` (GPLv3)
- `noske_files/gdex-*.tar.gz` (GPLv3)
- Susanne sample corpus: `data/corpora/susanne/vertical` and `data/registry/susanne`

The rest of the files are licensed under the Lesser GNU GPL version 3 or any later.
