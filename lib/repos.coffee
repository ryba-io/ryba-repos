#!/usr/bin/env coffee

fs = require 'fs'
parameters = require 'parameters'
path = require 'path'
rm = require 'remove'
multimatch = require 'multimatch'
exec = require('child_process').exec
each = require 'each'
url = require 'url'
ini = require 'my-node-ini'
http = require 'request'
util = require 'util'

#Ajout de la fonction diff pour les tableaux  
#Array.prototype.diff = (a) ->
#  return @filter((i) ->
#    return a.indexOf(i) < 0
#  )

dirpath = path.normalize "#{path.dirname process.argv[1]}/../shims"
#Port par défaut
default_port = 100180

list = (repos) ->
  if repos?
    dir = multimatch fs.readdirSync(dirpath), repos
  else
    dir = fs.readdirSync dirpath
  console.log file for file in dir

getNewPort = () ->
  port_path = "#{dirpath}/../port_inc.conf"
  if fs.existsSync port_path
    port = parseInt fs.readFileSync port_path
  else
    port = default_port
  fs.writeFileSync port_path, "#{port+1}"
  return port

buildAssetsFiles = (repo,u,config) ->
  url_path = url.parse(u).pathname
  url_name = url_path.split '/'
  url_name = url_name[url_name.length-1]
  
  repopath = "#{dirpath}/#{repo}"
  fs.mkdirSync "#{repopath}/assets"
  buf  = '#!/bin/bash\n'
  buf += 'set -e\n\n'
  # buf += 'if [ -n "$1" ]; then\n'
  # buf += '  export http_proxy="$1"\n'
  # buf += 'elif [ -n "$http_proxy" ]; then\n'
  # buf += '  unset http_proxy\n'
  # buf += 'fi\n\n'
  buf += 'yum clean expire-cache\n'
  sync = buf;
  buf += "wget -nv #{u} -O /etc/yum.repos.d/#{url_name}\n"
  buf += 'yum update -y\n'
  sync += 'yum update -y\n'
  Object.keys(config).forEach((element, key, _array) ->
    path = url.parse(config[element].baseurl).pathname
    buf += "\n# [#{element}]\n"
    sync+= "\n# [#{element}]\n"
    buf += "mkdir -p /var/www/html#{path}\n"
    buf += "reposync -p /var/www/html#{path} --repoid=#{element}\n"
    sync+= "reposync -p /var/www/html#{path} --repoid=#{element}\n"
    buf += "createrepo /var/www/html#{path}\n"
  )
  fs.writeFileSync "#{repopath}/assets/init", buf
  fs.chmodSync "#{repopath}/assets/init", 0o755
  fs.writeFileSync "#{repopath}/assets/sync", sync
  fs.chmodSync "#{repopath}/assets/sync", 0o755

_runRepo = (repo,init) ->
  repopath = "#{dirpath}/#{repo}"
  if init
    port = getNewPort()
    fs.writeFileSync "#{repopath}/port", port
    app='init'
  else
    port = fs.readFileSync "#{repopath}/port"
    app='sync'  
  exec "docker run -v #{repopath}/assets/:/app/ -v #{repopath}/repo:/var/www/html/ --rm=true --entrypoint /app/#{app} ryba_repos/syncer", (r_err,r_stdout,r_stderr) ->
    if r_err then console.log r_stderr
    else exec "docker run --name=repo_#{repo} -d -v #{repopath}/repo:/usr/local/apache2/htdocs/ -p #{port}:80 httpd", (err,stdout,stderr) ->
      if err then console.log stderr

initRepo = (repo, u, proxy) ->
  repopath = "#{dirpath}/#{repo}"
  fs.exists repopath, (exists) ->
    if exists
      console.log "[#{repo}] repo already exists, ignoring configuration step"
      _runRepo repo,false
    else
      console.log "[#{repo}] creating configuration files..."
      options = {url: u}
      options.proxy = proxy if proxy
      http options, (err, response, body) ->
        config = ini.parse body
        fs.mkdir repopath, () ->
          buildAssetsFiles repo, u, config
          fs.mkdir "#{repopath}/repo", () ->
            console.log "[#{repo}] end of configuration files creation"
            _runRepo repo,true

sync = (repos) ->
  repos = fs.readdirSync(dirpath) unless repos?
  each(repos)
  .parallel true
  .on 'item', (repo,next) ->
    _runRepo repo, false
  .on 'both', (err) ->
    if err then console.log 'Finished with ERRORS' else console.log 'Finished successfully!'

init = (repos,urls,proxy) ->
  if repos.length isnt urls?.length
    console.log "targetted repos number (#{repos.length}) and urls number (#{urls?.length}) don't match, exiting..." 
    process.exit 22      # Linux Invalid argument errCode
  each(repos)
  .parallel true
  .on 'item', (repo, index, next) ->
    initRepo repo, urls?[index],proxy
  .on 'both', (err) ->
    if err then console.log 'Finished with errors :',err.message else console.log 'Finished successfully !'
  
_dockerExec = (repos,action) ->
  console.log "#{action} #{repos}:"
  each repos
  .parallel true
  .on 'item', (repo,next) ->
    exec "docker #{action} #{repo}", (err, stdout, stderr) ->
      console.log "[#{repo}]: #{stderr}"
  .on 'both', (err) ->
    if err then console.log '#{action} finished with errors' else console.log '#{action} finished successfully !'

start = (repos) ->
  if repos?
    for repo, i in repos
      repos[i] = "repo_#{repo}"
    _dockerExec repos, 'start'
  else
    exec "docker ps -a | grep -oh 'repo_\\S\\+'", (err, stdout, stderr) ->
      if err
        console.log "Impossible to list repo docker containers: #{stderr}"
      else
        repos = stdout.split '\n'
        repos.pop()
        _dockerExec repos, 'start'

stop = (repos) ->
  if repos?
    for repo, i in repos
      repos[i] = "repo_#{repo}"
    _dockerExec repos, 'stop'
  else
    exec "docker ps | grep -oh 'repo_\\S\\+'", (err, stdout, stderr) ->
      if err
        console.log "Impossible to list running repo docker containers: #{stderr}"
      else
        repos = stdout.split '\n'
        repos.pop()
        _dockerExec repos, 'stop'

del = (repos) ->
  each(repos)
  .parallel true
  .on 'item', (repo,next) ->
    exec "docker rm repo_#{repo}", (err,stdout,stderr) ->
      console.log "[#{repo}] #{stderr}" if err?
    rm.removeSync "#{dirpath}/#{repo}"
  .on 'both', (b_err) ->
    if b_err then console.log "Finished with ERRORS" else console.log 'Finished successfully!'

params = parameters
  name: 'repos'
  description: 'Install and sync RHEL/CentOS repositories'
  commands: [
    name: 'list'
    description: 'list all the installed repositories'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      description: 'filter'
    ]
  ,
    name: 'init'
    description: 'initialize local repo with Docker container'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      required: true
      description: 'repo(s) to initialize'
    ,
      name: 'url'
      type: 'array'
      shortcut: 'u'
      required: true
      description: 'the url(s) of the repo(s)'
    ,
      name: 'proxy'
      shortcut: 'p'
      description: 'a proxy parameter if needed'
    ]
  ,
    name: 'start'
    description: 'Start Repo server(s) with Docker without synchronizing repo'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      description: 'the repo(s) to start. All by default'
    ]
  ,
    name: 'stop'
    description: 'Stop Repo server(s) with Docker'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      description: 'the repo(s) to stop. All by default'
    ]
  ,
    name: 'rm'
    description: 'Delete a repo'
    options: [
      name: 'repo'
      shortcut: 'r'
      type: 'array'
      required: true
      description: 'the repo to delete'
    ]
  ]

#On créé ./repos COMMAND [OPTIONS] -r REPO [OPTIONS] depuis ./repos COMMAND [OPTIONS] REPO [OPTIONS] -> 
argTab = process.argv.slice 2, process.argv.length
if argTab.length > 1 and '-r' not in argTab
  count=0
  for arg,i in argTab
    if '-' is arg.charAt 0
      count = 0
    else
      count++
      if count is 2
        argTab.splice i, 0, '-r'
        break

arg = params.parse(argTab);

console.log params.help arg.name if arg.command is 'help'

switch arg.command
  when 'list' then list arg.repo
  when 'init' then init arg.repo, arg.url, arg.proxy
  when 'sync' then sync arg.repo, arg.proxy
  when 'start' then start arg.repo
  when 'stop' then stop arg.repo
  when 'rm' then del arg.repo
