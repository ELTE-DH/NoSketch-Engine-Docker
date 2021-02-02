# NoSketch Engine Docker based on Debian stable

## Build

1. Put vert file in: data/corpora/susanne/vertical
2. Put config in: data/registry/susanne
3. `docker build . -t nosketchengine`
4. `docker run -p80:80 nosketchengine`
