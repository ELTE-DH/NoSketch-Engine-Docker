#!/bin/bash

if [[ -n "$(ls /corpora/*/indexed 2> /dev/null)" ]]; then
    echo 'WARNING: This will delete all indices and recompile all coropra!' >&2
    if [[ -n "$FORCE_RECOMPILE" ]]; then
        echo 'INFO: Continuing in force recompile mode' >&2
    else
        echo 'Do you want to continue? [y/N]' >&2
        read -N1 ans
        echo
        if [[ ! "${ans:-N}" =~ ^[yY] ]]; then
            echo "To recompile a specific corpus, run" \
             "'make execute CMD=\"compilecorp --no-ske --recompile-corpus CORPUS_REGISTRY_FILE\"' instead." >&2
            exit 1
        fi
    fi
fi

# Compile corpora
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.9/site-packages
for CORP_FILE in /corpora/registry/*; do
    echo "Running: compilecorp --no-ske --recompile-corpus ${CORP_FILE}" >&2;
    compilecorp --no-ske --recompile-corpus ${CORP_FILE} || exit $?;
done
