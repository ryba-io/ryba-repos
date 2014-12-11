#!/bin/sh

docker run --name='repo_ambari_sync-1.6.1' -it --rm -v /opt/repo_ambari_sync-1.6.1:/var/www/html ryba/repo_ambari_sync-1.6.1
