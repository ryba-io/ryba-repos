#!/usr/bin/env coffee

fs = require 'fs'
parameters = require 'parameters'
path = require 'path'
rm = require 'remove'
multimatch = require 'multimatch'
exec = require('child_process').exec
each = require 'each'
url = require 'url'
ini = require 'node-ini'
http = require 'request'
util = require 'util'

dirpath = path.normalize "#{path.dirname process.argv[1]}/../public"
try
  config = require "#{dirpath}/config"
catch e
  console.log e
  config =
    next_port: 10180
  fs.writeFileSync "#{dirpath}/config.json", JSON.stringify config, null, 2

#Ajout de la fonction diff pour les tableaux  
#Array.prototype.diff = (a) ->
#  return @filter((i) ->
#    return a.indexOf(i) < 0
#  )

#Port par défaut

list = (repos) ->
  if repos?
    dir = multimatch fs.readdirSync(dirpath), repos
  else
    dir = fs.readdirSync dirpath
  console.log file for file in dir

setPort = (repo, port) ->
  if port?
    config[repo] = port
  else
    config[repo] = config.next_port
    config.next_port++

  fs.writeFileSync "#{dirpath}/config.json", JSON.stringify config, null, 2
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
  buf += "wget -nv #{u} -O /etc/yum.repos.d/#{url_name}\n"
  buf += 'yum update -y\n'
  Object.keys(config).forEach((element, key, _array) ->
    path = url.parse(config[element].baseurl).pathname
    buf += "\n# [#{element}]\n"
    buf += "mkdir -p /var/ryba#{path}\n"
    buf += "reposync -p /var/ryba#{path} --repoid=#{element}\n"
    buf += "createrepo /var/ryba#{path}\n"
  )
  fs.writeFileSync "#{repopath}/assets/init", buf
  fs.chmodSync "#{repopath}/assets/init", 0o755


syncRepo = (repo, u, port) ->
  repopath = "#{dirpath}/#{repo}"
  fs.exists repopath, (exists) ->
    do_end = () ->
        exec "docker run -v #{repopath}/assets/:/app/ -v #{repopath}:/var/ryba --rm=true --entrypoint /app/init ryba_repos/syncer", (r_err, r_stdout, r_stderr) ->
          if r_err then console.log r_stderr
    if exists
      do_end()
    else
      options = {url: u}
      http options, (err, response, body) ->
        inifile = ini.parse body
        fs.mkdir repopath, () ->
          buildAssetsFiles repo, u, inifile
          do_end()

sync = (repos, urls, ports) ->
  if repos.length isnt urls?.length
    console.log "targetted repos number (#{repos.length}) and/or urls number (#{urls?.length}) and/or ports number (#{ports?.length}) don't match, exiting..." 
    process.exit 22      # Linux Invalid argument errCode
  each(repos)
  .parallel true
  .on 'item', (repo, index, next) ->
    syncRepo repo, urls?[index], ports?[index]
  .on 'both', (err) ->
    if err then console.log 'Finished with errors :',err.message else console.log 'Finished successfully !'
  
_dockerExec = (repos,action, port) ->
  console.log "#{action} #{repos}:"
  each repos
  .parallel true
  .on 'item', (repo,next) ->
    do_end = () ->
      exec "docker #{action} #{repo}", (err, stdout, stderr) ->
        console.log "[#{repo}]: #{stderr}"
    if action is 'start'
      if !config[repo]? or port?
        setPort repo, port
        exec "docker run --name=repo_#{repo} -d -v #{dirpath}/#{repo}:/usr/local/apache2/htdocs/ -p #{config[repo]}:80 httpd", (err,stdout,stderr) ->
          if err then console.log stderr
      else do_end()
    else
      do_end()
  .on 'both', (err) ->
    if err then console.log '#{action} finished with errors' else console.log '#{action} finished successfully !'

start = (repos) ->
  if repos?
    for repo, i in repos
      repos[i] = "repo_#{repo}"
      _dockerExec repo, 'start'
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
    name: 'sync'
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
      name: 'port'
      shortcut: 'p'
      required: false
      description: 'force port value'
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
  when 'sync' then sync arg.repo, arg.url, arg.port
  when 'start' then start arg.repo
  when 'stop' then stop arg.repo
  when 'rm' then del arg.repo
