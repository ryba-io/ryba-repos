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
  fs.writeFile "#{dirpath}/config.json", JSON.stringify(config, null, 2)

list = (repos) ->
  fs.readdir dirpath, (err, dir) ->
    dir = multimatch dir, repos if repos?
    for file in dir
      console.log file if file isnt 'config.json'

setPort = (repo, port) ->
  if port?
    config[repo] = port
  else
    config[repo] = config.next_port
    config.next_port++
  fs.writeFile "#{dirpath}/config.json", JSON.stringify(config, null, 2)
  return port

buildAssetsFiles = (repo,u,config, next) ->
  url_path = url.parse(u).pathname
  url_name = url_path.split '/'
  url_name = url_name[url_name.length-1]
  repopath = "#{dirpath}/#{repo}"
  buf  = '#!/bin/bash\n'
  buf += 'set -e\n\n'
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
  fs.writeFile "#{repopath}/init", buf, () ->
    fs.chmod "#{repopath}/init", next

syncRepo = (repo, u, port) ->
  repopath = "#{dirpath}/#{repo}"
  fs.exists "#{repopath}/init", (exists) ->
    do_end = () ->
      exec "docker run -v #{repopath}:/var/ryba --rm=true ryba_repos/syncer", (r_err, r_stdout, r_stderr) ->
        if r_err then console.log r_stderr
        dockerRun repo, port
    if exists and not u?
      do_end()
    else
      return Error 'Cannot create repo without remote repo url' unless u? 
      options = {url: u}
      http options, (err, response, body) ->
        ini.parse body, (err, inidata) ->
          fs.mkdir repopath, () ->
            buildAssetsFiles repo, u, inidata, do_end

sync = (repos, urls, ports) ->
  return Error "repos number (#{repos.length}) and urls number (#{urls?.length}) don't match" if urls? and repos.length isnt urls.length
  return Error "repos number (#{repos.length}) and ports number (#{ports?.length}) don't match" if ports? and repos.length isnt ports.length
  each(repos)
  .parallel true
  .on 'item', (repo, index, next) ->
    syncRepo repo, urls?[index], ports?[index]
  .on 'both', (err) ->
    if err then console.log 'Finished with errors :', err.message else console.log 'Finished successfully !'

dockerExec = (action, repo, callback) ->
  exec "docker #{action} repo_#{arg}", callback

dockerRun = (repo, port, callback) ->
    setPort repo, port
    exec "docker run --name=repo_#{repo} -d -v #{dirpath}/#{repo}:/usr/local/apache2/htdocs/ -p #{port}:80 httpd", callback

start = (repos, ports) ->
  startEach = (r) ->
    each(r)
    .parallel true
    .on 'item', (repo, index, next) ->
      if ports?[index]
        port = parseInt ports[index]
        if config[repo]?
          if config[repo] isnt port
            dockerExec 'stop', repo, (err) ->
              dockerExec 'rm', repo, (err) -> dockerRun repo, port
          else dockerExec 'start', repo
        else dockerRun repo, port
      else dockerExec 'start', repo
    .on 'both', (err) ->
      if err then console.log 'start finished with errors' else console.log "start finished successfully !"
  if repos?
    return Error "wrong arguments, please ignore ports or set it for each repo" if ports? and repos.length isnt ports.length
    startEach repos
  else
    exec "docker ps -a | grep -oh 'repo_\\S\\+'", (err, stdout, stderr) ->
      if err
        console.log "Impossible to list repo docker containers: #{stderr}"
      else
        repos = stdout.split '\n'
        repos.pop()
        startEach repos

stop = (repos) ->
  stopEach = (r) ->
    each(r)
    .parallel true
    .on 'item', (repo, index, next) ->
      dockerExec 'stop', repo
    .on 'both', (err) ->
      if err then console.log 'Finished with ERRORS' else console.log "stop finished successfully !"
  if repos?
    stopEach repos
  else
    exec "docker ps | grep -oh 'repo_\\S\\+'", (err, stdout, stderr) ->
      if err
        console.log "Impossible to list running repo docker containers: #{stderr}"
      else
        repos = stdout.split '\n'
        repos.pop()
        stopEach repos

del = (repos) ->
  each(repos)
  .parallel true
  .on 'item', (repo,next) ->
    dockerExec 'rm', repo, () -> rm.remove "#{dirpath}/#{repo}"
  .on 'both', (err) ->
    if err then  console.log "Finished with ERRORS" else console.log 'Finished successfully!'

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
      description: 'repo name filter(s)'
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
      required: false
      description: 'the url(s) of the repo(s)'
    ,
      name: 'port'
      shortcut: 'p'
      type: 'array'
      required: false
      description: 'force port value'
    ]
  ,
    name: 'start'
    description: 'Start Repo server(s) with Docker'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      description: 'the repo(s) to start. All by default'
    ,
      name: 'port'
      shortcut: 'p'
      type: 'array'
      description: 'force port value'
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
      description: 'the repo(s) to delete'
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

arg = params.parse argTab

switch arg.command
  when 'help' then console.log params.help arg.name
  when 'list' then list arg.repo
  when 'sync' then sync arg.repo, arg.url, arg.port
  when 'start' then start arg.repo, arg.port
  when 'stop' then stop arg.repo
  when 'rm' then del arg.repo