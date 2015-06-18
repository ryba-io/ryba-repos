
{exec} = require 'child_process'
watercolor = require 'watercolor'

module.exports = (cmd, debug, callback) ->
  child = exec cmd, callback
  if debug
    w = watercolor(color: 'green')
    w.pipe process.stdout
    w.write '\n'
    w.write cmd
    w.write '\n\n'
    child.stdout.pipe(watercolor color: 'cyan').pipe process.stdout
    child.stderr.pipe(watercolor color: 'magenta').pipe process.stderr
