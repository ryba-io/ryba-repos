
util = require 'util'
parameters = require 'parameters'
repos = require './repos'
PrettyError = require('pretty-error')
pe = new PrettyError()
error = (err) ->
  # console.log err.message if err
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
      name: 'system'
      type: 'array'
      shortcut: 's'
      required: true
      one_of: ['centos6', 'centos7']
      description: 'One of \'centos6\' or \'centos7\''
    ,
      name: 'repos'
      type: 'array'
      shortcut: 'r'
      required: true
      description: 'Repositories to initialize'
    ,
      name: 'urls'
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
      name: 'repos'
      type: 'array'
      shortcut: 'r'
      description: 'Repositories to start. All by default'
    ,
      name: 'ports'
      shortcut: 'p'
      type: 'array'
      description: 'Set port value on first start'
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
try
  args = params.parse()
catch e then return console.log e.message
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
    args.urls ?= []
    throw Error "Incoherent Arguments Length" if args.urls.length and args.repos.length isnt args.urls.length
    args.repos = for repo, i in args.repos
      repo: repo, url: args.urls[i]
    repos(args).sync args.repos, error
  when 'start'
    throw Error "Incoherent Arguments Length" if args.port.length and args.repo.length isnt args.port.length
    args.repos = for repo, i in args.repos
      repos: repo, port: args.port[i]
    repos(args).start args.repos, error
  when 'stop'
    repos(args).stop args.repo, error
  when 'remove'
    repos(args).remove args.repo, error
