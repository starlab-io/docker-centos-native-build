FROM starlabio/centos-base:1.2
MAINTAINER Doug Goldstein <doug@starlab.io>

# setup linkers for Cargo
RUN mkdir -p /root/.cargo/

ENV PATH "/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# install rustup
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && sh ./rustup-install.sh  -y && rm rustup-install.sh

# Install x86_64 Rust
RUN rustup default 1.15.1-x86_64-unknown-linux-gnu

# Install rustfmt / cargo fmt for testing
RUN cargo install --root /usr/local rustfmt --vers 0.8.0

# Install yum-plugin-ovl to work around issue with a bad
# rpmdb checksum
RUN yum install -y yum-plugin-ovl && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install xxd and attr utilities
RUN yum install -y vim-common attr && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install libffi
RUN yum install -y libffi libffi-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install CONFIG_STACK_VALIDATION dependencies
RUN yum install -y elfutils-libelf-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

# Install Matplotlib dependencies
RUN yum install gcc gcc-c++ python-devel freetype-devel libpng-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/* && \
    pip install matplotlib

# Ensure that xattr is present
RUN pip install xattr

# Install dracut and its depends
RUN yum install -y dracut-network nfs-utils && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

COPY dracut.conf /etc/dracut.conf
