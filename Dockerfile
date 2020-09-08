FROM starlabio/centos-base:3 AS main

LABEL maintainer="David Esler <david.esler@starlab.io>; Pete Dietl <pete.dietl@starlab.io>"

# Install EPEL
# Install yum-plugin-ovl to work around issue with a bad
# rpmdb checksum
RUN yum install -y epel-release yum-plugin-ovl

# Newer curl for systemd
COPY yum.repos.d/city-fan.repo /etc/yum.repos.d/

RUN yum update -y && yum install -y \
    # Install xxd and attr utilities
    # Install CONFIG_STACK_VALIDATION dependencies
    # Install which required to build RedHawk 6 OpenOnLoad subsystem
    # Install lz4 (for building systemd)
    vim-common attr libffi libffi-devel \
    elfutils-libelf-devel gcc gcc-c++ python-devel freetype-devel \
    libpng-devel lz4-devel dracut-network nfs-utils trousers-devel \
    libtool which \
    # Install Xen build dependencies
    libidn-devel zlib-devel SDL-devel curl-devel \
    libX11-devel ncurses-devel gtk2-devel libaio-devel dev86 iasl \
    gettext gnutls-devel openssl-devel pciutils-devel libuuid-devel \
    bzip2-devel xz-devel e2fsprogs e2fsprogs-devel yajl-devel mingw64-binutils \
    systemd-devel glibc-devel.i686 texinfo \
    # Install checkpolicy for XSM Xen
    checkpolicy \
    # Install grub2 build dependencies
    device-mapper-devel freetype-devel gettext-devel texinfo \
    dejavu-sans-fonts help2man libusb-devel rpm-devel glibc-static.x86_64 \
    glibc-static.i686 autogen \
    # Install yum-utils
    yum-utils \
    # Upstream now has gcc-4.8.5-36 which is greater then the -28 we were forcing
    gcc \
    # Add check and JSON dependencies
    check check-devel check.i686 check-devel.i686 \
    valgrind json-c-devel subunit \
    cppcheck subunit-devel \
    # Install tpm2
    tpm2-tss-devel \
    # Add libraries for building cryptsetup and friends
    libgcrypt-devel libpwquality-devel libblkid-devel \
    # Add tools for building the driverdomain image
    squashfs-tools \
    # Add ccache for development use
    ccache \
    # Install x86 32-bit gcc libs and aarch64 cross-compiler
    gcc-aarch64-linux-gnu libgcc.i686 libgcc-devel.i686 \
    # Install yum dependencies for ronn
    ruby-devel \
    # Various systemd build requirements
    gperf libcap-devel libmount-devel \
    # Add rpmsign and createrepo for building the Yum release repos
    gpg createrepo rpmsign \
    libxslt-devel libxml2-devel libyaml-devel \
    # Add prelink for execstack
    prelink \
    # Add pigz for tarball gzipping in parallel
    pigz \
    # Add hmaccalc for generating FIPS hmac files
    hmaccalc \
    # Add SELinux policy devel
    selinux-policy-devel \
    # For running as a non-root user but being able to up privileges
    sudo \
    # Because VIM!
    vim \
    # For debugging
    strace \
    # For tracing files in filesystem
    tree \
    # zip
    zip \
    # Python3
    python3 \
    # Cleanup
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/etc/local/cargo/rustup

# install rustup in a globally accessible location
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && \
    umask 020 && sh ./rustup-install.sh -y --default-toolchain 1.46.0-x86_64-unknown-linux-gnu && \
    rm rustup-install.sh && \
                            \
    # Install rustfmt / cargo fmt for testing
    rustup component add rustfmt

# TODO: matplotlib==2.2.3 is the LTS version, if we upgrade this, we have to
# upgrade python to 3.x
RUN pip install --upgrade pip && \
    pip install numpy==1.16.0 xattr requests behave pyhamcrest matplotlib==2.2.3

# Install ronn for generating man pages
RUN gem install ronn

# Set digest algorithms to be NIAP compatible (SHA256)
RUN echo "%_source_filedigest_algorithm 8" >> /etc/rpm/macros && \
    echo "%_binary_filedigest_algorithm 8" >> /etc/rpm/macros

ARG SHELLCHECK_VER=v0.7.0
RUN wget -nv https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz && \
    tar xf shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz && \
    install shellcheck-${SHELLCHECK_VER}/shellcheck /usr/local/bin && \
    rm shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz && \
    rm -r shellcheck-${SHELLCHECK_VER}

###
### BEGIN intermediate multi-stage build layers
###

FROM main AS binutils
COPY build_binutils /tmp/
RUN /tmp/build_binutils

FROM main AS bash
COPY bash_pub_key /tmp
ARG BASH_VER=5.0
RUN cd /tmp/ && \
    wget -nv http://ftp.gnu.org/gnu/bash/bash-${BASH_VER}.tar.gz && \
    wget -nv http://ftp.gnu.org/gnu/bash/bash-${BASH_VER}.tar.gz.sig && \
    gpg --import bash_pub_key && \
    gpg --verify bash-${BASH_VER}.tar.gz.sig && \
    tar xf bash-${BASH_VER}.tar.gz && \
    cd bash-${BASH_VER} && \
    ./configure \
        --prefix=/usr/local \
        --enable-alias \
        --enable-arith-for-command \
        --enable-array-variables \
        --enable-bang-history \
        --enable-brace-expansion \
        --enable-command-timing \
        --enable-cond-command \
        --enable-cond-regexp \
        --enable-coprocesses \
        --enable-debugger \
        --enable-dev-fd-stat-broken \
        --enable-directory-stack \
        --enable-disabled-builtins \
        --enable-dparen-arithmetic \
        --enable-extended-glob \
        --enable-help-builtin \
        --enable-history \
        --enable-job-control \
        --enable-multibyte \
        --enable-net-redirections \
        --enable-process-substitution \
        --enable-progcomp \
        --enable-prompt-string-decoding \
        --enable-readline \
        --enable-select \
        --enable-separate-helpfiles \
        --enable-mem-scramble && \
    make && \
    make install DESTDIR=/tmp/bash_install

# Remove the system cscope and rebuild it ourselves.
# This will bring us from version 15.8 -> 15.9.
# But more importantly, we have stolen the patches from the Ubuntu cscope
# deb, patches which fix the problem of cscope not recognizing functions
# which take functions as arguments.
# This fix adds a lot of functions in the Linux kernel to the index that
# cscope produces.
FROM main AS cscope
COPY cscope /tmp/cscope
ARG CSCOPE_VER=15.9
RUN yum erase -y cscope && \
    cd /tmp/cscope && \
    tar xf cscope-${CSCOPE_VER}.tar.gz && \
    cd cscope-${CSCOPE_VER} && \
    for p in ../patches/*.patch; do patch -p1 < "$p"; done && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/cscope_install


###
### END intermediate multi-stage build layers
###


FROM main
# Not ideal having to copy over the RPM, since it will still stick around
COPY --from=binutils /tmp/binutils_install /tmp/binutils/
RUN  if ! rpm -U --force /tmp/binutils/binut*.rpm; then \
    echo "Failed to install binutils RPM" >&2; \
    exit 1; \
    fi && rm -rf /tmp/binutils/
COPY --from=bash /tmp/bash_install /
COPY --from=cscope /tmp/cscope_install /

COPY vimrc /tmp/vimrc
COPY dracut.conf /etc/dracut.conf

ARG VER=1
ARG ZIP_FILE=add-user-to-sudoers.zip
RUN wget -nv "https://github.com/starlab-io/add-user-to-sudoers/releases/download/${VER}/${ZIP_FILE}" && \
    unzip "${ZIP_FILE}" && \
    rm "${ZIP_FILE}" && \
    mkdir -p /usr/local/bin && \
    mv add_user_to_sudoers /usr/local/bin/ && \
    mv startup_script /usr/local/bin/ && \
    chmod 4755 /usr/local/bin/add_user_to_sudoers && \
    chmod +x /usr/local/bin/startup_script && \
    # install some nice defaults for vim and bash
    cat /tmp/vimrc >> /etc/vimrc && \
    rm /tmp/vimrc && \
    # Let regular users be able to use sudo
    echo $'auth       sufficient    pam_permit.so\n\
account    sufficient    pam_permit.so\n\
session    sufficient    pam_permit.so\n\
' > /etc/pam.d/sudo

ENV LC_ALL=en_US.utf-8
ENV LANG=en_US.utf-8

ENTRYPOINT ["/usr/local/bin/startup_script"]
CMD ["/bin/bash", "-l"]
