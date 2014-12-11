#!/bin/sh

docker run --name repo_hdp-2.1.4.0 -d -v /opt/repo_hdp-2.1.4.0:/var/www/html/public -p 10183:80 avalawn/docker-httpd:latest

