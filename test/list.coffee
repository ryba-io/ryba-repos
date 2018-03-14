
os = require 'os'
path = require 'path'
should = require 'should'
nikita = require 'nikita'
repos = require '../lib/repos'

describe 'list', ->
  
  it 'list all the repos', () ->
    nikita
    .system.mkdir path.resolve os.tmpdir(), 'centos7', 'myrepo-1.2.3'
    .system.mkdir path.resolve os.tmpdir(), 'centos7', 'myrepo-1.2.4'
    .system.mkdir path.resolve os.tmpdir(), 'centos7', 'otherrepo'
    .call (_, callback) ->
      repos
        store: os.tmpdir()
        system: 'centos7'
      .list null, (err, repos) ->
        repos.should.eql [ 'myrepo-1.2.3', 'myrepo-1.2.4', 'otherrepo' ] unless err
        callback err
    .promise()
    
