from ubuntu:16.04
RUN apt-get update -qq
RUN apt-get build-dep -qq gnucash > /dev/null
RUN apt-get install -qq git bash-completion cmake make swig xsltproc libdbd-sqlite3 texinfo ninja-build libboost-all-dev libgtk-3-dev libwebkit2gtk-3.0-dev > /dev/null

# Set default MySQL root password for use as test database
RUN apt-get install -y debconf-utils
RUN echo mysql-server-5.7 mysql-server/root_password password oxford | debconf-set-selections
RUN echo mysql-server-5.7 mysql-server/root_password_again password oxford | debconf-set-selections

RUN apt-get install -y python3-mysqldb python3-dev mysql-server 
# we probably don't need python3-dev or libdbi-dev - try removing them and see what happens
RUN apt-get install -y libdbi-dev libdbd-mysql
RUN apt-get install -qq python3-dev

# Install MySQL server for tests
RUN apt-get install -y mysql-server

# Install Apache webserver and Flask middleware for 
RUN apt-get install -y python3-pip apache2 libapache2-mod-wsgi-py3
RUN pip3 install Flask

# Install Googletest for Gnucash build requirement
RUN apt-get --reinstall install -qq language-pack-en language-pack-fr
RUN git clone https://github.com/google/googletest -b release-1.8.0 gtest

# Avoid 'fatal: unable to auto-detect email address' error from git
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"

# Get lastest version of Gnucash maint release
RUN git clone https://github.com/Gnucash/gnucash.git

# Settings for googletest 
ENV GTEST_ROOT /gtest/googletest
ENV GMOCK_ROOT /gtest/googlemock

RUN mkdir -p "$HOME"/.local/share

RUN mkdir /build
WORKDIR /build

ENV TZ "America/Los_Angeles"

# Build and install Gnucash
RUN cmake ../gnucash -DWITH_PYTHON=ON -DCMAKE_BUILD_TYPE=debug -G Ninja -DALLOW_OLD_GETTEXT=ON
RUN ninja
RUN ninja install

# Download Gnucash rest
WORKDIR /var/www
RUN git clone https://github.com/loftx/gnucash-rest.git

# Set python path to  gnucash python install dir and gnucash_rest dir
ENV PYTHONPATH /usr/local/lib/python3/dist-packages:/var/www/gnucash-rest/gnucash_rest

# Set WSGI requirements 
RUN useradd wsgi
RUN mkdir /home/wsgi
RUN chown wsgi:wsgi /home/wsgi

# Add WSGI config to Apache config
ADD 000-default.conf /etc/apache2/sites-available 

# Add updated WSGI file
ADD gnucash_rest.wsgi /var/www/gnucash-rest

# Create test database
ADD gnucash.gnucash /home/wsgi/gnucash.gnucash

# Expose apache.
EXPOSE 80

CMD /usr/sbin/apache2ctl -D FOREGROUND
