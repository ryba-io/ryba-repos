
# Repository local synchronization with docker

This software is used to manage local YUM repositories (Web server), using
Docker. It contains tools to:
*   synchronize locally a remote yum repository
*   Publish a repository with a Webserver
*   Start/stop Web servers

## Installation

This chapter assumes that you have already installed docker and coffee-script

```bash
git clone https://github.com/ryba-io/ryba-repos
cd ryba-repos
docker build -t ryba_repos/syncer
```

## Commands

### Init

Synchronize a local repo with Docker container

```bash
bin/repos init repository-name -u http://remote.repository:PORT/path/repoFile.repo
```

### Start

Start a repo, all by default

```bash
bin/repos start repository-name
bin/repos start
```


## Arborescence

## Installation

## List of default port

#centos: 10180
#epel: 10181
#hdp-2.1.2.0: 10182
#hdp-2.1.4.0: 10183
#hdp-2.1.5.0: 10184
#hdp-2.1.7.0: 10185
#ambari-1.6.1: 10186

