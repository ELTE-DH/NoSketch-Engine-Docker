# NoSketch Engine Docker

This is a [dockerised](https://www.docker.com/) version of [NoSketch Engine](https://nlp.fi.muni.cz/trac/noske),
 the open source version of [Sketch Engine](https://www.sketchengine.eu/) corpus manager and text analysis software
 developed by [Lexical Computing Limited](https://www.lexicalcomputing.com/).

This docker image is based on Debian 10 Buster and
 [the NoSketch Engine build and installation process](https://nlp.fi.muni.cz/trac/noske#Buildandinstallation) contains
 some additional hacks for convenient install and use.
See [Dockerfile](Dockerfile) for details.

## TL;DR

1. `git clone https://github.com/ELTE-DH/NoSketch-Engine-Docker.git`
2. `make pull` – to download the docker image
3. `make compile` – to compile sample corpora
4. `make execute` – to execute a Sketch Engine command (`compilecorp`, `corpquery`, etc.) in the docker container
    (runs a test CLI query on `susanne` corpus by default)
5. `make run` – to launch the docker container
6. Navigate to `http://localhost:10070/` to try the WebUI

## Features

- Easy to add corpora (just add vertical file and registry file to the appropriate location,
   and compile the corpus with one command)
- CLI commands can be used directly (outside of the docker image)
- Works on any domain without changing configuration (without HTTPS and Shibboleth)
- Two example corpora included: [`susanne`](corpora/susanne)
   ([original NoSkE sample corpus](https://corpora.fi.muni.cz/noske/current/src/susanne-example-source.tar.bz2))
   and [`emagyardemo`](corpora/emagyardemo)
- (optional) Shibboleth SP (with eduid.hu)
- (optional) basic auth (updateable easily)
- (optional) HTTPS with Let's Encrypt (automatic renewal)

[Further info](corpora/emagyardemo/vertical/README.md) on how to analyse a plain text corpus by
 [e-magyar](https://github.com/nytud/emtsv) and convert it to the right format suitable to fit in the system.

## Usage

### 1. Get the Docker image

- Either pull the prebuilt image from [Dockerhub](https://hub.docker.com/r/eltedh/nosketch-engine): `make pull`
   (or `docker pull eltedh/nosketch-engine:latest`)
- Or build your own image yourself (the process can take 5 minutes or so): `make build IMAGE_NAME=myimage`– be sure 
   to name your image using the `IMAGE_NAME` parameter

### 2. Compile your corpus

1. Put vert file(s) in: `corpora/CORPUS_NAME/vertical` directory\
   (see examples in [`corpora/susanne/vertical`](corpora/susanne/vertical)
   and [`corpora/emagyardemo/vertical`](corpora/emagyardemo/vertical) directories)
2. Put config in: `corpora/registry/CORPUS_NAME` file\
   (see examples in [`corpora/registry/susanne`](corpora/registry/susanne)
   and [`corpora/registry/emagyardemo`](corpora/registry/emagyardemo))
3. Compile all corpora listed in [`corpora/registry`](corpora/registry) directory using the docker image: `make compile`
    - To compile _one_ corpus at a time (overwriting existing files), use the following command:
      `make execute CMD="compilecorp --no-ske --recompile-corpus CORPUS_REGISTRY_FILE"`
    - If you want to overwrite all existing indices automatically when running `make compile` set any value
       for `FORCE_RECOMPILE` env variable e.g. `make compile FORCE_RECOMPILE=y`

### 3a. Run the container

1. Run docker container: `make run`
2. Navigate to `http://SERVER_NAME:10070/` to use

### 3b. CLI Usage

- To run NoSketch Engine CLI commands run the docker image and add the desired command and its parameters
 (e.g. `corpinfo -s susanne`) at the end of the command:
    - `make execute CMD="corpinfo -s susanne"`
    - or:
       `docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora ${IMAGE_NAME}:latest corpinfo -s susanne`
- To get a shell to a running container use `make connect`

### 4. Additional commands

- `make stop`: stops the container
- `make clean`: stops the container, _removes indexed corpora_ and deletes docker image – __use with caution!__
- `make create-cert`: create self-signed certificate for Shibboleth (must restart a container to apply)
- `make remove-cert`: delete self-signed certificate files (must restart a container to apply)

## `make` parameters, multiple images and multiple containers

By default,
- the name of the docker image (`IMAGE_NAME`) is `eltedh/nosketch-engine`,
- the name of the docker container (`CONTAINTER_NAME`) is `noske`,
- the port number which the docker container uses (`PORT`) is `10070`,
- the variable to force recompiling already indexed coropra (`FORCE_RECOMPILE`) is not set
   (_empty_ or _not set_ means _false_ any other value means _true_),
- the citation link (`CITATION_LINK`) is `https://github.com/elte-dh/NoSketch-Engine-Docker`,
- the server name required for Let's Encrypt and/or Shibboleth (`SERVER_NAME`) is `https://sketchengine.company.com/`,
- the server alias required for Let's Encrypt and/or Shibboleth (`SERVER_ALIAS`) is `sketchengine.company.com`,
- the e-mail address required Let's Encrypt (`LETS_ENCRYPT_EMAIL`) is not set (mandatory for Let's Encrypt),
- the self-signed public and private keys (`PUBLIC_KEY`, `PRIVATE_KEY`) are loaded from
   ([conf/sp.for.eduid.service.hu-{cert,key}.crt](conf)) or empty if these files do not exist,
- the htaccess and htpasswd files (`HTACCESS`, `HTPASSWD`) are loaded from
   ([conf/{htaccess,htpasswd}](conf)) or empty if these files do not exist.

If there is a need to change these, set them as environment variables (e.g. `export IMAGE_NAME=myimage`)
 or supplement `make` commands with the appropriate values (e.g. `make run PORT=8080`).

E.g. `export IMAGE_NAME=myimage; make build` build an image called `myimage`; and
`make run IMAGE_NAME=myimage CONTAINER_NAME=mycontainer PORT=12345` launches the image called `myimage` in a container
 called `mycontainer` which will use port `12345`.
In the latter case the system will be availabe at `http://SERVER_NAME:12345/`.

See the table below on which `make` command accepts which parameter:

| command            | `IMAGE_NAME` | `CONTAINER_NAME` | `PORT` | `FORCE_RECOMPILE` | `USERNAME` | `PASSWORD` | The Other Variables |
|--------------------|:------------:|:----------------:|:------:|:-----------------:|------------|------------|:-------------------:|
| `make pull`        |       ✔      |         .        |    .   |         .         |      .     |      .     |          .          |
| `make build`       |       ✔      |         .        |    .   |         .         |      .     |      .     |          .          |
| `make compile`     |       ✔      |         .        |    .   |         ✔         |      .     |      .     |          .          |
| `make execute`     |       ✔      |         .        |    .   |         ✔         |      .     |      .     |          ✔          |
| `make run`         |       ✔      |         ✔        |    ✔   |         .         |      .     |      .     |          ✔          |
| `make connect`     |       .      |         ✔        |    .   |         .         |      .     |      .     |          .          |
| `make stop`        |       .      |         ✔        |    .   |         .         |      .     |      .     |          .          |
| `make clean`       |       ✔      |         ✔        |    .   |         .         |      .     |      .     |          .          |
| `make create-cert` |       .      |         .        |    .   |         .         |      .     |      .     |          .          |
| `make remove-cert` |       .      |         .        |    .   |         .         |      .     |      .     |          .          |
| `make htpasswd`    |       ✔      |         .        |    .   |         .         |      ✔     |      ✔     |          .          |

- The Other Variables are
    - `CITATION_LINK`
    - `SERVER_NAME` and `SERVER_ALIAS`
    - `PUBLIC_KEY` and `PRIVATE_KEY`
    - `HTACCESS` and `HTPASSWD`
-`LETS_ENCRYPT_EMAIL` variable is only used in `docker-compose.yml`.

In the rare case of _multiple different docker images_, be sure to name them differently (by using `IMAGE_NAME`).\
In the more common case of _multiple different docker containers_ running simultaneously,
be sure to name them differently (by using `CONTAINER_NAME`) and also be sure to use different port for each of them
 (by using `PORT`).

If you want to build your own docker image be sure to include the `IMAGE_NAME` parameter into the build command:
 `make build IMAGE_NAME=myimage` and also provide `IMAGE_NAME=myimage` for every `make` command
 which accepts this parameter.

## Authentication

Two types of authentication is supported basic auth and Shibboleth

### Basic auth

1. Uncomment relevant config lines in [`conf/htaccess`](conf/htaccess) and set user and password in
    [`conf/htpasswd`](conf/htpasswd)
    (e.g. use `make htpasswd USERNAME="USERNAME" PASSWORD="PASSWD" >> conf/htpasswd` shortcut 
    or `htpasswd` from `apache2-utils` package)
2. [Run or restart the container to apply](#3a-run-the-container) or
    [(re)build your custom image](#1-get-the-docker-image)

### Shibboleth

To be able to use the container as a Shibboleth SP (with eduid.hu)

1. Set the following environment variables:
    - `SERVER_NAME`  e.g. `export SERVER_NAME="https://sketchengine.company.com/"`
    - `SERVER_ALIAS`e.g. `export SERVER_ALIAS="sketchengine.company.com"`
2. Obtain a self-sgined certificate:
    - `make create-cert` to create a new certificate
    - Or put your files to conf/sp.for.eduid.service.hu-cert.crt and conf/sp.for.eduid.service.hu-key.crt with
       appropriate permissions (`chmod 644 conf/sp.for.eduid.service.hu-cert.crt conf/sp.for.eduid.service.hu-key.crt`)
3. Build docker image
4.  [Setup HTTPS](https-with-lets-encrypt)
5.  Register your SP with your IdP

## HTTPS with Let's Encrypt

1. Build docker image
2. Set the environment variables:
    - `LETS_ENCRYPT_EMAIL` e.g. `export LETS_ENCRYPT_EMAIL="contact@company.com"`
    - `SERVER_NAME`  e.g. `export SERVER_NAME="https://sketchengine.company.com/"`
    - `SERVER_ALIAS`e.g. `export SERVER_ALIAS="sketchengine.company.com"`
    - (optional) `IMAGE_NAME`, `PORT` and `CONTAINER_NAME`
3. `docker-compose up -d`

## Citation link

You can set a link to your publications which you require to cite.
Set `CITATION_LINK` e.g. `export CITATION_LINK="https://LINK_GOES_HERE"` or in [docker-compose.yml](docker-compose.yml).

The link is displayed in the lower-right corner of the main dashboard if any type of authentication is set.

## License

The following files in this repository are from https://nlp.fi.muni.cz/trac/noske and have their own license:
- `noske_files/manatee-open-*.tar.gz` (GPLv2+)
- `noske_files/bonito-open-*.tar.gz` (GPLv2+)
- `noske_files/crystal-open-*.tar.gz` (GPLv3)
- `noske_files/gdex-*.tar.gz` (GPLv3)
- Susanne sample corpus: `data/corpora/susanne/vertical` and `data/registry/susanne`

The rest of the files are licensed under the Lesser GNU GPL version 3 or any later.
