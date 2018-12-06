FROM centos:6.7
MAINTAINER David Esler <david.esler@starlab.io>

RUN mkdir /source

RUN yum groupinstall -y 'Development Tools' &&\
    yum install -y git openssl centos-release-scl && \
    yum install -y python27 && \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

ENV PATH /opt/rh/python27/root/usr/bin:${PATH}
ENV LD_LIBRARY_PATH /opt/rh/python27/root/usr/lib64/

VOLUME ["/source"]
WORKDIR /source
CMD ["/bin/bash"]
