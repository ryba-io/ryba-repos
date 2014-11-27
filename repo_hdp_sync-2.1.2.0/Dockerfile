FROM centos:centos6
RUN curl http://s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.1.2.0/hdp.repo -o /etc/yum.repos.d/hdp-2.1.2.0.repo
RUN yum clean expire-cache
RUN yum install -y createrepo gnupg yum-utils expect
VOLUME ["/var/www/html"]
ADD assets/init /app/init
RUN chmod 755 /app/init
ENTRYPOINT ["/app/init"]
CMD []
