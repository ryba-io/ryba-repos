
util = require 'util'
parameters = require 'parameters'
repos = require './repos'
PrettyError = require('pretty-error')
pe = new PrettyError()
error = (err) ->
  console.log pe.render err if err
  return !!err

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
  ,
    name: 'machine'
    shortcut: 'm'
    type: 'string'
    description: 'name of the docker machine to use (optional)' 
  ,
    name: 'container'
    shortcut: 'c'
    type: 'string'
    description: 'override the container name. `ryba_repos` by default' 
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
    , 
      name: 'env'
      shortcut: 'e'
      type: 'array'
      description: 'Set environment variables for sync container'
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
      description: 'set port value on first start'
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
      type: 'string'
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
      return if error err
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
    repos(args).sync repo, error
  when 'start'
    {repo, port} = args
    repo ?= []
    port ?= []
    throw Error "Incoherent Arguments Length" if port.length and repo.length isnt port.length
    repo = for name, i in repo
      name: name, port: port[i]
    repos(args).start repo, error
  when 'stop'
    repos(args).stop args.repo, error
  when 'remove'
    repos(args).remove args.repo, error
