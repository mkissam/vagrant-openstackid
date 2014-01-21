#!/bin/bash -xe

GIT_URL="https://github.com/openstack-infra/config.git"
GIT_BRANCH="master"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git mysql-server

hostname openstackid-dev
cat >/etc/resolv.conf <<EOF
nameserver 8.8.8.8
search openstack.org
EOF

mkdir -p /opt/config
git clone -b $GIT_BRANCH $GIT_URL /opt/config/production

/opt/config/production/install_puppet.sh
/opt/config/production/install_modules.sh

cat >/etc/puppet/puppet.conf <<EOF
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
templatedir=$confdir/templates
server=ci-puppetmaster.openstack.org
certname=openstackid-dev.openstack.org
pluginsync=true

[master]
# These are needed when the puppetmaster is run by passenger
# and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY
manifestdir=/opt/config/$environment/manifests
modulepath=/opt/config/$environment/modules:/etc/puppet/modules
manifest=$manifestdir/site.pp
reports=store

[agent]
report=true
splay=true
runinterval=600
EOF

apt-get install -y hiera hiera-puppet
mkdir -p /etc/puppet/hieradata/production

cat >/etc/puppet/hiera.yaml <<EOF
---
:hierarchy:
  - %{operatingsystem}
  - common
:backends:
  - yaml
:yaml:
  :datadir: '/etc/puppet/hieradata/%{environment}'
EOF

cat >/etc/puppet/hieradata/production/common.yaml <<EOF
sysadmins:
  - 'sysadmin@gexample.com'
openstackid_dev_site_admin_password: '12345678'
openstackid_dev_mysql_host: 'localhost'
openstackid_dev_mysql_password: '12345678'
EOF

chown -R puppet:puppet /etc/puppet/hieradata
chmod 0600 /etc/puppet/hieradata/production/common.yaml

# Create mysql databases
mysql <<EOF
CREATE DATABASE openstackid_openid_dev;
GRANT ALL
  ON openstackid_openid_dev.*
  TO 'openstackid'@'localhost' IDENTIFIED BY '12345678';
CREATE DATABASE openstackid_silverstripe_dev;
GRANT ALL
  ON openstackid_silverstripe_dev.*
  TO 'openstackid'@'localhost' IDENTIFIED BY '12345678';
EOF

puppet apply --modulepath='/opt/config/production/modules:/etc/puppet/modules' /opt/config/production/manifests/site.pp