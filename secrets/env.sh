#!/bin/bash

# SOURCE THIS FILE TO LOAD (EXPORT) VARIABLES TO THE ENVIRONMENT: source env.sh
# Here we can use bash's advanced variable interpolation magic to set variables in contrast to docker-compose's

PORT=10070
IMAGE_NAME=eltedh/nosketch-engine
CONTAINER_NAME=noske
SERVER_NAME=https://sketchengine.company.com/
SERVER_ALIAS=sketchengine.company.com
CITATION_LINK=https://github.com/elte-dh/NoSketch-Engine-Docker
PRIVATE_KEY=$(cat secrets/sp.for.eduid.service.hu-key.crt 2> /dev/null)
PUBLIC_KEY=$(cat secrets/sp.for.eduid.service.hu-cert.crt 2> /dev/null)
HTACCESS=$(cat secrets/htaccess 2> /dev/null)
HTPASSWD=$(cat secrets/htpasswd 2> /dev/null)
LETS_ENCRYPT_EMAIL=dummy@email.com

if [[ ! -z "$VERBOSE" ]]; then
    echo "Setting (updating) the following environment variables:"
    echo
    echo "PORT=${PORT}"
    echo "IMAGE_NAME=${IMAGE_NAME}"
    echo "CONTAINER_NAME=${CONTAINER_NAME}"
    echo "SERVER_NAME=${SERVER_NAME}"
    echo "SERVER_ALIAS=${SERVER_ALIAS}"
    echo "CITATION_LINK=${CITATION_LINK}"
    echo "PRIVATE_KEY=${PRIVATE_KEY}"
    echo "PUBLIC_KEY=${PUBLIC_KEY}"
    echo "HTACCESS=${HTACCESS}"
    echo "HTPASSWD=${HTPASSWD}"
    echo "LETS_ENCRYPT_EMAIL=${LETS_ENCRYPT_EMAIL}"
    echo
    echo "End of list"
fi
