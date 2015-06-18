
exec = require './exec'
utils = require './utils'

module.exports = (debug) ->

  sync: (repopath, callback) ->
    exec """
    if command -v docker-machine >/dev/null; then docker-machine start >/dev/null && eval "$(docker-machine env dev)"; fi
    docker run -v #{repopath}:/var/ryba --rm=true ryba/repos
    """, debug, callback

  start: (repo, callback) ->
    exec """
    if command -v docker-machine >/dev/null; then docker-machine start >/dev/null && eval "$(docker-machine env dev)"; fi
    docker start #{repo}
    """, debug, callback

  stop: (repo, callback) ->
    exec """
    if command -v docker-machine >/dev/null; then docker-machine start >/dev/null && eval "$(docker-machine env dev)"; fi
    docker stop #{repo}
    """, debug, callback

  rm: (repo, callback) ->
    exec """
    iif command -v docker-machine >/dev/null; then docker-machine start >/dev/null && eval "$(docker-machine env dev)"; fi
    docker rm #{repo}
    """, debug, callback

  run: (repo, pubdir, callback) ->
    throw Error 'Invalid arguments' unless repo.name? and repo.port?
    exec """
    if command -v docker-machine >/dev/null; then docker-machine start >/dev/null && eval "$(docker-machine env dev)"; fi
    docker run -d \
      --name=#{repo.name} \
      -v #{pubdir}/#{repo.name}:/usr/local/apache2/htdocs/ \
      -p #{repo.port}:80 \
      httpd
    """, debug, callback

  # obj: boolean, return an object instead of array, default to false
  ps: (obj, callback) ->
    if arguments.length is 1
      callback = obj
      obj = false
    exec """
    if command -v docker-machine >/dev/null; then docker-machine start >/dev/null && eval "$(docker-machine env dev)"; fi
    docker ps -a
    """, debug, (err, stdout, stderr) ->
      return callback err if err
      column_names = []
      column_length = []
      infos = {}
      for line, i in utils.lines stdout
        continue if /^\s*$/.test line
        if i is 0
          re = /(\w+\s+|\w+$)/mg
          while match = re.exec line
            column_names.push match[1].trim().toLowerCase()
            column_length.push match[1].length
          continue
        from = 0
        info = {}
        for column, i in column_names
          info[column] = if i isnt column_names.length - 1
          then line.substr(from, column_length[i]).trim()
          else line.substr(from).trim()
          from += column_length[i]
        infos[info.names] = info
      unless obj then infos = for _, info of infos then info
      callback null, infos





