
util = require 'util'
parameters = require 'parameters'
repos = require './repos'

params = parameters
  name: 'repos'
  description: 'Install and sync RHEL/CentOS repositories'
  options: [
    name: 'output'
    shortcut: 'o'
    description: 'Directory storing the repository files.'
  ,
    name: 'debug'
    shortcut: 'd'
    type: 'boolean'
    description: 'Directory storing the repository files.'
  ]
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
      description: 'Repositories to initialize'
    ,
      name: 'url'
      type: 'array'
      shortcut: 'u'
      required: false
      description: 'URLs of the repositories'
    ,
      name: 'port'
      shortcut: 'p'
      type: 'array'
      description: 'Default port value'
    ]
  ,
    name: 'start'
    description: 'Start Repo server(s) with Docker'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      description: 'Repositories to start. All by default'
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
      description: 'Repositories to stop. All by default'
    ]
  ,
    name: 'remove'
    description: 'Delete a repo'
    options: [
      name: 'repo'
      shortcut: 'r'
      type: 'array'
      required: true
      description: 'Repositories to delete from docker'
    ,
      name: 'purge'
      shortcut: 'p'
      type: 'boolean'
      description: 'Remove the repository files'
    ]
  ]
args = params.parse()
switch args.command
  when 'help' then console.log params.help args.name
  when 'list'
    repos(args).list args.repo, (err, repos) ->
      return console.log err if err
      for repo in repos
        process.stdout.write repo.name
        process.stdout.write " [#{repo.port}]"
        process.stdout.write " #{repo.docker.status}" if repo.docker.status
        process.stdout.write " Not registered" unless repo.docker.status
        process.stdout.write '\n'
  when 'sync'
    {repo, url, port} = args
    url ?= []
    throw Error "Incoherent Arguments Length" if url.length and repo.length isnt url.length
    repo = for name, i in repo
      name: name, url: url[i]
    repos(args).sync repo, (err) -> console.log err if err
  when 'start'
    {repo, port} = args
    repo ?= []
    port ?= []
    throw Error "Incoherent Arguments Length" if port.length and repo.length isnt port.length
    repo = for name, i in repo
      name: name, port: port[i]
    repos(args).start repo, (err) -> console.log err if err
  when 'stop'
    repos(args).stop args.repo, (err) -> console.log err if err
  when 'remove'
    repos(args).remove args.repo, (err) -> console.log err if err
