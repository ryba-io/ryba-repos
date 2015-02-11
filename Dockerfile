# (sudo) docker build -t ryba_repos/syncer .
FROM centos:centos6

RUN yum clean expire-cache
RUN yum update -y
RUN yum install -y createrepo gnupg yum-utils expect wget
VOLUME ["/var/ryba"]
ENTRYPOINT ["/var/ryba/init"]
