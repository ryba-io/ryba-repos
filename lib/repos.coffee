#!/usr/bin/env coffee

nikita = require 'nikita'
misc =  require 'nikita/lib/misc'
wrap = require('nikita/lib/misc/docker').wrap
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
    @options.store ?= './public'
    @options.store = path.resolve process.cwd(), @options.store
    @options.log ?= true
  
  list: (repos, callback) ->
    dir = path.resolve @options.store, @options.system
    fs.readdir dir, (err, dirs) =>
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
    return callback Error "repos number (#{repos.length}) and urls number (#{urls?.length}) don't match" if urls? and repos.length isnt urls.length
    return callback Error "repos number (#{repos.length}) and ports number (#{ports?.length}) don't match" if ports? and repos.length isnt ports.length
    each repos
    .parallel true
    .call (repo, next) =>
      ports = []
      repopath = "#{@options.store}/#{@options.system}/#{repo.repo}"
      repofile_original = "#{@options.store}/../repos/#{@options.system}/#{repo.repo}.repo"
      repofile_new = "#{@options.store}/#{@options.system}/#{repo.repo}.repo"
      nikita
        debug: @options.debug
      # write original file to repos/ directory (not executed if file already exists)
      .docker.build
        machine: @options.machine
        image: "ryba/repos_sync_#{@options.system}"
        file: "#{__dirname}/../docker/Dockerfile.#{@options.system}"
      .mkdir
        target: repopath
      # download ( or copy ) orignial repo file to repos folder
      .download 
        source: "#{repo.url}"
        target: "#{repofile_original}"
        if: /^http.*/.test repo.url
      .copy 
        source: "#{repo.url}"
        target: "#{repofile_original}"
        unless: /^http.*/.test repo.url
      .call (_, callback) -> # Write init docker script
        ini.parse "#{repofile_original}", (err, data) =>
          return callback err if err
          init_data = utils.build_assets repo, data
          custom_repo = utils.buid_custom_repo_file repo, data
          @file
            target: "#{repopath}/init"
            content: init_data
            mode: 0o0755
          @file.ini
            target: "#{repofile_new}"
            content: custom_repo
            stringify: misc.ini.stringify_multi_brackets
            indent: ''
            separator: '='
            comment: '#'
            eof: true
          @next callback
      .docker.run
        # debug: true
        image: "ryba/repos_sync_#{@options.system}"
        machine: @options.machine
        volume: [
          "#{repopath}:/var/ryba"
          "#{repofile_original}:/etc/yum.repos.d/#{path.basename repo.repo}.repo"
        ]
        env: @options.env
        rm: true
      .next (err, status) ->
        return callback err if err
    .next callback
  # start the ryba_repos container serving public directory
  start: (callback) ->
    nikita
    .execute
      cmd : wrap machine: @options.machine, "ps -a | grep '#{@options.container}'"
      code_skipped: 1
    .docker.service
      unless: -> @status -1
      image: 'httpd'
      container: @options.container
      machine: @options.machine
      volume: "#{@options.store}:/usr/local/apache2/htdocs/"
      port: "#{@options.port}:80"
    .docker.start
      container: @options.container
      machine: @options.machine
    .next callback
  
  # stop the ryba_repos container serving public directory
  stop: (callback) ->
    container = @options.container ?= 'ryba_repos'
    nikita
    .docker.stop
      container: @options.container
      machine: @options.machine
      code_skipped: 1
    .next callback
      
  # removes the ryba_repos container serving public directory
  remove: (repos, callback) ->
    repos ?= ['*']
    nikita
    .docker.rm
      container: @options.container
      machine: @options.machine
      force: true
      code_skipped: 1
    each repos
    .parallel true
    .call (repo, next) =>
      nikita
      .remove
        if: @options.purge
        target: "#{@options.store}/#{repo}"
      .next next
    .next callback
    
