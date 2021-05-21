# NoSketch Engine Docker

This is a dockerised version of [NoSketch Engine](https://nlp.fi.muni.cz/trac/noske), the open source version of [Sketch Engine](https://www.sketchengine.eu/) corpus manager and text analysis software developed by [Lexical Computing Limited](https://www.lexicalcomputing.com/).

This docker image is based on Debian stable with some additional hacks for convenient install and use of the software.

## Features

- Easy to add corpora (just add vertical file and registry file to he appropriate location and rebuild the docker)
- CLI commands can be used directly (outside of the docker image)
- Works on any domain without changing configuration
- Two example corpora included: `susanne` (original NoSkE sample corpus) and `emagyardemo`.

[Further info](data/corpora/emagyardemo/vertical/README.md) on how to create an [e-magyar](https://github.com/nytud/emtsv)-analysed corpus from plain `txt` and put in the system.

## Usage

1. Put vert file in: `data/corpora/CORPUS_NAME/vertical` (see example in `data/corpora/*/vertical`)
2. Put config in: `data/registry/CORPUS_NAME` (see example in `data/registry/*`)
3. (Optional: password authentication) Uncomment relevant config lines in `conf/000-default.conf` and set user and password in `conf/htpasswd`   
4. `docker build . -t nosketch_engine` (can run for 5 minutes or something)
5. `docker run --rm --name noske -p80:80 nosketch_engine`
6. Navigate to http://DOMAIN/crystal/ to use

## CLI Usage

- To run NoSketch Engine CLI commands run the docker and add the command and its parameters at the end of the original command (`docker run -it nosketch_engine COMMAND PARAMS`). E.g. `docker run -it nosketch_engine encodevert -h` 
- To get a shell in the container use the following command: `docker run -p80:80 -it --entrypoint /bin/bash nosketch_engine`

## Demo on Dockerhub

The docker image with the sample corpus included is [available on dockerhub](https://hub.docker.com/r/eltedh/nosketch-engine):

```bash
docker pull eltedh/nosketch-engine
docker run --rm --name noske -p80:80 eltedh/nosketch-engine
```

# License

The following files in this repository are from https://nlp.fi.muni.cz/trac/noske and have their own license:
- `noske_files/manatee-open-*.tar.gz` (GPLv2+)
- `noske_files/bonito-open-*.tar.gz` (GPLv2+)
- `noske_files/crystal-open-*.tar.gz` (GPLv3)
- `noske_files/gdex-*.tar.gz` (GPLv3)
- Susanne sample corpus: `data/corpora/susanne/vertical` and `data/registry/susanne`

The rest of the files are licensed under the Lesser GNU GPL version 3 or any later.
