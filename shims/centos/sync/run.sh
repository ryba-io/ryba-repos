#!/bin/sh

docker run --name 'ryba_repo_centos' -it --rm -v /opt/repo_centos:/var/www/html ryba/repo_centos_sync

