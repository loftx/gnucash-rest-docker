FROM ubuntu:20.04
MAINTAINER dev@loftx.co.uk

# Avoid interactive prompts e.g. for tzdata
ARG DEBIAN_FRONTEND=noninteractive
# Resolve 'E: You must put some 'source' URIs in your sources.list' error
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN apt-get update
RUN apt-get build-dep -y gnucash
RUN apt-get install -y libtool swig subversion xsltproc python3-pip dbus git apache2 libapache2-mod-wsgi-py3 python3-dev
RUN apt-get install -y cmake libgtk-3-dev libboost-all-dev gettext libgtest-dev libdbd-mysql google-mock 	
# from old 18.04
RUN apt-get install -y git bash-completion cmake make swig xsltproc libdbd-sqlite3 texinfo ninja-build libboost-all-dev libwebkit2gtk-4.0-dev 
RUN pip3 install Flask

# Avoid 'fatal: unable to auto-detect email address' error
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

WORKDIR /gnucash
RUN git checkout tags/3.11 # latest in 3 branch

###

WORKDIR /
RUN git clone https://github.com/google/googletest.git

WORKDIR /googletest
RUN mkdir build 
WORKDIR /googletest/build
RUN cmake .. -DBUILD_SHARED_LIBS=ON -DINSTALL_GTEST=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr
RUN make -j8
RUN make install
RUN ldconfig

###

#RUN mkdir /build-gnucash

RUN mkdir /gnucash-install

#WORKDIR /build-gnucash

WORKDIR /gnucash

RUN cmake /gnucash -DWITH_PYTHON=ON -DCMAKE_BUILD_TYPE=debug -G Ninja -DALLOW_OLD_GETTEXT=ON -DWITH_AQBANKING=OFF -DWITH_OFX=OFF -DCMAKE_INSTALL_PREFIX=/gnucash-install
WORKDIR /gnucash
RUN ninja
RUN ninja install

# Copy .so files over to lib directory
#RUN cp -R /root/opt/lib/* /lib/
#RUN cp -R /root/opt/lib/gnucash/* /lib/

# Copy python packages over to python directory
RUN cp -r /gnucash-install/lib/python3.8/site-packages/* /usr/lib/python3/dist-packages/

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
