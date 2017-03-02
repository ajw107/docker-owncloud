#!/bin/bash

ocpath='/var/www/owncloud'
htuser='abc'
htgroup='abc'
rootuser='root'
#update through apt if possible
sudo apt-get update
sudo apt-get -y dist-upgrade

if [ ! -f "/config/www/owncloud/index.php" ]; then

#owncloud_vers=$(curl -L http://tools.linuxserver.io/lsio/owncloud.php | jq .package | sed -e 's/^"//'  -e 's/"$//')
echo "WARNING: Manually installing owncloud as not found where it should be"
curl -o /tmp/owncloud.tar.bz2 -L "https://download.owncloud.org/community/owncloud-${OWNCLOUD_VER}.tar.bz2"
mkdir -p /config/www/owncloud
tar -xjf /tmp/owncloud.tar.bz2 -C /config/www/owncloud  --strip-components=1
else
    ##see if there is an update available, exits with non-zero if there is NO update
    cd "${ocpath}"
    sudo -u ${htuser} php updater/application.php upgrade:detect --only-check --exit-if-none
    if [ "$?" -eq "0" ]
    then
        #tell all users what's happening
        sudo -u ${htuser} php occ maintenance:mode --on
        
        #TODO: downbload latest tarball (can;t seems to find a download link without a version number in)
        
        #TODO: mv owncloud to owncloud-bak
        
        #TODO: tar xvf owncloud-*.tar.gz
        
        #TODO: cp owncloud-bak/config/config.php owncloud/config/config/php
        
        #TODO: cp -arp owncloud-bak/data owncloud/
        
        #TODO: check if owncloud-bak/apps dir has entires that owncloud/apps doesn't and cp -arp them over
        
        #set permissions for updating OwnCloud
        chown -R ${htuser}:${htgroup} ${ocpath}
    
        #see if and update is available, as already installed
        sudo -u ${htuser} php occ upgrade
    
        #Change permissions back for security
        printf "Creating possible missing Directories\n"
        mkdir -p $ocpath/data
        mkdir -p $ocpath/assets
        mkdir -p $ocpath/updater

        printf "chmod Files and Directories\n"
        find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
        find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

        printf "chown Directories\n"
        chown -R ${rootuser}:${htgroup} ${ocpath}/
        chown -R ${htuser}:${htgroup} ${ocpath}/apps/
        chown -R ${htuser}:${htgroup} ${ocpath}/assets/
        chown -R ${htuser}:${htgroup} ${ocpath}/config/
        chown -R ${htuser}:${htgroup} ${ocpath}/data/
        chown -R ${htuser}:${htgroup} ${ocpath}/themes/
        chown -R ${htuser}:${htgroup} ${ocpath}/updater/

        chmod +x ${ocpath}/occ

        printf "chmod/chown .htaccess\n"
        if [ -f ${ocpath}/.htaccess ]
        then
            chmod 0644 ${ocpath}/.htaccess
            chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
        fi
        if [ -f ${ocpath}/data/.htaccess ]
        then
            chmod 0644 ${ocpath}/data/.htaccess
            chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess
        fi
        
        #TODO: (ONLY IF UPGRADE SUCCEDED) rm -rf owncloud-bak owncloud-*.tar.gz
        #we're done, I hope....
        sudo -u ${htuser} php occ maintenance:mode --off
        cd -
    fi
fi

chown -R abc:abc /config/www/owncloud

