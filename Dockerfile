from ubuntu:14.04
run apt-get update -qq
run apt-get build-dep -qq gnucash > /dev/null
run apt-get install -qq git bash-completion cmake3 make swig xsltproc libdbd-sqlite3 texinfo ninja-build libboost-all-dev libgtk-3-dev libwebkit2gtk-3.0-dev > /dev/null
run apt-get --reinstall install -qq language-pack-en language-pack-fr
run git clone https://github.com/google/googletest -b release-1.8.0 gtest
copy ubuntu-14.04-testscript afterfailure commonbuild /

# Avoid 'fatal: unable to auto-detect email address' error from git
RUN git config --global user.email "unused@example.com"
RUN git config --global user.name "Unused"
RUN git clone https://github.com/Gnucash/gnucash.git

run apt-get install -qq python3-dev

run chmod +x /ubuntu-14.04-testscript /afterfailure /commonbuild
run /ubuntu-14.04-testscript
