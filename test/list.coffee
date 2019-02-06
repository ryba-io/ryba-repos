
os = require 'os'
path = require 'path'
should = require 'should'
nikita = require '@nikitajs/core'
repos = require '../lib/repos'

describe 'list', ->
  
  # Note, using os.tmpdir() on osx generate the error: The path 
  # /var/folders/bz/9cdm1gtj7v1gdr7yq_whq3j40000gn/T/ryba-repos
  # is not shared from OS X and is not known to Docker.
  tmpdir = '/tmp'
  
  it 'list all the repos', () ->
    nikita
    .system.mkdir path.resolve tmpdir, 'centos7', 'myrepo-1.2.3'
    .system.mkdir path.resolve tmpdir, 'centos7', 'myrepo-1.2.4'
    .system.mkdir path.resolve tmpdir, 'centos7', 'otherrepo'
    .call (_, callback) ->
      repos()
      .list
        store: tmpdir
        system: 'centos7'
      , (err, repos) ->
        repos.should.eql
          centos7: [ 'myrepo-1.2.3', 'myrepo-1.2.4', 'otherrepo' ] unless err
        callback err
    .promise()
    
