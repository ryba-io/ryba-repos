#!/bin/sh

docker run --name 'repo_epel_sync' -it --rm -v /opt/repo_epel:/var/www/html ryba/repo_epel_sync
