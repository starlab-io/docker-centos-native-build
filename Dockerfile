
# RHEL/Alma release version
ARG releasever=8.5
FROM almalinux:$releasever

LABEL maintainer="Star Lab <info@starlab.io>"

RUN mkdir /source

# Pin release version
ARG releasever
RUN echo $releasever > /etc/dnf/vars/releasever

# Install EPEL
RUN yum update -y && yum install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/* && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled powertools

# Install basic build dependencies
RUN yum update -y && yum install -y \
    git kernel-devel wget openssl openssl-devel python3 python3-devel python3-docutils \
    audit-libs-devel bc binutils-devel dwarves elfutils-devel \
    java-devel kabi-dw libbabeltrace-devel libbpf-devel libcap-devel \
    libcap-ng-devel llvm-toolset ncurses-devel net-tools newt-devel \
    numactl-devel pciutils-devel perl perl-devel rsync xmlto xz-devel zlib-devel && \
    yum group install -y "Development Tools" && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

RUN yum update -y && yum install -y \
    # Install xxd and attr utilities
    # Install CONFIG_STACK_VALIDATION dependencies
    # Install which required to build RedHawk 6 OpenOnLoad subsystem
    # Install lz4 (for building systemd)
    vim-common attr libffi libffi-devel \
    elfutils-libelf-devel gcc gcc-c++ freetype-devel \
    libpng-devel lz4-devel dracut-network nfs-utils trousers-devel \
    libtool which libmnl-devel bpftool \
    # Support for CONFIG_GCC_PLUGINS
    gcc-plugin-devel.x86_64 \
    # Install Xen build dependencies
    libidn-devel zlib-devel SDL-devel curl-devel \
    libX11-devel gtk2-devel libaio-devel iasl \
    gettext gnutls-devel pciutils-devel libuuid-devel \
    bzip2-devel xz-devel e2fsprogs e2fsprogs-devel yajl-devel mingw64-binutils \
    systemd-devel glibc-devel.i686 texinfo \
    bzip2-devel.i686 zlib-devel.i686 openssl-devel.i686 \
    python3-libselinux libselinux-utils libselinux-devel \
    libselinux-devel.i686 \
    # Install checkpolicy for XSM Xen
    checkpolicy \
    # Install grub2 build dependencies
    device-mapper-devel freetype-devel gettext-devel texinfo \
    dejavu-sans-fonts help2man libusb-devel rpm-devel glibc-static.x86_64 \
    glibc-static.i686 autogen \
    # Install yum-utils
    yum-utils \
    # Add check and JSON dependencies
    check check-devel check.i686 check-devel.i686 \
    valgrind json-c-devel cppcheck \
    # Install tpm2
    tpm2-tss-devel \
    # Add libraries for building cryptsetup and friends
    libgcrypt-devel libpwquality-devel libblkid-devel \
    # Add tools for building the driverdomain image
    squashfs-tools \
    # Add ccache for development use
    ccache \
    # Install x86 32-bit gcc libs
    libgcc.i686 \
    # Install yum dependencies for ronn
    ruby-devel \
    # Various systemd build requirements
    gperf libcap-devel libmount-devel meson libseccomp-devel libacl-devel kmod-devel \
    pam-devel libmicrohttpd-devel cryptsetup-devel iptables-devel libxkbcommon-devel \
    # Add rpmsign and createrepo for building the Yum release repos
    gpg createrepo rpm-sign \
    libxslt-devel libxml2-devel libyaml-devel \
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
    # quilt for patching
    quilt \
    # clang analyzer/scan-build
    clang-analyzer \
    # Update the ssl certs
    ca-certificates \
    # For running release tests
    expect \
    # parallel
    parallel && \
    # Cleanup
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/* && \
    # lcov
    rpm -ivh http://downloads.sourceforge.net/ltp/lcov-1.14-1.noarch.rpm

# build dependencies in powertools repo
RUN yum install -y --enablerepo=powertools execstack glibc-static && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/etc/local/cargo/rustup

# install rustup in a globally accessible location
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && \
    umask 020 && sh ./rustup-install.sh -y --default-toolchain 1.61.0-x86_64-unknown-linux-gnu && \
    rm rustup-install.sh && \
                            \
    # Install rustfmt / cargo fmt for testing
    rustup component add rustfmt && \
    rustup component add clippy-preview && \
    cargo install ripgrep --locked && \
    # We need nightly to be able to use cargo udeps. Installing it like this does not make it default
    rustup install nightly && \
    cargo install cargo-udeps --locked

# Setup the i686 target for rust
RUN rustup target add i686-unknown-linux-gnu

# Ugly, but required for successful i686 build
RUN ln -sf /usr/bin/strip /usr/bin/i686-linux-gnu-strip

# install the cargo license checker
RUN cargo install cargo-license --locked

RUN pip3 install --upgrade pip && \
    pip3 install numpy xattr requests behave pyhamcrest matplotlib

RUN alternatives --set python /usr/bin/python3

# Install ronn for generating man pages
RUN gem install ronn

# Set digest algorithms to be NIAP compatible (SHA256)
RUN echo "%_source_filedigest_algorithm 8" >> /etc/rpm/macros && \
    echo "%_binary_filedigest_algorithm 8" >> /etc/rpm/macros && \
    echo "%_smp_ncpus_max 0" >> /etc/rpm/macros && \
    echo "%_source_payload  w6T0.xzdio" >> /etc/rpm/macros && \
    echo "%_binary_payload  w6T0.xzdio" >> /etc/rpm/macros && \
    echo "%_unpackaged_files_terminate_build 0" >> /etc/rpm/macros

# Install shellcheck
ARG SHELLCHECK_VER=v0.7.0
RUN wget -nv https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VER}/shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz && \
    tar xf shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz && \
    install shellcheck-${SHELLCHECK_VER}/shellcheck /usr/local/bin && \
    rm shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz && \
    rm -r shellcheck-${SHELLCHECK_VER}

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

ENV LC_ALL=C.utf-8
ENV LANG=C.utf-8

VOLUME ["/source"]
WORKDIR /source
ENTRYPOINT ["/usr/local/bin/startup_script"]
CMD ["/bin/bash", "-l"]
