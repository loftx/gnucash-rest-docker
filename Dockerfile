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

WORKDIR /gnucash
RUN git checkout maint

ENV GTEST_ROOT /gtest/googletest
ENV GMOCK_ROOT /gtest/googlemock

#!/bin/bash -e

RUN mkdir -p "$HOME"/.local/share

RUN mkdir /build
WORKDIR /build

ENV TZ "America/Los_Angeles"

# Refresh from cache...
WORKDIR /gnucash
RUN git pull

WORKDIR /build

RUN cmake ../gnucash -DWITH_PYTHON=ON -DCMAKE_BUILD_TYPE=debug -G Ninja -DALLOW_OLD_GETTEXT=ON
RUN ninja
    
RUN ln -s /build/lib/python3/dist-packages/gnucash /usr/lib/python3/dist-packages/gnucash

WORKDIR /

RUN echo "import gnucash" >> /test.py
RUN echo "print('OK')" >> /test.py
RUN echo "" >> /test.py

RUN python3 /test.py
