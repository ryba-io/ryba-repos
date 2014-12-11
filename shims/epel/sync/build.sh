#!/bin/sh

cd `dirname ${BASH_SOURCE}`
docker build -t ryba/repo_epel_sync .

