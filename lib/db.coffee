
fs = require 'fs'

module.exports = (directory) ->

  cache = null

  set: (data, callback) ->
    data = JSON.stringify(data, null, 2)
    fs.writeFile "#{directory}/config.json", data, callback

  get: (callback) ->
    return cache if cache
    fs.readFile "#{directory}/config.json", 'utf8', (err, data) =>
      if err and err.code is 'ENOENT'
        data = port_inc: 10180, repos: {}
        return fs.writeFile "#{directory}/config.json", data, (err) ->
          callback err, data
      return callback err if err
      try data = JSON.parse data
      catch err then return callback err
      cache = data
      callback null, data