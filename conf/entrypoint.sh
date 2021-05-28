#!/bin/bash

# compile corpora
for CORP_FILE in /data/registry/*; do
    echo "Running: compilecorp --no-ske ${CORP_FILE}";
    compilecorp --no-ske ${CORP_FILE} || exit $?;
done

# If no params start the server,
# else run the specified command from /usr/local/bin
if [ $# -eq 1 ]; then
    echo "Done. Starting server."
    /usr/sbin/apache2ctl -D FOREGROUND
else
    shift
    /usr/local/bin/$@
fi
