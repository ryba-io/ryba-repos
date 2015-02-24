
util = require 'util'
parameters = require 'parameters'
repos = require './repos'

params = parameters
  name: 'repos'
  description: 'Install and sync RHEL/CentOS repositories'
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
      description: 'repo(s) to initialize'
    ,
      name: 'url'
      type: 'array'
      shortcut: 'u'
      required: false
      description: 'the url(s) of the repo(s)'
    ]
  ,
    name: 'start'
    description: 'Start Repo server(s) with Docker'
    options: [
      name: 'repo'
      type: 'array'
      shortcut: 'r'
      description: 'the repo(s) to start. All by default'
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
      description: 'the repo(s) to stop. All by default'
    ]
  ,
    name: 'remove'
    description: 'Delete a repo'
    options: [
      name: 'repo'
      shortcut: 'r'
      type: 'array'
      required: true
      description: 'the repo(s) to delete'
    ]
  ]
arg = params.parse()

switch arg.command
  when 'help' then console.log params.help arg.name
  when 'list'
    repos.list arg.repo, (err, repos) ->
      for repo in repos
        process.stdout.write repo.name
        process.stdout.write " [#{repo.port}]"
        process.stdout.write " #{repo.docker.status}" if repo.docker.status
        process.stdout.write " Not registered" unless repo.docker.status
        process.stdout.write '\n'
  when 'sync'
    {repo, url} = arg
    url ?= []
    throw Error "Incoherent Arguments Length" if url.length and repo.length isnt url.length
    repo = for name, i in repo
      name: name, url: url[i]
    repos.sync repo, (err) -> console.log err if err
  when 'start'
    {repo, port} = arg
    repo ?= []
    port ?= []
    throw Error "Incoherent Arguments Length" if port.length and repo.length isnt port.length
    repo = for name, i in repo
      name: name, port: port[i]
    repos.start repo, (err) -> console.log err if err
  when 'stop'
    repos.stop arg.repo, (err) -> console.log err if err
  when 'remove'
    repos.remove arg.repo, (err) -> console.log err if err
