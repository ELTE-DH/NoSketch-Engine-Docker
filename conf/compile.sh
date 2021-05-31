#!/bin/bash

# compile corpora
for CORP_FILE in /data/registry/*; do
    echo "Running: compilecorp --no-ske ${CORP_FILE}";
    compilecorp --no-ske ${CORP_FILE} || exit $?;
done
