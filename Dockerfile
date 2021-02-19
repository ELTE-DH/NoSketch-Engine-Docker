# From official stable-slim debian pinned by its name
FROM debian:buster-slim

# Update installation
RUN apt-get update && apt-get upgrade -y

# Install NoSketchEngine dependencies
RUN apt-get install -y build-essential swig libpcre++-dev python-dev libsass-dev libltdl-dev python-pip python-cheetah python-setuptools python-simplejson apache2

# Install packages available only though pip
RUN pip install signalfd

# Enable apache CGI
RUN a2enmod cgi

# Copy installation packages
COPY noske_files/ /tmp/noske_files

# Install NoSketch Engine pkgs
# Manatee 
RUN pwd && tar xf /tmp/noske_files/manatee-open-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/manatee-open-* && ./configure PYTHON=python2 --with-pcre && make && make install && ldconfig

# Bonito
RUN tar xf /tmp/noske_files/bonito-open-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/bonito-open-* && ./configure && make && make install && ./setupbonito /var/www/bonito /var/lib/bonito && chown -R www-data:www-data /var/lib/bonito

# GDEX
RUN tar xf /tmp/noske_files/gdex-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/gdex-* && python2 setup.py install

# Crystal
# HACK1 Modify shell in Makefile to bash to handle bashism
# HACK2 add user and chown node_modules directory for node-sass build
RUN tar xf /tmp/noske_files/crystal-open-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/crystal-open-*/ && \
 sed  -i '1i SHELL:=/bin/bash' Makefile && \
 useradd corpora && mkdir /home/corpora && chown -R corpora:corpora /home/corpora /tmp/noske_files/crystal-open-*/ && su -l corpora -c "make -C /tmp/noske_files/crystal-open-*/" && \
 make install

# Clean Up
RUN rm -rf /tmp/noske_files

# Copy Apache config
COPY conf/000-default.conf /etc/apache2/sites-enabled/
COPY conf/htpasswd /var/lib/bonito/htpasswd
RUN rm /var/www/bonito/.htaccess && sed -i 's|URL_BONITO: "https://.*|URL_BONITO: window.location.origin + "/bonito/run.cgi/",|' /var/www/crystal/config.js

# Copy entrypoint file and patched run.cgi
COPY conf/entrypoint.sh /usr/local/bin/
COPY conf/run.cgi /var/www/bonito/

# Place corpora
RUN mkdir -p /home/corpora
COPY data/corpora /home/corpora
RUN mkdir /home/registry
COPY data/registry /home/registry

# Compile corpora, fail on error
RUN for CORP_FILE in /home/registry/*; do \
        echo "Running: encodevert -xrvc ${CORP_FILE}"; \
        compilecorp --no-ske ${CORP_FILE} || exit $?; \
    done

# Start the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "$@"]

EXPOSE 80
