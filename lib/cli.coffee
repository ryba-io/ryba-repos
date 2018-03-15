
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
    repos().start args, (err, status) ->
      if err
        process.stdout.write err.message
      else if status
        process.stdout.write "Server started and listening on port #{args.port}"
      else
        process.stdout.write 'Server already started'
      process.stdout.write '\n'
  when 'stop'
    repos().stop args, (err, status) ->
      if err
        process.stdout.write err.message
      else if status
        process.stdout.write 'Server stopped'
      else
        process.stdout.write 'Server already stopped'
      process.stdout.write '\n'
  when 'remove'
    repos(args).remove args.repo, error
  else
    throw Error "Unsupported Command: #{args.command}"
