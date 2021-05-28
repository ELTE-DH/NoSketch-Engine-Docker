# From official stable-slim debian pinned by its name
FROM debian:buster-slim

# Update installation
RUN apt-get update && apt-get upgrade -y

# Install NoSketchEngine dependencies
RUN apt-get install -y build-essential swig libpcre++-dev python-dev libsass-dev libltdl-dev python-pip python-cheetah \
 python-setuptools python-simplejson apache2

# Install packages available only though pip
RUN pip install signalfd

# Enable apache CGI
RUN a2enmod cgi

# Copy installation packages
COPY noske_files/ /tmp/noske_files

# Install NoSketch Engine pkgs
## Manatee
RUN pwd && tar xf /tmp/noske_files/manatee-open-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/manatee-open-* && \
 ./configure PYTHON=python2 --with-pcre && make && make install && ldconfig

## Bonito
### HACK1 patch conccgi.py to handle large corpora
RUN tar xf /tmp/noske_files/bonito-open-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/bonito-open-* && \
 ./configure && make && make install && ./setupbonito /var/www/bonito /var/lib/bonito && \
 chown -R www-data:www-data /var/lib/bonito && \
 sed -i 's#wtr = int(words) / float(tokens)#wtr = float(words) / float(tokens)#' \
 /usr/local/lib/python2.7/dist-packages/bonito/conccgi.py

## GDEX
RUN tar xf /tmp/noske_files/gdex-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/gdex-* && python2 setup.py install

## Crystal
### HACK2 Modify shell in Makefile to bash to handle bashism
### HACK3 add user and chown node_modules directory for node-sass build
### HACK4 modify URL_BONITO to be set dynamically to the request domain in every request
RUN tar xf /tmp/noske_files/crystal-open-*.tar.gz -C /tmp/noske_files && cd /tmp/noske_files/crystal-open-*/ && \
 sed  -i '1i SHELL:=/bin/bash' Makefile && \
 useradd corpora && mkdir /home/corpora && chown -R corpora:corpora /home/corpora /tmp/noske_files/crystal-open-*/ && \
 su -l corpora -c "make -C /tmp/noske_files/crystal-open-*/" && \
 make install && \
 sed -i 's|URL_BONITO: "https://.*|URL_BONITO: window.location.origin + "/bonito/run.cgi/",|' \
 /var/www/crystal/config.js

# Copy configs and clean up
## 1. Copy Apache config, entrypoint file and patched run.cgi
## 2. Clean up
COPY conf/ /tmp/conf
RUN mv /tmp/conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf && \
 mv /tmp/conf/htpasswd /var/lib/bonito/htpasswd && \
 cp /tmp/conf/entrypoint.sh /usr/local/bin/ && cp /tmp/conf/run.cgi /var/www/bonito/ && \
 rm /var/www/bonito/.htaccess && \
 rm -rf /tmp/noske_files /tmp/conf

# Place corpora
COPY data /data
RUN ln -s /data/registry /data/corpora/registry
# COPY data /tmp/data
# RUN mv /tmp/data/corpora/* /home/corpora/ && mv /tmp/data/registry /home/registry && rm -rf /tmp/data && \
#  ln -s /home/corpora /corpora && ln -s /home/registry /home/corpora/registry


# # Compile corpora, fail on error
# RUN for CORP_FILE in /data/registry/*; do \
#         echo "Running: compilecorp --no-ske ${CORP_FILE}"; \
#         compilecorp --no-ske ${CORP_FILE} || exit $?; \
#     done

# Start the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "$@"]

EXPOSE 80
