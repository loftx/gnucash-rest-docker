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
RUN apt-get install -y python3-pip dbus git apache2 libapache2-mod-wsgi python3-dev python3-mysqldb
RUN pip3 install Flask

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

# Build Gnucash with Python bindings
RUN cmake -D WITH_AQBANKING=OFF -D WITH_OFX=OFF -D WITH_PYTHON=ON -D PYTHON_LIBRARY:FILEPATH=/usr/bin/python3 -D PYTHON_INCLUDE_DIR:PATH=/usr/include/python3.5m .
RUN make

# Add link in main python directory so gnucash can be imported
RUN ln -s /gnucash/lib/python3/dist-packages/gnucash /usr/lib/python3.5/gnucash

RUN apt-get install -y gdb python3-dbg libc6-dbg

#RUN python3 -c 'import gnucash'

RUN echo 1

RUN gdb -ex r --args python3 -c 'import gnucash'