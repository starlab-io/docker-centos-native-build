FROM centos:6.7
MAINTAINER David Esler <david.esler@starlab.io>

RUN mkdir /source

# Add the proxy cert
RUN update-ca-trust force-enable
ADD proxy.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust extract

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
