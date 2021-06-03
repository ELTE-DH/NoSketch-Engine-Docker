#!/bin/bash

# compile corpora
for CORP_FILE in /corpora/registry/*; do
    echo "Running: compilecorp --no-ske ${CORP_FILE}";
    compilecorp --no-ske ${CORP_FILE} || exit $?;
done
