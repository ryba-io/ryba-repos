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

printError = (err) -> console.log err if err?

dirpath = path.normalize "#{path.dirname process.argv[1]}/../public"
try
  config = require "#{dirpath}/config"
catch e
  console.log e
  config =
    next_port: 10180
  fs.writeFile "#{dirpath}/config.json", JSON.stringify(config, null, 2)

list = (repos, next) ->
  fs.readdir dirpath, (err, dir) ->
    repos ?= ['*']
    repos.push '!config.json'
    dir = multimatch dir, repos
    next err, dir

setPort = (repo, port) ->
  if port?
    config[repo] = port
  else
    config[repo] = config.next_port
    config.next_port++
  fs.writeFile "#{dirpath}/config.json", JSON.stringify(config, null, 2)
  return port

build_assets = (repo, config) ->
  url_path = url.parse(repo.url).pathname
  url_name = url_path.split '/'
  url_name = url_name[url_name.length-1]
  repopath = "#{dirpath}/#{repo.name}"
  buf  = '#!/bin/bash\n'
  buf += 'set -e\n\n'
  buf += 'yum clean expire-cache\n'
  buf += "wget -nv #{repo.url} -O /etc/yum.repos.d/#{url_name}\n"
  buf += 'yum update -y\n'
  for key, element of config
    path = url.parse(config[element].baseurl).pathname
    buf += "\n# [#{element}]\n"
    buf += "mkdir -p /var/ryba#{path}\n"
    buf += "reposync -p /var/ryba#{path} --repoid=#{element}\n"
    buf += "createrepo /var/ryba#{path}\n"

sync = (repos, callback) ->
  return Error "repos number (#{repos.length}) and urls number (#{urls?.length}) don't match" if urls? and repos.length isnt urls.length
  return Error "repos number (#{repos.length}) and ports number (#{ports?.length}) don't match" if ports? and repos.length isnt ports.length
  each(repos)
  .parallel true
  .on 'item', (repo, next) ->
    ports = []
    # syncRepo repo, urls?[index], ports?[index]
    repopath = "#{dirpath}/#{repo.name}"
    do_init = ->
      fs.exists "#{repopath}/init", (exists) ->
        return do_end() if exists #and not repo.url
        return Error 'Cannot create repo without remote repo url' unless repo.url? 
        http url: repo.url, (err, response, body) ->
          return callback err if err
          fs.mkdir repopath, (err) ->
            return callback err if err and err.code isnt 'EEXIST'
            fs.writeFile "#{repopath}/repo", body, (err) ->
              return callback err if err
              ini.parse "#{repopath}/repo", (err, inidata) ->
                return callback err if err
                data = build_assets repo.name, repo.url, inidata
                fs.writeFile "#{repopath}/init", data, (err) ->
                  return callback err if err
                  fs.chmod "#{repopath}/init", 0o0755, (err) ->
                    return callback err if err
                    do_end()
    do_end = ->
      exec """
      if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
      docker run -v #{repopath}:/var/ryba --rm=true ryba_repos/syncer
      """, (err, stdout, stderr) ->
        next err
    do_init()
  .on 'both', (err) ->
    if err then console.log 'Finished with errors :', err.message else console.log 'Finished successfully !'

dockerExec = (action, repo, callback) ->
  console.log action, repo
  exec """
  if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
  docker #{action} repo_#{repo}
  """, callback

dockerRun = (repo, port, callback) ->
  console.log "run new container: #{repo}"
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
            dockerExec 'stop', repo, (err) -> dockerExec 'rm', repo, (err) -> dockerRun repo, port, printError
          else dockerExec 'start', repo, printError
        else dockerRun repo, port, printError
      else dockerExec 'start', repo, printError
    .on 'both', (err) ->
      if err then console.log 'start finished with errors' else console.log "start finished successfully !"
  if repos?
    return Error "wrong arguments, please ignore ports or set it for each repo" if ports? and repos.length isnt ports.length
    startEach repos
  else
    list repos, (err, repos) ->
      if err
        console.log "Impossible to list repo docker containers: #{err}"
      else
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
    # ,
    #   name: 'port'
    #   shortcut: 'p'
    #   type: 'array'
    #   required: false
    #   description: 'force port value'
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
  when 'list' then list arg.repo, (err, dir) -> console.log file for file in dir
  when 'sync'
    {repo, url} = arg
    throw Error "Incoherent Arguments Length" if url.length and repo.length isnt url.length
    repo = for name, i in repo
      name: name, url: url[i]
    sync repo, (err) -> console.log err if err
  when 'start' then start arg.repo, arg.port
  when 'stop' then stop arg.repo
  when 'rm' then del arg.repo
