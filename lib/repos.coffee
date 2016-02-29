#!/usr/bin/env coffee

mecano = require 'mecano'
misc =  require 'mecano/lib/misc'
wrap = require('mecano/lib/misc/docker').wrap
fs = require 'fs'
path = require 'path'
rmr = require 'remove'
multimatch = require 'multimatch'
each = require 'each'
url = require 'url'
ini = require 'node-ini'
http = require 'request'
utils = require './utils'

module.exports = (options) ->
  new Repos options

class Repos

  constructor: (@options={}) ->
    @options.container ?= 'ryba_repos'
    @options.port ?= '10800'
    @options.directory ?= './public'
    @options.directory = path.resolve process.cwd(), @options.directory
    @options.log ?= true
  
  
  list: (callback) ->
    fs.readdir @options.directory, (err, dirs) =>
      return callback err if err
      return callback null, 'no repos' unless dirs.length
      list = []
      (list.push(name) unless /^.*\.repo$/.test name) for name in dirs      
      callback null , list
    
  # create the directories'layout (public, repo)
  # syncs the repos:
  # - create a directory inside public under the repo(s) name(s)
  # - write a .repo file containing the mirror informations with changed url (inside public)
  # - copy to repos folder the original .repo file
  sync: (repos, callback) ->
    return Error "repos number (#{repos.length}) and urls number (#{urls?.length}) don't match" if urls? and repos.length isnt urls.length
    return Error "repos number (#{repos.length}) and ports number (#{ports?.length}) don't match" if ports? and repos.length isnt ports.length
    each repos
    .parallel true
    .call (repo, next) =>
      ports = []
      repopath = "#{@options.directory}/#{repo.name}"
      repos_dir = "#{@options.directory}/../repos"
      repofile = "#{repo.name}.repo"
      mecano
      # write original file to repos/ directory (not executed if file already exists)
      .mkdir
        destination: repopath
      .mkdir
        destination: repos_dir
      # download ( or copy ) orignial repo file to repos folder
      .download 
        source: "#{repo.url}"
        destination: "#{repos_dir}/#{repofile}"
        if: /^http.*/.test repo.url
      .copy 
        source: "#{repo.url}"
        destination: "#{repos_dir}/#{repofile}"
        unless: /^http.*/.test repo.url
          # destination: "#{repopath}/#{repo.name}.repo"
      .call # Write init docker script
        handler: (_, callback) ->
          try 
            ini.parse "#{repos_dir}/#{repofile}", (err, data) =>
              return callback err if err
              init_data = utils.build_assets repo, data
              custom_repo = utils.buid_custom_repo_file repo, data
              @write
                destination: "#{repopath}/init"
                content: init_data
                mode: 0o0755
              @ini
                destination: "#{repopath}/../#{repofile}"
                content: custom_repo
                stringify: misc.ini.stringify_multi_brackets
                indent: ''
                separator: '='
                comment: '#'
                eof: true
              @then callback
      .docker_run
        image: 'ryba/repos_sync'
        machine: @options.machine
        volume: "#{repopath}:/var/ryba"
        env: @options.env
      .then (err, status) ->
        return callback err if err
    .then callback

  # start the ryba_repos container serving public directory
  start: (callback) ->
    mecano
      .execute
        cmd : wrap machine: @options.machine, "ps -a | grep '#{@options.container}'"
        code_skipped: 1
      .docker_service
        unless: -> @status -1
        image: 'httpd'
        container: @options.container
        machine: @options.machine
        volume: "#{@options.directory}:/usr/local/apache2/htdocs/"
        port: "#{@options.port}:80"
      .docker_start
        container: @options.container
        machine: @options.machine
      .then callback
  
  # stop the ryba_repos container serving public directory
  stop: (callback) ->
    container = @options.container ?= 'ryba_repos'
    mecano
      .docker_stop
        container: @options.container
        machine: @options.machine
        code_skipped: 1
      .then callback
      
  # removes the ryba_repos container serving public directory
  remove: (repos, callback) ->
      repos ?= ['*']
      mecano
      .docker_rm
        container: @options.container
        machine: @options.machine
        force: true
        code_skipped: 1
      each repos
      .parallel true
      .call (repo, next) =>
        mecano
        .remove
          if: @options.purge
          destination: "#{@options.directory}/#{repo}"
        .then next
      .then callback
    
