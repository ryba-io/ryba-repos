#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
rmr = require 'remove'
multimatch = require 'multimatch'
exec = require('child_process').exec
each = require 'each'
url = require 'url'
ini = require 'node-ini'
http = require 'request'
utils = require './utils'

dirpath = path.normalize "#{path.dirname process.argv[1]}/../public"

exports.list = (repos, obj, callback) ->
  if arguments.length is 2
    callback = obj
    obj = false
  fs.readFile "#{dirpath}/config.json", 'utf8', (err, config) ->
    return callback err if err
    try config = JSON.parse config
    catch err then return callback err
    fs.readdir dirpath, (err, dirs) ->
      return callback err if err
      if repos?.length
      then names = repos
      else names = ['*']
      names.push '!config.json'
      dirs = multimatch dirs, names
      repos = {}
      for dir in dirs
        repos[dir] = name: dir, port: config[dir]?.port
      utils.docker_ps true, (err, infos) ->
        return callback err if err
        for name, repo of repos
          repo.docker = infos[name] or {}
        unless obj then repos = for _, repo of repos then repo
        callback null, repos

setPort = (repo, callback) ->
  fs.readFile "#{dirpath}/config.json", 'utf8', (err, config) ->
    return callback err if err and err.code isnt 'ENOENT'
    config = if err then {} else JSON.parse config 
    config.port_inc ?= 10180
    unless repo.port?
      repo.port = config.port_inc++
      changed = true
    else  if config[repo.name]?.port isnt repo.port?
      config[repo.name] ?= {}
      config[repo.name].port = repo.port
      changed = true
    return callback() unless changed
    fs.writeFile "#{dirpath}/config.json", JSON.stringify(config, null, 2), (err) ->
      callback err

exports.sync = (repos, callback) ->
  return Error "repos number (#{repos.length}) and urls number (#{urls?.length}) don't match" if urls? and repos.length isnt urls.length
  return Error "repos number (#{repos.length}) and ports number (#{ports?.length}) don't match" if ports? and repos.length isnt ports.length
  each repos
  .parallel true
  .run (repo, next) ->
    ports = []
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
                data = utils.build_assets repo.name, repo.url, inidata
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
  .then callback

exports.start = (repos, callback) ->
  exports.list (repos.map (r) -> r.name), true, (err, registered_repos) ->
    return callback err if err
    for repo in repos
      registered_repos[repo.name].port = repo.port if repo.port?
    each registered_repos
    .parallel true
    .run (repo, next) ->
      unless repo.docker.names # Unregistered container
        utils.docker_run repo, dirpath, (err) ->
          return next err
      else if /^Up/.test repo.docker.status # Running container
        return next() if "#{repo.port}" is /([\d]+)\->80/.exec(repo.docker.ports)?[1]
        return utils.docker_exec repo.name, 'stop', (err) ->
          return next err if err
          utils.docker_exec repo.name, 'rm', (err) ->
            return next err if err
            utils.docker_run repo, dirpath, (err) ->
              return next err if err
              setPort repo, (err) ->
                next err
      else # Stoped container
        utils.docker_exec repo.name, 'start', (err) ->
          next err
    .then (err) ->
      callback err

exports.stop = (repos, callback) ->
  exports.list repos, true, (err, repos) ->
    return callback err if err
    each repos
    .run (repo, next) ->
       return next() unless /^Up/.test repo.docker?.status
       utils.docker_exec repo.name, 'stop', next
    .then callback

exports.remove = (repos, callback) ->
  each repos
  .parallel true
  .run (repo, next) ->
    utils.docker_exec repo, 'rm', (err) ->
      return next err if err
      rmr.remove "#{dirpath}/#{repo}", next
  .then callback


