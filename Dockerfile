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
### HACK2: Modify npm install command in Makefile to handle "permission denied"
### HACK3: Modify shell in Makefile to bash to handle bashism
### HACK4: modify URL_BONITO to be set dynamically to the request domain in every request
RUN sed  -i 's/npm install/npm install --unsafe-perm=true/' crystal*/Makefile && \
    make -C crystal*/ install SHELL=/bin/bash && \
    sed -i 's|URL_BONITO: "https://.*|URL_BONITO: window.location.origin + "/bonito/run.cgi/",|' \
        /var/www/crystal/config.js


# Remove unnecessary files
RUN rm -rf /var/www/bonito/.htaccess /tmp/noske_files/*


# Copy config files
COPY conf/*.sh /usr/local/bin/
COPY conf/run.cgi /var/www/bonito/
COPY conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY conf/htpasswd /var/lib/bonito/htpasswd

# Start the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "$@"]
EXPOSE 80
