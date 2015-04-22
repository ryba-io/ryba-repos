
exec = require './exec'

module.exports = (debug) ->

  sync: (repopath, callback) ->
    exec """
    if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
    docker run -v #{repopath}:/var/ryba --rm=true ryba_repos/syncer
    """, debug, callback

  start: (repo, callback) ->
    exec """
    if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
    docker start #{repo}
    """, debug, callback

  stop: (repo, callback) ->
    exec """
    if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
    docker stop #{repo}
    """, debug, callback

  rm: (repo, callback) ->
    exec """
    if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
    docker rm #{repo}
    """, debug, callback

  run: (repo, pubdir, callback) ->
    throw Error 'Invalid arguments' unless repo.name? and repo.port?
    exec """
    if command -v boot2docker; then boot2docker up && $(boot2docker shellinit); fi
    docker run -d \
      --name=#{repo.name} \
      -v #{pubdir}/#{repo.name}:/usr/local/apache2/htdocs/ \
      -p #{repo.port}:80 \
      httpd
    """, debug, callback
