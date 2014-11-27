
# Repository local synchronization with docker

## Installation

Docker must be installed on the system.

```bash
# Clone this repo
git clone https://github.com/wdavidw/ryba-repo.git
cd ryba-repo

# Build HDP image
repo_centos_sync/build.sh
# Synchronize CentOS
repo_centos_sync/run.sh
# Run CentOS HTTP server (port 10180)
repo_centos

# Build Epel image
repo_epel_sync/build.sh
# Synchronize Epel
repo_epel_sync/run.sh
# Run Epel HTTP server (port 10181)
repo_epel

# Build HDP image
repo_hdp_sync-2.1.7.0/build.sh
# Synchronize HDP
repo_hdp_sync-2.1.7.0/run.sh
# Run HDP HTTP server (port 10185)
repo_hdp-2.1.7.0

# Build Ambari image
repo_ambari_sync-1.6.1/build.sh
# Synchronize Ambari
repo_ambari_sync-1.6.1/run.sh
# Run Ambari HTTP server (port 10186)
repo_ambari_sync-1.6.1
```

## List of default port

centos: 10180
epel: 10181
hdp-2.1.2.0: 10182
hdp-2.1.4.0: 10183
hdp-2.1.5.0: 10184
hdp-2.1.7.0: 10185
ambari-1.6.1: 10186

