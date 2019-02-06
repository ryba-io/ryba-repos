
module.exports =
  name: 'repos'
  description: 'Install and sync RHEL/CentOS repositories'
  options: [
    name: 'container'
    shortcut: 'c'
    type: 'string'
    default: 'ryba_repos'
    description: 'override the container name. `ryba_repos` by default'
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
    name: 'output'
    shortcut: 'o'
    description: 'Directory storing the repository files.'
  ,
    name: 'store'
    shortcut: 's'
    type: 'string'
    default: './public'
    description: 'Directory storing the repositories'
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
      required: false
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
      name: 'port'
      shortcut: 'p'
      type: 'integer'
      default: 10080
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
