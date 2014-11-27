FROM centos:centos6
RUN curl http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.6.1/ambari.repo -o /etc/yum.repos.d/ambari-1.6.1.repo
RUN yum clean expire-cache
RUN yum install -y createrepo gnupg yum-utils expect
VOLUME ["/var/www/html"]
ADD assets/init /app/init
RUN chmod 755 /app/init
ENTRYPOINT ["/app/init"]
CMD []
