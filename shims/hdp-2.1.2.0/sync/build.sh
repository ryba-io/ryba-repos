#!/bin/sh

cd `dirname ${BASH_SOURCE}`
docker build -t ryba/repo_hdp_sync-2.1.2.0 .

