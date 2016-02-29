
url = require 'url'
exec = require('child_process').exec

exports.build_assets = (repo, config) ->
  url_path = url.parse(repo.url).pathname
  url_name = url_path.split '/'
  url_name = url_name[url_name.length-1]
  buf  = '#!/bin/bash\n'
  buf += 'set -e\n\n'
  buf += 'yum clean expire-cache\n'
  # buf += "wget -nv #{repo.url} -O /etc/yum.repos.d/#{url_name}\n"
  buf += 'yum update -y\n'
  for key, element of config
    directory = url.parse(element.baseurl).pathname
    buf += "\n# [#{element.name}]\n"
    buf += "mkdir -p /var/ryba#{directory}\n"
    buf += "reposync -p /var/ryba#{directory} --repoid=#{key}\n"
    buf += "createrepo /var/ryba#{directory}\n"
  buf

# Rewrite base url of the .repo file in order to map the public directory repo-base layout
# eg 'https://repo.mongodb.org/yum/redhat/6/mongodb-org/3.2/x86_64/' is replaced by
# 'https://repo.mongodb.org/mongodb_3.2/yum/redhat/6/mongodb-org/3.2/x86_64/'
exports.buid_custom_repo_file = (repo, config) ->
  for _,conf of config
    infos = url.parse(conf.baseurl)
    conf.mirrorlist = conf.mirrorlist.replace "#{infos.hostname}" , "#{infos.hostname}/#{repo.name}" if conf.mirrorlist
    conf.baseurl = conf.baseurl.replace "#{infos.hostname}" , "#{infos.hostname}/#{repo.name}" if conf.baseurl
  config
    

exports.lines = (str) ->
  str.split /\r\n|[\n\r\u0085\u2028\u2029]/g
