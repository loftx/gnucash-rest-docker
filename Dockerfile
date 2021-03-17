FROM ubuntu:16.04
MAINTAINER dev@loftx.co.uk

# Avoid interactive prompts e.g. for tzdata
ARG DEBIAN_FRONTEND=noninteractive
# Resolve 'E: You must put some 'source' URIs in your sources.list' error
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN apt-get update
RUN apt-get build-dep -y gnucash
RUN apt-get install -y libtool swig subversion libgnomeui-dev xsltproc python3-pip dbus git apache2 libapache2-mod-wsgi-py3 python3-dev
RUN apt-get install -y cmake libwebkit2gtk-3.0-dev libgtk-3-dev libboost-all-dev gettext libgtest-dev libdbd-mysql google-mock 	
RUN pip3 install Flask

# Avoid 'fatal: unable to auto-detect email address' error
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

WORKDIR /gnucash
RUN git checkout tags/3.11

RUN mkdir /build-gnucash
WORKDIR /build-gnucash

RUN cmake -DCMAKE_INSTALL_PREFIX=$HOME/opt -DWITH_PYTHON=ON ../gnucash  
RUN make
RUN make install

# Copy .so files over to lib directory
RUN cp /root/opt/lib/* /lib/
RUN cp /root/opt/lib/gnucash/* /lib/

# Copy python packages over to python directory
RUN cp -r /root/opt/lib/python3.5/site-packages/* /usr/lib/python3/dist-packages/

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

#RUN python3 -c 'import gnucash'

# By default start up apache in the foreground, override with /bin/bash for interative.
#CMD /usr/sbin/apache2ctl -D FOREGROUND
CMD bash
