# The builder image

## From official Debian 13 Trixie image pinned by its name trixie-slim
FROM debian:trixie-slim AS build

## Install noske dependencies
### deb packages
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        libltdl-dev \
        libpcre2-dev \
        bison \
        libsass-dev \
        python3-dev \
        python3-setuptools \
        libcap-dev \
        file \
        swig \
        debmake \
        javahelper \
        autoconf-archive \
        dh-python \
        pybuild-plugin-pyproject && \
    rm -rf /var/lib/apt/lists/*

## Build noske components
COPY noske_files/* /tmp/noske_files/
WORKDIR /tmp/noske_files/

### Manatee
#### HACK1: Add str_map.h which is missing from the source
COPY conf/str_map.h /tmp/noske_files/
RUN tar -xvf manatee* && \
    cd manatee* && \
    debmake && \
    cp ../str_map.h ./hat-trie/test/str_map.h && \
    EDITOR=/bin/true dpkg-source -q --commit . fix_build && \
    echo -e 'override_dh_auto_configure:\n\tdh_auto_configure -- \\\n\t\t--with-pcre2' >> ./debian/rules && \
    debuild -d -us -uc

### Bonito
#### HACK2: Add patch to dynamically load corpora registry files
RUN tar -xvf bonito* && \
    cd bonito* && \
    debmake -b":python3" && \
    printf '%b\n' \
    '/^    corplist = \["susanne"\]$/c\\' \
    '    \# Read corpora list runtime from registry\\' \
    '    if "MANATEE_REGISTRY" not in os.environ:\\' \
    '        os.environ["MANATEE_REGISTRY"] = "@MANATEE_REGISTRY@"\\' \
    '    corplist = [corp_name for corp_name in os.listdir(os.environ["MANATEE_REGISTRY"])]' \
    ';/^    corpname = "susanne"$/c\\' \
    '    if len(corplist) > 0:\\' \
    '        corpname = corplist[0]\\' \
    '    else:\\' \
    '        corpname = "susanne"' | \
    sed -i -f - run.cgi.in && \
    touch AUTHORS ChangeLog NEWS && \
    EDITOR=/bin/true dpkg-source -q --commit . fix_build && \
    printf '%s\n' \
    '#!/bin/bash' \
    '#DEBHELPER#' \
    '' \
    'MANATEE_REGISTRY="/corpora/registry" /usr/bin/setupbonito /var/www/bonito /var/lib/bonito' \
    'chown -R www-data:www-data /var/lib/bonito' > debian/postinst && \
    printf '%b\n' \
    'export DEB_PYTHON_INSTALL_LAYOUT=deb' \
    'override_dh_auto_install:' \
    '\tPREFIX=/usr DESTDIR=$(CURDIR)/debian/tmp make install' \
    'override_dh_missing:' \
    '\tdh_missing --fail-missing' >> ./debian/rules && \
    printf '%s\n' \
    'usr/bin/*' \
    'usr/lib/python3/dist-packages/bonito/*' \
    'usr/share/bonito/*' >> debian/bonito-open.install && \
    debuild -d -us -uc

### GDEX
RUN tar -xvf gdex* && \
    cd gdex* && \
    debmake -b":python3" && \
    sed -i "s/<version>/4.13.13/g" setup.py && \
    EDITOR=/bin/true dpkg-source -q --commit . fix_build && \
    echo -e 'override_dh_auto_test:\n\techo "Disabled autotest"' >> debian/rules && \
    debuild -d -us -uc

### Crystal
#### HACK2: Modify npm install command in Makefile to handle "permission denied"
#### HACK3: Modify version directly in the Makefile instead of creating an environment variable
#### HACK4: Copy modified page-dashboard.tag to be able to display custom citation message with URL (and restore banner)
#### HACK5: modify URL_BONITO to be set dynamically to the request domain in every request
COPY conf/page-dashboard.tag /tmp/noske_files/
RUN tar -xvf crystal* && \
    cd crystal-* && \
    debmake && \
    touch debian/changelog && \
    sed -e 's/npm install/npm install --unsafe-perm=true/' \
        -e 's/VERSION ?= `git describe --tags --always`/VERSION=2.238.7/' \
        -i Makefile && \
    cp ../page-dashboard.tag app/src/dashboard/page-dashboard.tag && \
    EDITOR=/bin/true dpkg-source -q --commit . fix_build && \
    echo 'sed -e "s|URL_BONITO: \"http://.*|URL_BONITO: window.location.origin + \"/bonito/run.cgi/\",|" \' \
        >> debian/postinst && \
    echo '-e "s|HIDE_DASHBOARD_BANNER: true|HIDE_DASHBOARD_BANNER: false|" \' >> debian/postinst && \
    echo '-i /var/www/crystal/config.js' >> debian/postinst && \
    debuild -d -us -uc

# The actual image

## From official Debian 13 Trixie image pinned by its name trixie-slim
FROM debian:trixie-slim

## Copy deb packages built in the previous step
COPY --from=build /tmp/noske_files/*.deb /tmp/noske_files/

## Install noske dependencies
### deb packages
RUN apt-get update && \
    apt-get install -y \
        parallel \
        make \
        apache2 \
        libapache2-mod-shib \
        python3-prctl \
        python3-openpyxl \
        python3-html2text \
        python3-legacy-cgi \
        /tmp/noske_files/*.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/noske_files

## Enable apache CGI and mod_rewrite
RUN a2enmod cgi rewrite shib

## Copy config files (These files contain placeholders replaced in entrypoint.sh according to environment variables)
COPY conf/*.sh /usr/local/bin/
COPY conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY conf/shibboleth2.xml /etc/shibboleth/shibboleth2.xml
COPY conf/*.crt /etc/shibboleth/

## These files should be updated through environment variables (HTACCESS,HTPASSWD,PUBLIC_KEY,PRIVATE_KEY)
##  but uncommenting the lines below enable creation of a custom image with secrets included
# COPY secrets/htaccess /var/www/.htaccess
# COPY secrets/htpasswd /var/lib/bonito/htpasswd
# COPY secrets/*.crt /etc/shibboleth/

## HACK6: Link site-packages to dist-packages to help Python find these packages
#          (e.g. creating subcorpus and keywords on it -> calls mkstats with popen which calls manatee internally)
#         TODO Seems to be a bug in the build system as manatee should be in .../site-packages/manatee folder
## HACK7: Symlink bonito path to have less changes in run.cgi
## HACK8: Create /var/lib/bonito folder
RUN ln -s /usr/lib/python3.13/site-packages/manatee.py /usr/lib/python3/dist-packages/manatee.py && \
    ln -s /usr/lib/python3.13/site-packages/_manatee.so /usr/lib/python3/dist-packages/_manatee.so && \
    ln -s /usr/lib/python3.13/site-packages/_manatee.a /usr/lib/python3/dist-packages/_manatee.a && \
    ln -s /usr/lib/python3.13/site-packages/_manatee.la /usr/lib/python3/dist-packages/_manatee.la

# Start the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "$@"]
EXPOSE 80
