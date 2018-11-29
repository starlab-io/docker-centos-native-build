FROM centos:6.7
MAINTAINER David Esler <david.esler@starlab.io>

RUN yum groupinstall -y 'Development Tools'
