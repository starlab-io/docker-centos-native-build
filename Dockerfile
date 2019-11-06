FROM starlabio/centos-base:3
MAINTAINER David Esler <david.esler@starlab.io>

# setup linkers for Cargo
RUN mkdir -p /root/.cargo/

ENV PATH "/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# install rustup
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && \
    sh ./rustup-install.sh -y --default-toolchain 1.37.0-x86_64-unknown-linux-gnu && \
    rm rustup-install.sh

# Install rustfmt / cargo fmt for testing
RUN rustup component add rustfmt

# Install yum-plugin-ovl to work around issue with a bad
# rpmdb checksum
# Install xxd and attr utilities
# Install CONFIG_STACK_VALIDATION dependencies
# Install which required to build RedHawk 6 OpenOnLoad subsystem
RUN yum install -y yum-plugin-ovl vim-common attr libffi libffi-devel \
        elfutils-libelf-devel gcc gcc-c++ python-devel freetype-devel \
        libpng-devel dracut-network nfs-utils trousers-devel libtool which && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# TODO: matplotlib==2.2.3 is the LTS version, if we upgrade this, we have to
# upgrade python to 3.x
RUN pip install numpy==1.16.0
RUN pip install xattr requests behave pyhamcrest matplotlib==2.2.3

COPY dracut.conf /etc/dracut.conf

# Install EPEL
RUN yum install -y epel-release && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install Xen build dependencies
RUN yum install -y libidn-devel zlib-devel SDL-devel curl-devel \
		libX11-devel ncurses-devel gtk2-devel libaio-devel dev86 iasl \
		gettext gnutls-devel openssl-devel pciutils-devel libuuid-devel \
		bzip2-devel xz-devel e2fsprogs e2fsprogs-devel yajl-devel mingw64-binutils \
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
RUN yum install -y check check-devel check.i686 check-devel.i686 \
        valgrind json-c-devel subunit \
        cppcheck subunit-devel && \
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
RUN yum install -y gpg createrepo rpmsign \
                libxslt-devel libxml2-devel libyaml-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/* \
    # Set digest algorithms to be NIAP compatible (SHA256)
    echo "%_source_filedigest_algorithm 8" >> /etc/rpm/macros \
    echo "%_binary_filedigest_algorithm 8" >> /etc/rpm/macros

# Add tools for building the driverdomain image
RUN yum install -y squashfs-tools && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Add ccache for development use
RUN yum install -y ccache && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

RUN yum install -y gcc-aarch64-linux-gnu libgcc.i686 libgcc-devel.i686 && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install ronn for generating man pages
RUN yum install -y ruby-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/* && \
    gem install ronn

# Various systemd build requirements
RUN yum install -y gperf libcap-devel libmount-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Newer curl for systemd
COPY yum.repos.d/city-fan.repo /etc/yum.repos.d/
RUN yum update -y curl \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Add SELinux policy devel
RUN yum install -y selinux-policy-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

