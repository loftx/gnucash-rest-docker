from ubuntu:16.04
run apt-get update -qq
run apt-get build-dep -qq gnucash > /dev/null
run apt-get install -qq git bash-completion cmake make swig xsltproc libdbd-sqlite3 texinfo ninja-build libboost-all-dev libgtk-3-dev libwebkit2gtk-3.0-dev > /dev/null
run apt-get --reinstall install -qq language-pack-en language-pack-fr
run git clone https://github.com/google/googletest -b release-1.8.0 gtest

# Avoid 'fatal: unable to auto-detect email address' error from git
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

run apt-get install -qq python3-dev

ENV GTEST_ROOT /gtest/googletest
ENV GMOCK_ROOT /gtest/googlemock

#!/bin/bash -e

RUN mkdir -p "$HOME"/.local/share

RUN mkdir /build
WORKDIR /build

ENV TZ "America/Los_Angeles"

# Set default MySQL root password for use as test database
RUN apt-get install -y debconf-utils
RUN echo mysql-server-5.7 mysql-server/root_password password oxford | debconf-set-selections
RUN echo mysql-server-5.7 mysql-server/root_password_again password oxford | debconf-set-selections

RUN apt-get install -y python3-mysqldb python3-dev mysql-server 
# we probably don't need python3-dev or libdbi-dev - try removing them and see what happens
RUN apt-get install -y libdbi-dev libdbd-mysql

# Install MySQL server for tests
RUN apt-get install -y mysql-server

# New bits
RUN apt-get install -y python3-pip apache2 libapache2-mod-wsgi
RUN pip3 install Flask

WORKDIR /var/www
RUN git clone https://github.com/loftx/gnucash-rest.git

WORKDIR /gnucash

# Add patch for gint32
ADD base-typemaps.i.add_gint32.patch /gnucash/base-typemaps.i.add_gint32.patch
RUN git apply base-typemaps.i.add_gint32.patch

WORKDIR /build

RUN cmake ../gnucash -DWITH_PYTHON=ON -DCMAKE_BUILD_TYPE=debug -G Ninja -DALLOW_OLD_GETTEXT=ON
RUN ninja
RUN ninja install
    
RUN ln -s /build/lib/python3/dist-packages/gnucash /usr/lib/python3/dist-packages/gnucash
RUN ln -s /var/www/gnucash-rest/gnucash_rest/gnucash_simple.py /usr/lib/python3/dist-packages/gnucash_simple.py

WORKDIR /build
