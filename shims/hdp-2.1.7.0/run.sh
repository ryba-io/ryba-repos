#!/bin/sh

docker run --name repo_hdp-2.1.7.0 -d -v /opt/repo_hdp-2.1.7.0:/var/www/html/public -p 10185:80 avalawn/docker-httpd:latest

