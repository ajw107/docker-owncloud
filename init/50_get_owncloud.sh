#!/bin/bash

if [ ! -f "/config/www/owncloud/index.php" ]; then

owncloud_vers=$(curl -L http://tools.linuxserver.io/lsio/owncloud.php | jq .package | sed -e 's/^"//'  -e 's/"$//')
curl -o /tmp/owncloud.tar.bz2 -L "$owncloud_vers"
mkdir -p /config/www/owncloud
tar -xjf /tmp/owncloud.tar.bz2 -C /config/www/owncloud  --strip-components=1
else
    #see if and update is available, as already installed
    cd /config/www/owncloud
    sudo -u abc php occ upgrade
    cd -
fi

chown -R abc:abc /config/www/owncloud

