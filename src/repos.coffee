#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
rmr = require 'remove'
multimatch = require 'multimatch'
each = require 'each'
url = require 'url'
ini = require 'node-ini'
http = require 'request'
db = require './db'
docker = require './docker'
utils = require './utils'

module.exports = (options) ->
  new Repos options

class Repos

  constructor: (@options={}) ->
    @options.directory ?= './public'
    @options.directory = path.resolve process.cwd(), @options.directory
    @options.log ?= true
    @db = db @options.directory
    @docker = docker @options.debug


  list: (repos, obj, callback) ->
    if arguments.length is 2
      callback = obj
      obj = false
    @db.get (err, config) =>
      return callback err if err
      fs.readdir @options.directory, (err, dirs) =>
        return callback err if err
        if repos?.length
        then names = repos
        else names = ['*']
        names.push '!config.json'
        dirs = multimatch dirs, names
        repos = {}
        for dir in dirs
          repos[dir] = name: dir, port: config.repos[dir]?.port
        utils.docker_ps true, (err, infos) =>
          return callback err if err
          for name, repo of repos
            repo.docker = infos[name] or {}
          unless obj then repos = for _, repo of repos then repo
          callback null, repos

  setPort: (name, port, callback) ->
    # {name, port} = repo
    @db.get (err, config) =>
      return err if err
      unless config.repos[name]?
        config.repos[name] = {}
        changed = true
      unless port?
        ports_used = for k, v of config.repos then v.port
        port = config.port_inc
        while port in ports_used
          port++
        config.repos[name].port = port
        changed = true
      else if config.repos[name].port isnt port
        config.repos[name].port = port
        changed = true
      return callback() unless changed
      @db.set config, callback
   

  sync: (repos, callback) ->
    return Error "repos number (#{repos.length}) and urls number (#{urls?.length}) don't match" if urls? and repos.length isnt urls.length
    return Error "repos number (#{repos.length}) and ports number (#{ports?.length}) don't match" if ports? and repos.length isnt ports.length
    each repos
    .parallel true
    .run (repo, next) =>
      ports = []
      repopath = "#{@options.directory}/#{repo.name}"
      do_init = =>
        fs.exists "#{repopath}/init", (exists) =>
          return do_end() if exists #and not repo.url
          return Error 'Cannot create repo without remote repo url' unless repo.url? 
          http url: repo.url, (err, response, body) =>
            return callback err if err
            fs.mkdir repopath, (err) =>
              return callback err if err and err.code isnt 'EEXIST'
              fs.writeFile "#{repopath}/repo", body, (err) =>
                return callback err if err
                ini.parse "#{repopath}/repo", (err, inidata) =>
                  return callback err if err
                  data = utils.build_assets repo, inidata
                  fs.writeFile "#{repopath}/init", data, (err) =>
                    return callback err if err
                    fs.chmod "#{repopath}/init", 0o0755, (err) =>
                      return callback err if err
                      do_end()
      do_end = =>
        @setPort repo.name, repo.port, (err) =>
          return next err if err
          @docker.sync repopath, (err, stdout, stderr) -> next err
      do_init()
    .then callback

  start: (repos, callback) ->
    @list (repos.map (r) -> r.name), true, (err, registered_repos) =>
      return callback err if err
      for repo in repos
        registered_repos[repo.name].port = repo.port if repo.port?
      each registered_repos
      .parallel true
      .run (repo, next) =>
        unless repo.docker.names # Unregistered container
          @docker.run repo, @options.directory, (err) =>
            return next err
        else if /^Up/.test repo.docker.status # Running container
          return next() if "#{repo.port}" is /([\d]+)\->80/.exec(repo.docker.ports)?[1]
          return @docker.stop repo.name, (err) =>
            return next err if err
            @docker.rm repo.name, (err) =>
              return next err if err
              @docker.run repo, @options.directory, (err) =>
                return next err
        else # Stoped container
          @docker.start repo.name, (err) =>
            next err
      .then (err) =>
        callback err

  stop: (repos, callback) ->
    @list repos, true, (err, repos) =>
      return callback err if err
      each repos
      .run (repo, next) =>
         return next() unless /^Up/.test repo.docker?.status
         @docker.stop repo.name, next
      .then callback

  remove: (repos, callback) ->
    each repos
    .parallel true
    .run (repo, next) =>
      @docker.rm repo, (err) =>
        return next err if err
        return next() unless @options.purge
        rmr.remove "#{@options.directory}/#{repo}", next
    .then callback


