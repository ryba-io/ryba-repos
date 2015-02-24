
# Repository local synchronization with docker

This software is used to manage local YUM repositories (Web server), using
Docker. It contains tools to:
*   synchronize locally a remote yum repository
*   Publish a repository with a Webserver
*   Start/stop Web servers

## Installation

This chapter assumes that you have already installed Docker and Node.js.

```bash
git clone https://github.com/ryba-io/ryba-repos
cd ryba-repos
docker build -t ryba_repos/syncer .
```

## Init

`repos init -r {name} -u {url}`

*   -r, --repo   
    Name of the repository.   
*   -u, --url   
    URL from where to fetch the repository definition file.    
*   -p, --port   
    Port use to serve the repository locally.   

Synchronize a local repo using a temporary Docker container. The repository are
downloaded into your local public folder located inside this project. The
folder is named after the "repo" argument. For example, here's how to
synchronize the Epel repository.

```bash
./bin/repos init -r epel -u https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=x86_64
```

## Start

Start a repo, all by default

```bash
bin/repos start repository-name
bin/repos start
```

## List of default port

*   centos: 10180   
*   epel: 10181   
*   hdp-2.1.2.0: 10182   
*   hdp-2.1.4.0: 10183   
*   hdp-2.1.5.0: 10184   
*   hdp-2.1.7.0: 10185   
*   ambari-1.6.1: 10186   

