FROM debian:stable-slim


#Update installation
RUN apt-get update && apt-get upgrade -y

# python python-cheetah python-simplejson libltdl7
#Install NoSketchEngine dependencies
RUN apt-get install -y build-essential swig libpcre++-dev python-dev libsass-dev libltdl-dev python-pip python-cheetah python-setuptools python-simplejson apache2

# Install packages available only though pip
RUN pip install signalfd

# Enable apache CGI
RUN a2enmod cgi

#Copy installation packages
COPY pkgs/ /tmp/pkgs

#Install NoSketchEngine pkgs
# Manatee 
RUN pwd && tar xf /tmp/pkgs/manatee-open-*.tar.gz -C /tmp/pkgs && cd /tmp/pkgs/manatee-open-* && ./configure PYTHON=python2 --with-pcre && make && make install && ldconfig

# Bonito
RUN tar xf /tmp/pkgs/bonito-open-*.tar.gz -C /tmp/pkgs && cd /tmp/pkgs/bonito-open-* && ./configure && make && make install && ./setupbonito /var/www/bonito /var/lib/bonito && chown -R www-data:www-data /var/lib/bonito

# GDEX
RUN tar xf /tmp/pkgs/gdex-*.tar.gz -C /tmp/pkgs && cd /tmp/pkgs/gdex-* && python2 setup.py install

# Crystal
# HACK1 Modify shell in Makefile to bash to handle bashism
# HACK2 add user and chown node_modules directory for node-sass build
RUN tar xf /tmp/pkgs/crystal-open-*.tar.gz -C /tmp/pkgs && cd /tmp/pkgs/crystal-open-*/ && \
sed  -i '1i SHELL:=/bin/bash' Makefile && \
useradd corpora && mkdir /home/corpora && chown -R corpora:corpora /home/corpora /tmp/pkgs/crystal-open-*/ && su -l corpora -c "make -C /tmp/pkgs/crystal-open-*/" && \
make install

# Place corpora
RUN mkdir -p /home/corpora
COPY data/corpora /home/corpora
RUN mkdir /home/registry
COPY data/registry /home/registry

#Encode corpora
RUN encodevert -xrvc /home/registry/susanne

RUN chown -R www-data:www-data /var/lib/bonito

# Copy Apache config
RUN rm /var/www/bonito/.htaccess
COPY conf/000-default.conf /etc/apache2/sites-enabled/
RUN sed -i 's#URL_BONITO: "https://#URL_BONITO: "http://#' /var/www/crystal/config.js
RUN sed -i "s|MANATEE_REGISTRY'] = ''|MANATEE_REGISTRY'] = '/home/registry'|" /var/www/bonito/run.cgi

#Running server
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

EXPOSE 80 443
