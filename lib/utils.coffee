
url = require 'url'
exec = require('child_process').exec

exports.build_assets = (repo, config) ->
  url_path = url.parse(repo.url).pathname
  url_name = url_path.split '/'
  url_name = url_name[url_name.length-1]
  buf  = '#!/bin/bash\n'
  buf += 'set -e\n\n'
  buf += 'yum clean expire-cache\n'
  buf += "wget -nv #{repo.url} -O /etc/yum.repos.d/#{url_name}\n"
  buf += 'yum update -y\n'
  for key, element of config
    directory = url.parse(element.baseurl).pathname
    buf += "\n# [#{element.name}]\n"
    buf += "mkdir -p /var/ryba#{directory}\n"
    buf += "reposync -p /var/ryba#{directory} --repoid=#{key}\n"
    buf += "createrepo /var/ryba#{directory}\n"
  buf

exports.lines = (str) ->
  str.split /\r\n|[\n\r\u0085\u2028\u2029]/g
