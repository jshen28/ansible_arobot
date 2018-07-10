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
cp $contrib_path/arobot_deps.tar /tmp
cd /tmp
tar -xvf arobot_deps.tar

# Generate local repo
cd $yum_repo_path
cat << EOF > local.repo
[local]
name=local
baseurl=file:///tmp/arobot_deps
gpgcheck=0
enabled=1

EOF

# Install ansible
cd ~
yum install -y ansible

# Execute ansible scripts
cd $base_path
ansible-playbook site.yml
