
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
./bin/repos sync \
  -r repo_ambari-2.0.0 \
  -u http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.0.0/ambari.repo
```

## Start

Start a repo, all by default

```bash
bin/repos start repository-name
bin/repos start
```


