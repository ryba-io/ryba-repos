#!/bin/sh

docker run --name repo_centos -d -v /opt/repo_centos:/var/www/html/public -p 10180:80 avalawn/docker-httpd:latest

