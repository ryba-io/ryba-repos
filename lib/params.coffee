
module.exports =
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
    ,
      name: 'system'
      type: 'string'
      shortcut: 's'
      required: true
      one_of: ['centos6', 'centos7']
      description: 'One of \'centos6\' or \'centos7\''
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
