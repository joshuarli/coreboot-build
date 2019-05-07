FROM debian:unstable-slim

RUN apt-get -qq update && \
    apt-get -qqy install \
        g++ \
        gnat \
        make \
        flex \
        bison \
        git \
        bzip2 \
        xz-utils \
        curl \
        zlib1g-dev \
        libncurses5-dev \
        pypy && \
    ln -s "$(command -v pypy)" /usr/bin/python

RUN git clone https://review.coreboot.org/coreboot ~/coreboot
WORKDIR /root/coreboot
RUN make crossgcc-i386 CPUS=$(nproc)

# clean up coreboot toolchain build requirements
# make, libncurses5-dev is needed for make menuconfig
# python (pypy interpreter works fine, and is a smaller package) is needed as part of seabios build
# git is still needed (although read the TODO)

RUN apt-get -qqy purge \
        g++ \
        gnat \
#        make \
        flex \
        bison \
#        git \
        bzip2 \
        xz-utils \
        curl \
        zlib1g-dev && \
#        libncurses5-dev \
#        pypy \
    apt-get clean

# the blobs repository is excluded from submodule updates, but is necessary, so clone the latest
RUN git clone https://review.coreboot.org/blobs 3rdparty/blobs/

# build ifdtool and create in-path symlinks to some common tools
RUN cd util/ifdtool && \
    make && \
    ln -s "$(readlink -f ./ifdtool)" /usr/bin/ifdtool && \
    ln -s "$(readlink -f ../me_cleaner/me_cleaner.py)" /usr/bin/me_cleaner

# TODO: if seabios repo is vendored in during docker build, and the coreboot build process is modified to not submodule update (and so do that in the docker build), then git can be purged as well as .git/ in coreboot, for some space savings in the final image
