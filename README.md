
# Repository local synchronization with docker

This software is used to manage local YUM repositories (Web server), using
Docker. It contains tools to:   

*   synchronize locally a remote yum repository
*   Publish a repository with a Webserver
*   Start/stop Web servers

## Installation

This chapter assumes that you have already installed Git, Docker and Node.js.

```bash
git clone https://github.com/ryba-io/ryba-repos
cd ryba-repos
docker-machine create ryba
eval "$(docker-machine env ryba)"
docker build -t ryba/repos .
```


/usr/bin/rsync -av --bwlimit=524 --exclude=repodata --exclude=i386 --exclude=debug --exclude=isos --delete rsync://rsync.gtlib.gatech.edu/centos/6.7 /Users/wdavidw/www/projects/ryba/ryba-repos/public/repo_centos/centos/temp

## Sync

`repos sync -r {name} -u {url}`

*   -r, --repo   
    Name of the repository.   
*   -u, --url   
    URL from where to fetch the repository definition file.   

Synchronize a local repo using a temporary Docker container. The repository are
downloaded into your local public folder located inside this project. The
folder is named after the "repo" argument. For example, here's how to
synchronize the Epel repository.

```bash
./bin/repos -d sync \
  -r ambari-2.2.0.0 \
  -u  	http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.0.0/ambari.repo
./bin/repos -d sync \
  -r hdp-2.3.4.0 \
  -u http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.4.0/hdp.repo
```

## Start

Start a repo, all by default

```bash
bin/repos start repository-name
bin/repos start
```

## Recipes

./bin/repos -d sync -r repo_mongodb-org-3.0 -u /Users/wdavidw/www/projects/ryba/ryba-repos/repos/mongodb-org-3.0.repo
