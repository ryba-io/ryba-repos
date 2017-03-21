
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
# Centos6
./bin/repos -m ryba -d sync \
  -s centos6 \
  -r centos \
  -u repos/centos6/centos.repo
./bin/repos -m ryba -d sync \
  -s centos6 \
  -r epel \
  -u repos/centos6/epel.repo
./bin/repos -d sync \
  -s centos6 \
  -r ambari-2.4.1.0 \
  -u http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.4.1.0/ambari.repo
./bin/repos -d sync \
  -s centos6 \
  -r hdf-2.0.1.0 \
  -u http://public-repo-1.hortonworks.com/HDF/centos6/2.x/updates/2.0.1.0/hdf.repo
# Centos7
./bin/repos -m ryba -d sync \
  -s centos7 \
  -r centos \
  -u repos/centos7/centos.repo
./bin/repos -m ryba -d sync \
  -s centos7 \
  -r epel \
  -u repos/centos7/epel.repo
./bin/repos -d sync \
  -s centos7 \
  -r ambari-2.4.1.0 \
  -u http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.4.1.0/ambari.repo
./bin/repos -d sync \
  -s centos7 \
  -r hdp-2.5.3.0 \
  -u http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.5.3.0/hdp.repo
./bin/repos -d sync \
  -s centos7 \
  -r hdf-2.0.1.0 \
  -u http://public-repo-1.hortonworks.com/HDF/centos7/2.x/updates/2.0.1.0/hdf.repo
```
docker  run --rm -v /Users/wdavidw/www/projects/ryba/ryba-repos/public/centos7-hdp-2.5.0.0:/var/ryba -v /Users/wdavidw/www/projects/ryba/ryba-repos/public/../repos/centos7-hdp-2.5.0.0.repo:/etc/yum.repos.d/centos7-hdp-2.5.0.0.repo ryba/repos_sync

docker  run --rm -v /Users/wdavidw/www/projects/ryba/ryba-repos/public/centos7/hdp-2.5.0.0:/var/ryba -v /Users/wdavidw/www/projects/ryba/ryba-repos/public/../repos/centos7/hdp-2.5.0.0.repo:/etc/yum.repos.d/centos7/hdp-2.5.0.0.repo ryba/repos_sync

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
