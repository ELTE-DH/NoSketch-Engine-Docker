# From official stable-slim debian pinned by its name
FROM debian:buster-slim


# Install noske dependencies

## deb packages
RUN apt-get update && \
    apt-get install -y \
        apache2 \
        build-essential \
        libltdl-dev \
        libpcre++-dev \
        libsass-dev \
        python-cheetah \
        python-dev \
        python-pip \
        python-setuptools \
        python-simplejson \
        swig

## python packages
RUN pip install signalfd


# Enable apache CGI
RUN a2enmod cgi


# Install noske components
ADD noske_files/* /tmp/noske_files/
WORKDIR /tmp/noske_files/

## Manatee
RUN cd manatee* && \
    ./configure PYTHON=python2 --with-pcre && \
    make && \
    make install && \
    ldconfig

## Bonito
### HACK1: patch conccgi.py to handle large corpora
RUN cd bonito* && \
    ./configure && \
    make && \
    make install && \
    ./setupbonito /var/www/bonito /var/lib/bonito && \
    chown -R www-data:www-data /var/lib/bonito && \
    sed -i 's#wtr = int(words) / float(tokens)#wtr = float(words) / float(tokens)#' \
    /usr/local/lib/python2.7/dist-packages/bonito/conccgi.py

## GDEX
RUN cd gdex* && \
    python2 setup.py install

## Crystal
### HACK2: Modify shell in Makefile to bash to handle bashism
### HACK3: add user and chown node_modules directory for node-sass build
### HACK4: modify URL_BONITO to be set dynamically to the request domain in every request
RUN cd crystal* && \
    sed  -i '1i SHELL:=/bin/bash' Makefile && \
    useradd corpora && \
    mkdir /home/corpora && \
    chown -R corpora:corpora /home/corpora /tmp/noske_files/crystal*/ && \
    su -l corpora -c "make -C /tmp/noske_files/crystal*/" && \
    make install && \
    sed -i 's|URL_BONITO: "https://.*|URL_BONITO: window.location.origin + "/bonito/run.cgi/",|' /var/www/crystal/config.js


COPY conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY conf/htpasswd /var/lib/bonito/htpasswd
COPY conf/*.sh /usr/local/bin/
COPY conf/run.cgi /var/www/bonito/

RUN rm -rf /var/www/bonito/.htaccess /tmp/noske_files/*


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO:
# Place corpora
# COPY data /data
# RUN ln -s /data/registry /data/corpora/registry
# COPY data /tmp/data
# RUN mv /tmp/data/corpora/* /home/corpora/ && \
#     mv /tmp/data/registry /home/registry && \
#     rm -rf /tmp/data && \
#     ln -s /home/corpora /corpora && \
#     ln -s /home/registry /home/corpora/registry
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Start the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "$@"]

EXPOSE 80
