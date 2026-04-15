#!/bin/bash

# If no params then start the server,
# else run the specified command from /usr/local/bin
if [ $# -eq 1 ]; then
    # Shibboleth requires these to be set properly!
    SERVER_NAME=${SERVER_NAME:="https://sketchengine.company.com/"}
    SERVER_ALIAS=${SERVER_ALIAS:="sketchengine.company.com"}
    CITATION_LINK=${CITATION_LINK:="https://github.com/elte-dh/NoSketch-Engine-Docker"}
    PRIVATE_KEY=${PRIVATE_KEY:=""}
    PUBLIC_KEY=${PUBLIC_KEY:=""}
    HTACCESS=${HTACCESS:=""}
    HTPASSWD=${HTPASSWD:=""}
    echo "Starting server with name (${SERVER_NAME}) and alias (${SERVER_ALIAS})."
    echo 'You can override these values with SERVER_NAME and SERVER_ALIAS environment variables.'
    sed -i "s#SERVER_NAME_PLACEHOLDER#${SERVER_NAME}#" /etc/apache2/sites-enabled/000-default.conf
    sed -i "s#SERVER_ALIAS_PLACEHOLDER#${SERVER_ALIAS}#" /etc/apache2/sites-enabled/000-default.conf
    sed -i "s#SERVER_NAME_PLACEHOLDER#${SERVER_NAME}#" /etc/shibboleth/shibboleth2.xml
    sed -i "s#CITATION_LINK_PLACEHOLDER#${CITATION_LINK}#" /var/www/crystal/bundle.js
    # ENV variables take precedence (note: The whitespace check prevents echo from adding a new line, which would make the file non-empty)
    # If ENV variable set with non-whitespace content or (the file is missing, empty, or contain whitespace characters only)
    if [[ "${PRIVATE_KEY}" =~ [^[:space:]] ]] || ! grep -q '[^[:space:]]' "/etc/shibboleth/sp.for.eduid.service.hu-key.crt" 2>/dev/null; then
        echo "${PRIVATE_KEY}" > /etc/shibboleth/sp.for.eduid.service.hu-key.crt
    fi
    chmod 644 /etc/shibboleth/sp.for.eduid.service.hu-key.crt
    if [[ "${PUBLIC_KEY}" =~ [^[:space:]] ]] || ! grep -q '[^[:space:]]' "/etc/shibboleth/sp.for.eduid.service.hu-cert.crt" 2>/dev/null; then
        echo "${PUBLIC_KEY}" > /etc/shibboleth/sp.for.eduid.service.hu-cert.crt
    fi
    chmod 644 /etc/shibboleth/sp.for.eduid.service.hu-cert.crt
    if [[ "${HTACCESS}" =~ [^[:space:]] ]] || ! grep -q '[^[:space:]]' "/var/www/.htaccess" 2>/dev/null; then
        echo "${HTACCESS}" > /var/www/.htaccess
    fi
    if [[ "${HTPASSWD}" =~ [^[:space:]] ]] || ! grep -q '[^[:space:]]' "/var/lib/bonito/htpasswd" 2>/dev/null; then
        echo "${HTPASSWD}" > /var/lib/bonito/htpasswd
    fi
    # Must be started after apache (only if cert and key are not empty)
    if grep -q '[^[:space:]]' "/etc/shibboleth/sp.for.eduid.service.hu-cert.crt" 2>/dev/null; then
        (sleep 5 && service shibd start && echo 'Shibd started.' || exit 1) &
    else
        # Skipping shibd start and disabling apache module and config to avoid degrading over time
        a2dismod shib
        a2disconf shib
    fi
    /usr/sbin/apache2ctl -D FOREGROUND
else
    shift
    "$@"
fi
