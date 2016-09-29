FROM starlabio/centos-base:1.2
MAINTAINER Doug Goldstein <doug@starlab.io>

# setup linkers for Cargo
RUN mkdir -p /root/.cargo/

ENV PATH "/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# install rustup
RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && sh ./rustup-install.sh  -y && rm rustup-install.sh

# Install x86_64 Rust
RUN rustup default 1.12.0-x86_64-unknown-linux-gnu

# Install rustfmt / cargo fmt for testing
RUN cargo install --root /usr/local rustfmt --vers 0.5.0
