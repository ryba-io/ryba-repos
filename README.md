
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
docker build -t ryba/repos .
```

## Sync

`repos sync -s {system} -r {name} -u {url}`

*   -r, --repo   
    Name of the repository.   
*   -s, --system   
    Underlying system, one of centos6 or centos7.   
*   -u, --url   
    URL from where to fetch the repository definition file.   
*   -m, --machine   
    Name of the docker machine to use, if docker machine is installed.

Synchronize a local repo using a temporary Docker container. The repository are
downloaded into your local public folder located inside this project. The
folder is named after the "repo" argument. For example, here's how to
synchronize the Epel repository.

```bash
os=centos7 # one of "centos6", "centos7"
./bin/repos -m ryba -d sync \
  -s $os \
  -r centos \
  -u repos/$os/centos.repo
./bin/repos -m ryba -d sync \
  -s $os \
  -r epel \
  -u repos/$os/epel.repo
./bin/repos -m ryba -d sync \
  -s $os \
  -r mysql \
  -u repos/$os/mysql.repo
./bin/repos -d sync \
  -s $os \
  -r ambari-2.5.1.0 \
  -u http://public-repo-1.hortonworks.com/ambari/$os/2.x/updates/2.5.1.0/ambari.repo
./bin/repos -d sync \
  -s $os \
  -r 2.6.1.0 \
  -u http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.6.1.0/hdp.repo
./bin/repos -d sync \
  -s $os \
  -r hdf-2.1.2.0 \
  -u http://public-repo-1.hortonworks.com/HDF/$os/2.x/updates/2.1.2.0/hdf.repo
./bin/repos -d sync \
  -s $os \
  -r opennebula \
  -u repos/$os/opennebula.repo
./bin/repos -d sync \
  -s $os \
  -r kubernetes \
  -u repos/$os/kubernetes.repo
```

## Start

*   -m, --machine   
    Name of the docker machine to use, if docker machine is installed.
*   -c, --container   
    Name of the docker container. 'ryba_repos' by default.
*   -p, --port   
    Port used to run the container the first time. 10800 by default.

```bash
bin/repos start
bin/repos -m 'ryba' start
```

## Recipes

./bin/repos -d sync -r repo_mongodb-org-3.0 -u /Users/wdavidw/www/projects/ryba/ryba-repos/repos/mongodb-org-3.0.repo

## Developer

For contributor, run `npm version major|minor|patch -m "Bump to version %s` to publish a new version. Changelog is generated with the command `./node_modules/.bin/changelog-maker --group`.
