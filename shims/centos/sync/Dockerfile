FROM centos:centos6
RUN rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum install -y createrepo gnupg yum-utils expect
VOLUME ["/var/www/html"]
ADD assets/init /app/init
RUN chmod 755 /app/init
ENTRYPOINT ["/app/init"]
CMD []
