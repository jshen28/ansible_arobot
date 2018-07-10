#!/bin/bash

set -ex

# Backup repo files
yum_repo_path=/etc/yum.repos.d
backup_repo_path=/tmp/repos_orgin
if [[ -d "$yum_repo_path" && "`ls -A $yum_repo_path`" != "" ]]; then
    if [[ -d "$backup_repo_path" ]]; then
        rm -rf $backup_repo_path
    fi
    mkdir -p $backup_repo_path
    mv $yum_repo_path/* $backup_repo_path
fi

# Untar cache rpms
base_path=$(cd `dirname $0`; pwd)
cache_path=/tmp/cache
if [[ -d "$cache_path" ]]; then
    rm -rf $cache_path
fi
contrib_path=$base_path/contrib
cp $contrib_path/arobot_cache.tar /tmp
cp $contrib_path/irorpms.tar /tmp
cd /tmp
tar -xvf arobot_cache.tar
tar -xvf irorpms.tar

# Generate local repo
cd $yum_repo_path
cat << EOF > local.repo
[base]
name=base
baseurl=file:///tmpcache/base
gpgcheck=0
enabled=1

[epel]
name=epel
baseurl=file:///tmp/cache/epel
gpgcheck=0
enabled=1

[extras]
name=extras
baseurl=file:///tmp/cache/extras
gpgcheck=0
enabled=1

[updates]
name=updates
baseurl=file:///tmp/cache/updates
gpgcheck=0
enabled=1

[newton]
name=newton
baseurl=file:///tmp/cache/newton
gpgcheck=0
enabled=1

EOF

# Install createrepo and ansible
cd ~
yum install -y ansible createrepo

# Createrepo for ironic related rpms
createrepo /tmp/irorpms
cat << EOF >> $yum_repo_path/local.repo
[irorpms]
name=irorpms
baseurl=file:///tmp/irorpms
gpgcheck=0
enabled=1

EOF

# Execute ansible scripts
cd $base_path
ansible-playbook site.yml
