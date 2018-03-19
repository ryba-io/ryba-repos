
os = require 'os'
path = require 'path'
should = require 'should'
nikita = require 'nikita'
repos = require '../lib/repos'

describe 'list', ->
  
  it 'list all the repos', () ->
    nikita
    .file
      target: path.resolve os.tmpdir(), 'ryba-repos', 'centos7', 'myrepo-1.2.3', 'hello'
      content: 'world'
    .call (_, callback) ->
      repos()
      .start
        container: 'ryba_repos'
        store: path.resolve os.tmpdir(), 'ryba-repos'
        system: 'centos7'
        port: 10080
      , callback
    .call (_, callback) ->
      repos()
      .stop
        container: 'ryba_repos'
        store: path.resolve os.tmpdir(), 'ryba-repos'
        system: 'centos7'
        port: 10080
      , (err, status) ->
        status.should.be.true() unless err
        callback err
    .call (_, callback) ->
      repos()
      .stop
        container: 'ryba_repos'
        store: path.resolve os.tmpdir(), 'ryba-repos'
        system: 'centos7'
        port: 10080
      , (err, status) ->
        status.should.be.false() unless err
        callback err
    .promise()
    
