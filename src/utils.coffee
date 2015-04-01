
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
  console.log '------------------'
  console.log repo
  console.log config
  for key, element of config
    directory = url.parse(element.baseurl).pathname
    buf += "\n# [#{element.name}]\n"
    buf += "mkdir -p /var/ryba#{directory}\n"
    buf += "reposync -p /var/ryba#{directory} --repoid=#{key}\n"
    buf += "createrepo /var/ryba#{directory}\n"
  console.log buf
  buf

exports.docker_exec = (repo, action, callback) ->
  exec """
  if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
  docker #{action} #{repo}
  """, callback

exports.docker_run = (repo, pubdir, callback) ->
  exec """
  if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
  docker run -d \
    --name=#{repo.name} \
    -v #{pubdir}/#{repo.name}:/usr/local/apache2/htdocs/ \
    -p #{repo.port}:80 \
    httpd
  """, callback

exports.docker_ps = (obj, callback) ->
  if arguments.length is 1
    callback = obj
    obj = false
  child = exec """
  if command -v boot2docker >/dev/null; then boot2docker up >/dev/null 2>&1 && $(boot2docker shellinit); fi
  docker ps -a
  """, (err, stdout, stderr) ->
    return callback err if err
    column_names = []
    column_length = []
    infos = {}
    for line, i in exports.lines stdout
      continue if /^\s*$/.test line
      if i is 0
        re = /(\w+\s+|\w+$)/mg
        while match = re.exec line
          column_names.push match[1].trim().toLowerCase()
          column_length.push match[1].length
        continue
      from = 0
      info = {}
      for column, i in column_names
        info[column] = if i isnt column_names.length - 1
        then line.substr(from, column_length[i]).trim()
        else line.substr(from).trim()
        from += column_length[i]
      infos[info.names] = info
    unless obj then infos = for _, info of infos then info
    callback null, infos

exports.lines = (str) ->
  str.split /\r\n|[\n\r\u0085\u2028\u2029]/g
