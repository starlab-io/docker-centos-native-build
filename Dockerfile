FROM centos:6.7
MAINTAINER David Esler <david.esler@starlab.io>

RUN mkdir /source

RUN yum groupinstall -y 'Development Tools' &&\
    yum install -y git openssl && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

VOLUME ["/source"]
WORKDIR /source
CMD ["/bin/bash"]
