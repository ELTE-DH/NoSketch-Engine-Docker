# From official Debian 10 Buster image pinned by its name buster-slim
FROM debian:bullseye-slim


# Install noske dependencies
## deb packages
RUN apt-get update && \
    apt-get install -y \
        apache2 \
        libapache2-mod-shib \
        build-essential \
        libltdl-dev \
        libpcre++-dev \
        libsass-dev \
        python3-dev \
        python3-setuptools \
        file \
        swig


# Enable apache CGI and mod_rewrite
RUN a2enmod cgi rewrite shib


# Install noske components
ADD noske_files/* /tmp/noske_files/
WORKDIR /tmp/noske_files/

## Manatee
RUN cd manatee* && \
    ./configure --with-pcre && \
    make && \
    make install

## Bonito
### HACK1: patch conccgi.py to handle large corpora
RUN cd bonito* && \
    ./configure && \
    make && \
    make install && \
    ./setupbonito /var/www/bonito /var/lib/bonito && \
    chown -R www-data:www-data /var/lib/bonito

## GDEX
RUN cd gdex* && \
    sed -i "s/<version>/4.12/g" setup.py && \
    ./setup.py build && \
    ./setup.py install

## Crystal
### HACK2: Modify npm install command in Makefile to handle "permission denied"
### HACK3: Modify shell in Makefile to bash to handle bashism
### HACK4: modify URL_BONITO to be set dynamically to the request domain in every request
COPY conf/page-dashboard.tag /tmp/noske_files/
RUN sed  -i 's/npm install/npm install --unsafe-perm=true/' crystal*/Makefile && \
    cp page-dashboard.tag crystal*/app/src/dashboard/page-dashboard.tag && \
    cd crystal-* && \
    make && \
    make install VERSION=2.107 && \
    sed -i 's|URL_BONITO: "http://.*|URL_BONITO: window.location.origin + "/bonito/run.cgi/",|' \
        /var/www/crystal/config.js


# Remove unnecessary files and create symlink for utility command
RUN rm -rf /var/www/bonito/.htaccess /tmp/noske_files/* && \
    ln -sf /usr/bin/htpasswd /usr/local/bin/htpasswd


# Copy config files (These files contain placeholders replaced in entrypoint.sh according to environment variables)
COPY conf/*.sh /usr/local/bin/
COPY conf/run.cgi /var/www/bonito/run.cgi
COPY conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY conf/shibboleth2.xml /etc/shibboleth/shibboleth2.xml
COPY conf/*.crt /etc/shibboleth/

### These files should be updated through environment variables (HTACCESS,HTPASSWD,PUBLIC_KEY,PRIVATE_KEY)
# but uncommenting the lines below enable creation of a custom image with secrets included
# COPY secrets/htaccess /var/www/.htaccess
# COPY secrets/htpasswd /var/lib/bonito/htpasswd
# COPY secrets/*.crt /etc/shibboleth/

# Start the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "$@"]
EXPOSE 80
