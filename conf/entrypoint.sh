#!/bin/bash

# If no params start the server,
# else run the specified command from /usr/local/bin
if [ $# -eq 1 ]; then
    # Shibboleth requires these to be set properly!
    SERVER_NAME=${SERVER_NAME:="https://sketchengine.company.com/"}
    SERVER_ALIAS=${SERVER_ALIAS:="sketchengine.company.com"}
    echo "Done. Starting server with name (${SERVER_NAME}) and alias (${SERVER_ALIAS})."
    echo 'You can override these values with ${SERVER_NAME} and ${SERVER_ALIAS} environment variables.'
    sed -i "s#SERVER_NAME_PLACEHOLDER#${SERVER_NAME}#" /etc/apache2/sites-enabled/000-default.conf
    sed -i "s#SERVER_ALIAS_PLACEHOLDER#${SERVER_ALIAS}#" /etc/apache2/sites-enabled/000-default.conf
    sed -i "s#SERVER_NAME_PLACEHOLDER#${SERVER_NAME}#" /etc/shibboleth/shibboleth2.xml
    # Must be started after apache
    (sleep 5 && service shibd start && echo 'Shibd started.') &
    /usr/sbin/apache2ctl -D FOREGROUND
else
    shift
    /usr/local/bin/$@
fi
