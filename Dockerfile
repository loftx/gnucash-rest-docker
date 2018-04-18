FROM ubuntu:16.04
MAINTAINER dev@loftx.co.uk

RUN apt-get update

# Set default MySQL root password for use as test database
RUN apt-get install -y debconf-utils
RUN echo mysql-server-5.7 mysql-server/root_password password oxford | debconf-set-selections
RUN echo mysql-server-5.7 mysql-server/root_password_again password oxford | debconf-set-selections

# Install GnuCash dependancies including MySQL and python
RUN apt-get install -y intltool autoconf automake autotools-dev libsigsegv2 m4 libtool libltdl-dev libglib2.0-dev icu-devtools libicu-dev libboost-all-dev guile-2.0 guile-2.0-dev swig2.0 libxml++2.6-dev libxslt1-dev xsltproc libgtest-dev google-mock gtk+3.0 libgtk-3-dev libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev cmake libdbi-dev libdbd-mysql libxml2-utils

# Install WSGI/Flask dependencies and Flask
RUN apt-get install -y python-pip dbus git apache2 libapache2-mod-wsgi python-dev python-mysqldb
RUN pip install Flask

# Install MySQL server for tests
RUN apt-get install -y mysql-server 

# Avoid 'fatal: unable to auto-detect email address' error from git
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

# Checkout Gnucash 2.7.8
WORKDIR /gnucash
RUN git fetch origin 2.7.8
RUN git checkout tags/2.7.8

# Testing - probably won't need the python dev one
RUN apt-get install -y python3-dev

# Build Gnucash with Python bindings
RUN cmake -D WITH_AQBANKING=OFF -D WITH_OFX=OFF -D WITH_PYTHON=ON -D PYTHON_LIBRARY:FILEPATH=/usr/bin/python3 -D PYTHON_INCLUDE_DIR:PATH=/usr/include/python3.5m .
RUN make

# 'make install' is not run as the following error occurs if /gnucash isn't the working directory (https://bugzilla.gnome.org/show_bug.cgi?id=794526)
# WARN <gnc.engine> failed to load gncmod-backend-dbi from relative path dbi
# CRIT <gnc.engine> required library gncmod-backend-dbi not found.
# WARN <gnc.engine> failed to load gncmod-backend-xml from relative path xml
# CRIT <gnc.engine> required library gncmod-backend-xml not found.

# Checkout Gnucash Rest API
WORKDIR /var/www
RUN git clone https://github.com/loftx/gnucash-rest.git

# Add WSGI config to Apache config
ADD 000-default.conf /etc/apache2/sites-available 

# Set WSGI requirements 
RUN useradd wsgi
RUN mkdir /home/wsgi
RUN chown wsgi:wsgi /home/wsgi

# Create test database
ADD gnucash.gnucash /home/wsgi/gnucash.gnucash

# Add link in main python directory so gnucash can be imported
RUN ln -s /gnucash/lib/python3/dist-packages/gnucash /usr/lib/python3.5/gnucash

# Add link in main python directory so gnucash_rest can be imported 
RUN ln -s /var/www/gnucash-rest/gnucash_rest /usr/lib/python3.5/gnucash_rest

# Expose apache.
EXPOSE 80

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND
