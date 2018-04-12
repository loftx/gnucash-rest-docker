FROM ubuntu:16.04
MAINTAINER dev@loftx.co.uk

RUN apt-get update

RUN apt-get install -y debconf-utils
RUN echo mysql-server-5.7 mysql-server/root_password password oxford | debconf-set-selections
RUN echo mysql-server-5.7 mysql-server/root_password_again password oxford | debconf-set-selections

RUN apt-get install -y intltool autoconf automake autotools-dev libsigsegv2 m4 libtool libltdl-dev libglib2.0-dev icu-devtools libicu-dev libboost-all-dev guile-2.0 guile-2.0-dev swig2.0 libxml++2.6-dev libxslt1-dev xsltproc libgtest-dev google-mock gtk+3.0 libgtk-3-dev libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev libdbi-dev python-pip dbus git python-dev python-mysqldb mysql-server mysql-client libdbd-mysql apache2 libapache2-mod-wsgi

# Avoid 'fatal: unable to auto-detect email address' error
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git
WORKDIR /gnucash

RUN git fetch origin 2.7.3
RUN git checkout tags/2.7.3 
RUN pip install Flask

RUN ./autogen.sh
RUN ./configure --enable-python
RUN make
RUN make install

# Added LD_LIBRARY_PATH as was seeing errors relating to libgnc-qof.so.1
ENV LD_LIBRARY_PATH /usr/local/lib:/usr/lib:/lib
RUN echo "export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib" >> /etc/apache2/envvars

WORKDIR /var/www
RUN git clone https://github.com/loftx/gnucash-rest.git

ADD 000-default.conf /etc/apache2/sites-available 

ADD gnucash_rest.wsgi /var/www/gnucash-rest

RUN useradd wsgi
RUN mkdir /home/wsgi
RUN chown wsgi:wsgi /home/wsgi

ADD gnucash.gnucash /home/wsgi/gnucash.gnucash

# Expose apache.
EXPOSE 80

# By default start up apache in the foreground, override with /bin/bash for int
CMD service mysql start && /usr/sbin/apache2ctl -D FOREGROUND
