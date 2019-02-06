
os = require 'os'
path = require 'path'
should = require 'should'
nikita = require 'nikita'
repos = require '../lib/repos'

describe 'list', ->
  
  # Note, using os.tmpdir() on osx generate the error: The path 
  # /var/folders/bz/9cdm1gtj7v1gdr7yq_whq3j40000gn/T/ryba-repos
  # is not shared from OS X and is not known to Docker.
  tmpdir = '/tmp'
  
  it 'list all the repos', () ->
    nikita
    .file
      target: path.resolve tmpdir, 'ryba-repos', 'centos7', 'myrepo-1.2.3', 'hello'
      content: 'world'
    .call (_, callback) ->
      repos()
      .start
        container: 'ryba_repos'
        store: path.resolve tmpdir, 'ryba-repos'
        system: 'centos7'
        port: 10080
      , callback
    .call (_, callback) ->
      repos()
      .stop
        container: 'ryba_repos'
        store: path.resolve tmpdir, 'ryba-repos'
        system: 'centos7'
        port: 10080
      , (err, {status}) ->
        status.should.be.true() unless err
        callback err
    .call (_, callback) ->
      repos()
      .stop
        container: 'ryba_repos'
        store: path.resolve tmpdir, 'ryba-repos'
        system: 'centos7'
        port: 10080
      , (err, {status}) ->
        status.should.be.false() unless err
        callback err
    .promise()
    
