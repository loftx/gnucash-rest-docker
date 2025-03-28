FROM ubuntu:24.04
MAINTAINER dev@loftx.co.uk

# Avoid interactive prompts e.g. for tzdata
ARG DEBIAN_FRONTEND=noninteractive
# Resolve 'E: You must put some 'source' URIs in your sources.list' error
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
RUN apt update
RUN apt build-dep -y gnucash
RUN apt install -y libtool swig subversion xsltproc python3-pip dbus git apache2 libapache2-mod-wsgi-py3 python3-dev
RUN apt install -y cmake libgtk-3-dev libboost-all-dev gettext libgtest-dev libdbd-mysql google-mock 
RUN apt install -y git bash-completion cmake make swig xsltproc libdbd-sqlite3 texinfo ninja-build libboost-all-dev guile-2.2-dev python3-flask

# needed for testing
RUN apt install -y python3-mysqldb libmysqlclient-dev

# Avoid 'fatal: unable to auto-detect email address' error
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

WORKDIR /gnucash
RUN git checkout tags/5.10 #  5 seems to build

WORKDIR /
RUN git clone https://github.com/google/googletest.git

WORKDIR /googletest
RUN mkdir build 
WORKDIR /googletest/build

RUN cmake .. -DBUILD_SHARED_LIBS=ON -DINSTALL_GTEST=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr
RUN make -j8
RUN make install
RUN ldconfig

RUN mkdir /gnucash-install

WORKDIR /gnucash

RUN cmake /gnucash -DWITH_PYTHON=ON -DCMAKE_BUILD_TYPE=debug -G Ninja -DALLOW_OLD_GETTEXT=ON -DWITH_AQBANKING=OFF -DWITH_OFX=OFF -DCMAKE_INSTALL_PREFIX=/gnucash-install
WORKDIR /gnucash
RUN ninja
RUN ninja install

# Copy python packages over to python directory
RUN cp -r /gnucash-install/lib/python3.12/site-packages/* /usr/lib/python3/dist-packages/

ADD gnucash.gnucash /gnucash.gnucash

WORKDIR /var/www
RUN git clone https://github.com/loftx/gnucash-rest.git

ADD 000-default.conf /etc/apache2/sites-available 

ADD gnucash_rest.wsgi /var/www/gnucash-rest

RUN useradd wsgi
RUN mkdir /home/wsgi
RUN chown wsgi:wsgi /home/wsgi

RUN service apache2 restart

# Expose apache.
EXPOSE 80

WORKDIR /var/www/gnucash-rest

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND
