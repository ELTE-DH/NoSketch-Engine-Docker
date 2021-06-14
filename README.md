# NoSketch Engine Docker

This is a dockerised version of [NoSketch Engine](https://nlp.fi.muni.cz/trac/noske), the open source version of [Sketch Engine](https://www.sketchengine.eu/) corpus manager and text analysis software developed by [Lexical Computing Limited](https://www.lexicalcomputing.com/).

This docker image is based on Debian stable and [the NoSketch Engine build and installation process](https://nlp.fi.muni.cz/trac/noske#Buildandinstallation) contains some additional hacks for convenient install and use.
See [Dockerfile](Dockerfile) for details

## Features

- Easy to add corpora (just add vertical file and registry file to the appropriate location, and finally compile the coprus)
- CLI commands can be used directly (outside of the docker image)
- Works on any domain without changing configuration
- Two example corpora included: [`susanne` (original NoSkE sample corpus)](https://corpora.fi.muni.cz/noske/current/src/susanne-example-source.tar.bz2) and [`emagyardemo`](corpora/emagyardemo).

[Further info](corpora/emagyardemo/vertical/README.md) on how to create an [e-magyar](https://github.com/nytud/emtsv)-analysed corpus from plain `txt` and put in the system

## Usage

1. Put vert file(s) in: `corpora/CORPUS_NAME/vertical` directory (see examples in `corpora/*/vertical`)
2. Put config in: `corpora/registry/CORPUS_NAME` file (see examples in `corpora/registry/*`)
3. (Optional: password authentication) Uncomment relevant config lines in `conf/000-default.conf` and set user and password in `conf/htpasswd` (e.g. use `htpasswd -c conf/htpasswd USERNAME` command from apache2-utils)
4. Build docker image: `make build`  (can run for 5 minutes or so) (optionally one can set the name of the image and container with `IMAGE_NAME` variable: `make build IMAGE_NAME=noske`)
5. Compile all corpora: `make compile` (one must add `IMAGE_NAME` variable if it was used in the previous step: `make compile IMAGE_NAME=noske`)
6. Run docker container: `make run` (optionally with `PORT=DESIRED_PORT_NUMBER` and `IMAGE_NAME` if it were used previously)
7. Navigate to http://localhost:10070/crystal/ to use

## CLI Usage

- To run NoSketch Engine CLI commands run the docker and add the desired command and its parameters (e.g. `corpinfo -s susanne`) at the end of the command:
    - `docker run --rm -it --mount type=bind,src=$$(pwd)/corpora,dst=/corpora ${IMAGE_NAME}:latest corpinfo -s susanne`
    - Or with shortcut: `make execute CMD="corpinfo -s susanne"`
- To get a shell to a running container named "noske" use `make connect`.

## Demo on Dockerhub

The prebuilt docker image with the sample corpora included is [available on dockerhub](https://hub.docker.com/r/eltedh/nosketch-engine):

```bash
docker pull eltedh/nosketch-engine:latest
docker run --rm --name noske -p80:80 eltedh/nosketch-engine:latest
```

# License

The following files in this repository are from https://nlp.fi.muni.cz/trac/noske and have their own license:
- `noske_files/manatee-open-*.tar.gz` (GPLv2+)
- `noske_files/bonito-open-*.tar.gz` (GPLv2+)
- `noske_files/crystal-open-*.tar.gz` (GPLv3)
- `noske_files/gdex-*.tar.gz` (GPLv3)
- Susanne sample corpus: `data/corpora/susanne/vertical` and `data/registry/susanne`

The rest of the files are licensed under the Lesser GNU GPL version 3 or any later.
