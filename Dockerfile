FROM phusion/baseimage:0.9.19

#ARG STEEMD_BLOCKCHAIN=https://example.com/steemd-blockchain.tbz2

RUN \
    apt-get update && \
    apt-get install -y \
        autoconf \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        cmake \
        doxygen \
        git \
        libboost-all-dev \
        libreadline-dev \
        libssl-dev \
        libtool \
        ncurses-dev \
        pbzip2 \
        python3 \
        python3-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /usr/local/src/steem

RUN \
    cd /usr/local/src/steem && \
    git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/usr/local/steemd-default \
        -DCMAKE_BUILD_TYPE=Release \
        -DLOW_MEMORY_NODE=ON \
        -DENABLE_CONTENT_PATCHING=OFF \
        -DCLEAR_VOTES=ON \
        .. \
    && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rfv build && \
    mkdir build && \
    cd build && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/usr/local/steemd-full \
        -DCMAKE_BUILD_TYPE=Release \
        -DLOW_MEMORY_NODE=OFF \
        -DENABLE_CONTENT_PATCHING=ON \
        -DCLEAR_VOTES=OFF \
        .. \
    && \
    make -j$(nproc) && \
    make install && \
    rm -rf /usr/local/src/steem

RUN \
    apt-get remove -y \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        cmake \
        doxygen \
        dpkg-dev \
        git \
        libboost-all-dev \
        libc6-dev \
        libexpat1-dev \
        libgcc-5-dev \
        libhwloc-dev \
        libibverbs-dev \
        libicu-dev \
        libltdl-dev \
        libncurses5-dev \
        libnuma-dev \
        libopenmpi-dev \
        libpython-dev \
        libpython2.7-dev \
        libreadline-dev \
        libreadline6-dev \
        libssl-dev \
        libstdc++-5-dev \
        libtinfo-dev \
        libtool \
        linux-libc-dev \
        m4 \
        make \
        manpages \
        manpages-dev \
        mpi-default-dev \
        python-dev \
        python2.7-dev \
        python3-dev \
    && \
    apt-get autoremove -y && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /var/cache/* \
        /usr/include \
        /usr/local/include

RUN useradd -s /bin/bash -m -d /var/lib/steemd steemd

RUN mkdir /var/cache/steemd && \
    chown steemd:steemd -R /var/cache/steemd

# add blockchain cache to image
#ADD $STEEMD_BLOCKCHAIN /var/cache/steemd/blocks.tbz2

ENV HOME /var/lib/steemd
RUN chown steemd:steemd -R /var/lib/steemd

VOLUME ["/var/lib/steemd"]

# rpc service:
EXPOSE 8090
# p2p service:
EXPOSE 2001

RUN mkdir -p /etc/service/steemd
ADD contrib/steemd.run /etc/service/steemd/run
RUN chmod +x /etc/service/steemd/run

# add seednodes from documentation to image
ADD doc/seednodes.txt /etc/steemd/seednodes.txt

# the following adds lots of logging info to stdout
ADD contrib/config-for-docker.ini /etc/steemd/config.ini
