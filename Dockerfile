FROM ubuntu:16.04
MAINTAINER dev@loftx.co.uk

# Avoid interactive prompts e.g. for tzdata
ARG DEBIAN_FRONTEND=noninteractive
# Resolve 'E: You must put some 'source' URIs in your sources.list' error
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN apt-get update
RUN apt-get build-dep -y gnucash
RUN apt-get install -y libtool swig subversion libgnomeui-dev xsltproc python-pip dbus git apache2 libapache2-mod-wsgi python-dev
RUN apt-get install -y cmake libwebkit2gtk-3.0-dev libgtk-3-dev  libboost-all-dev gettext libgtest-dev google-mock
RUN pip install Flask

# Avoid 'fatal: unable to auto-detect email address' error
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

WORKDIR /gnucash
RUN git checkout tags/3.11

RUN mkdir /build-gnucash
WORKDIR /build-gnucash
RUN cmake -DCMAKE_INSTALL_PREFIX=$HOME/opt  ../gnucash  
RUN make
RUN make install
# Added LD_LIBRARY_PATH as was seeing errors relating to libgnc-qof.so.1
ENV LD_LIBRARY_PATH /usr/local/lib:/usr/lib:/lib
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

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND
