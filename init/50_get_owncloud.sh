#!/usr/bin/with-contenv bash
run_cmd() {
    set +e

    cmd=$@
    if [ "${DEBUG}" == "TRUE" ]
    then
        echo "Executing [$cmd]"
    fi
    eval $cmd
    ret_code=$?

    if [ "$ret_code" == "0" ]
    then
        echo "$@ executed successfully"
    else
        echo "$@ failed with exit code [$ret_code]"
    fi
}

rootuser='root'
#update through apt if possible
run_cmd "sudo apt-get update"
run_cmd "sudo apt-get -qy dist-upgrade"

if [ ! -f "${OC_DIR}/index.php" ] #"${CONFIG_DIR}/www/owncloud/index.php" ]
then
    #owncloud_vers=$(curl -L http://tools.linuxserver.io/lsio/owncloud.php | jq .package | sed -e 's/^"//'  -e 's/"$//')
    echo "WARNING: Manually installing owncloud as not found where it should be [${OC_DIR}]"
    run_cmd "curl -o /tmp/owncloud.tar.bz2 -L \"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VER}.tar.bz2\""
    run_cmd "mkdir -pv \"${OC_DIR}\"" #${CONFIG_DIR}/www/owncloud
    run_cmd "tar -xjf /tmp/owncloud.tar.bz2 -C \"${OC_DIR}\" --strip-components=1" #${CONFIG_DIR}/www/owncloud  --strip-components=1
else
    ##see if there is an update available, exits with non-zero if there is NO update
    echo "Checking if OwnCloud needs a manual update (ie not through apt-get"
    run_cmd "cd \"${OC_DIR}\""
    run_cmd "sudo -u ${USER} php updater/application.php upgrade:detect --only-check --exit-if-none"
    if [ "$?" -eq "0" ]
    then
        echo "WARNING: A manual update of owncloud is required as apt-get didn't update it"
        #tell all users what's happening
        run_cmd "chown -R ${rootuser}:${GROUP} \"${OC_DIR}/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/apps/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/assets/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/config/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/data/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/themes/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/updater/\""

        run_cmd "chmod -v +x \"${OC_DIR}/occ\""
        run_cmd "sudo -u ${USER} php occ maintenance:mode --on"
        
        #TODO: downbload latest tarball (can;t seems to find a download link without a version number in)
        
        #TODO: mv owncloud to owncloud-bak
        
        #TODO: tar xvf owncloud-*.tar.gz
        
        #TODO: cp owncloud-bak/config/config.php owncloud/config/config.php
        
        #TODO: cp -arp owncloud-bak/data owncloud/
        
        #TODO: check if owncloud-bak/apps dir has entires that owncloud/apps doesn't and cp -arp them over
        
        #set permissions for updating OwnCloud
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}\""
    
        #see if an update is available, as already installed
        run_cmd "sudo -u ${USER} php occ upgrade"
    
        #Change permissions back for security
        printf "Creating possible missing Directories\n"
        run_cmd "mkdir -pv \"${OC_DIR}/data\""
        run_cmd "mkdir -pv \"${OC_DIR}/assets\""
        run_cmd "mkdir -pv \"${OC_DIR}/updater\""

        printf "chmod Files and Directories\n"
        run_cmd "find \"${OC_DIR}/\" -type f -print0 | xargs -0 chmod 0644"
        run_cmd "find \"${OC_DIR}/\" -type d -print0 | xargs -0 chmod 0755"

        printf "chown Directories\n"
        run_cmd "chown -R ${rootuser}:${GROUP} \"${OC_DIR}/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/apps/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/assets/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/config/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/data/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/themes/\""
        run_cmd "chown -R ${USER}:${GROUP} \"${OC_DIR}/updater/\""

        run_cmd "chmod -v +x \"${OC_DIR}/occ\""

        printf "chmod/chown .htaccess\n"
        if [ -f "${OC_DIR}/.htaccess" ]
        then
            run_cmd "chmod -v 0644 \"${OC_DIR}/.htaccess\""
            run_cmd "chown -v ${rootuser}:${GROUP} \"${OC_DIR}/.htaccess\""
        fi
        if [ -f "${DATA_DIR}/.htaccess" ]
        then
            run_cmd "chmod -v 0644 \"${DATA_DIR}/.htaccess\""
            run_cmd "chown -v ${rootuser}:${GROUP} \"${DATA_DIR}/.htaccess\""
        fi
        
        #TODO: (ONLY IF UPGRADE SUCCEDED) rm -rf owncloud-bak owncloud-*.tar.gz
        
        #sometimes a file rescan is needed, may as well just do it
        run_cmd "sudo -u ${USER} php console.php files:scan --all"
        #we're done, I hope....
        run_cmd "sudo -u ${USER} php occ maintenance:mode --off"
        #cd -
    fi
fi

run_cmd "chown -R ${USER}:${GROUP} \"${DATA_DIR}\""
