FROM ubuntu:16.04
MAINTAINER dev@loftx.co.uk

RUN apt-get update
RUN apt-get install -y intltool autoconf automake autotools-dev libsigsegv2 m4 libtool libltdl-dev libglib2.0-dev icu-devtools libicu-dev libboost-all-dev guile-2.0 guile-2.0-dev swig2.0 libxml++2.6-dev libxslt1-dev xsltproc libgtest-dev google-mock gtk+3.0 libgtk-3-dev libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev cmake libdbi-dev libdbd-mysql libxml2-utils
RUN apt-get install -y python-pip dbus git apache2 libapache2-mod-wsgi python-dev
RUN pip install Flask

# Avoid 'fatal: unable to auto-detect email address' error
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

WORKDIR /gnucash
#RUN git fetch origin 2.7.5
#RUN git checkout tags/2.7.5 

# Move this with the rest of the installs if required - error seems to go away with this?
RUN apt-get install libmysqlclient-dev

RUN cmake -D CMAKE_INSTALL_PREFIX=/opt/gnucash-devel -D WITH_AQBANKING=OFF -D WITH_OFX=OFF -D WITH_PYTHON=ON .
RUN make
RUN make install

WORKDIR /var/www
RUN git clone https://github.com/loftx/gnucash-rest.git

ADD 000-default.conf /etc/apache2/sites-available 

ADD gnucash_rest.wsgi /var/www/gnucash-rest

RUN useradd wsgi
RUN mkdir /home/wsgi
RUN chown wsgi:wsgi /home/wsgi

ADD gnucash.gnucash /home/wsgi/gnucash.gnucash

# Add link in main python directory
RUN ln -s /gnucash/lib/python2.7/site-packages/gnucash /usr/lib/python2.7/gnucash

RUN service apache2 restart

# Expose apache.
EXPOSE 80

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND
