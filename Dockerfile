FROM starlabio/centos-base:2
MAINTAINER David Esler <david.esler@starlab.io>

# setup linkers for Cargo
RUN mkdir -p /root/.cargo/

ENV PATH "/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# install rustup
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && \
    sh ./rustup-install.sh -y --default-toolchain 1.26.2-x86_64-unknown-linux-gnu && \
    rm rustup-install.sh

# Install rustfmt / cargo fmt for testing
RUN cargo install --force rustfmt --vers 0.8.6

# Install yum-plugin-ovl to work around issue with a bad
# rpmdb checksum
# Install xxd and attr utilities
# Install CONFIG_STACK_VALIDATION dependencies
RUN yum install -y yum-plugin-ovl vim-common attr libffi libffi-devel \
        elfutils-libelf-devel gcc gcc-c++ python-devel freetype-devel \
        libpng-devel dracut-network nfs-utils trousers-devel libtool && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# TODO: matplotlib==2.2.3 is the LTS version, if we upgrade this, we have to
# upgrade python to 3.x
RUN pip install xattr matplotlib==2.2.3 requests behave pyhamcrest

COPY dracut.conf /etc/dracut.conf

# Install EPEL
RUN yum install -y epel-release && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install Xen build dependencies
RUN yum install -y libidn-devel zlib-devel SDL-devel curl-devel \
		libX11-devel ncurses-devel gtk2-devel libaio-devel dev86 iasl \
		gettext gnutls-devel openssl-devel pciutils-devel libuuid-devel \
		bzip2-devel xz-devel e2fsprogs-devel yajl-devel mingw64-binutils \
		systemd-devel glibc-devel.i686 texinfo \
        && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install checkpolicy for XSM Xen
RUN yum install -y checkpolicy \
        && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install grub2 build dependencies
RUN yum install -y device-mapper-devel freetype-devel gettext-devel texinfo \
		dejavu-sans-fonts help2man libusb-devel rpm-devel glibc-static.x86_64 \
		glibc-static.i686 autogen \
        && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install yum-utils
RUN yum install -y yum-utils \
        && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

COPY build_binutils /tmp/

RUN /tmp/build_binutils

## Upstream now has gcc-4.8.5-36 which is greater then the -28 we were forcing
RUN yum install -y gcc && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*


# Add check and JSON dependencies
RUN yum install -y check check-devel valgrind json-c-devel subunit subunit-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

RUN yum install -y tpm2-tss-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Add libraries for building cryptsetup and friends
RUN yum install -y libgcrypt-devel libpwquality-devel libblkid-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Add rpmsign and createrepo for building the Yum release repos
RUN yum install -y gpg createrepo rpmsign && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*
