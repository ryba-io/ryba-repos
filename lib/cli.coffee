
util = require 'util'
parameters = require 'parameters'
repos = require './repos'
PrettyError = require('pretty-error')
pe = new PrettyError()
error = (err) ->
  # console.log err.message if err
  console.log pe.render err if err
  return !!err

params = parameters require './params'
args = params.parse()
if commands = params.helping args
  return process.stdout.write params.help commands
switch args.command
  when 'help' then console.log params.help args.name
  when 'list'
    repos(args).list args.repo, (err, repos) ->
      return if error err
      for repo in repos
        process.stdout.write repo
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
  else
    throw Error "Unsupported Command: #{args.command}"
