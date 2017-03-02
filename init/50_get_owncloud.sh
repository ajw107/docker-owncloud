#!/bin/bash

if [ ! -f "/config/www/owncloud/index.php" ]; then

#owncloud_vers=$(curl -L http://tools.linuxserver.io/lsio/owncloud.php | jq .package | sed -e 's/^"//'  -e 's/"$//')
echo "WARNING: Manually installing owncloud as not found where it should be"
curl -o /tmp/owncloud.tar.bz2 -L "https://download.owncloud.org/community/owncloud-${OWNCLOUD_VER}.tar.bz2"
mkdir -p /config/www/owncloud
tar -xjf /tmp/owncloud.tar.bz2 -C /config/www/owncloud  --strip-components=1
fi

chown -R abc:abc /config/www/owncloud

