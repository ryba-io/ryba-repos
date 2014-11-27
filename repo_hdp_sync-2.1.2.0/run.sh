#!/bin/sh

docker run --name='repo_hdp_sync-2.1.2.0' -it --rm -v /opt/repo_hdp-2.1.2.0:/var/www/html ryba/repo_hdp_sync-2.1.2.0
