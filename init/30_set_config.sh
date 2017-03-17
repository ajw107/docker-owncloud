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

# make folders if required
run_cmd "mkdir -pv \"${CONFIG_DIR}/\"{nginx/site-confs,log/mysql,log/nginx,keys} /var/run/{php,mysqld}"

# configure mariadb
# setup custom cnf file
#maybe we should just nuke any config files in favour of our own?  Then when the config files are updates they will be used rather than the old ones
#[[ ! -f "${CONFIG_DIR}/custom.cnf" ]] && cp /defaults/my.cnf "${CONFIG_DIR}/custom.cnf"
#[[ ! -L /etc/mysql/conf.d/custom.cnf && -f /etc/mysql/conf.d/custom.cnf ]] && rm /etc/mysql/conf.d/custom.cnf
#[[ ! -L /etc/mysql/conf.d/custom.cnf ]] && ln -s "${CONFIG_DIR}/custom.cnf" /etc/mysql/conf.d/custom.cnf
run_cmd "cp -v /defaults/my.cnf \"${CONFIG_DIR}/custom.cnf\""
if [ -f /etc/mysql/conf.d/custom.cnf ]
then
    run_cmd "rm -v /etc/mysql/conf.d/custom.cnf"
fi
run_cmd "ln -sv \"${CONFIG_DIR}/custom.cnf\" /etc/mysql/conf.d/custom.cnf"
#also move old locations into user defineable ones
if [ ! "/config" == "${CONFIG_DIR}" ]
then
    echo "Config Directory moved from /config to ${CONFIG_DIR}, moving old data across..."
    if [ ! -d "${CONFIG_DIR}" ]
    then
        run_cmd "mkdir -pv \"${CONFIG_DIR}\""
    fi
    #check if directory actually contains anything first
    if [ -d "/config" ]
    then
        if test "$(ls -A /config)"
        then
            run_cmd "find /config -maxdepth 1 -exec mv -v \"{}\" \"${CONFIG_DIR}/\" \\;"
        fi
    fi
fi
if [ ! "/config/www/owncloud/data" == "${DATA_DIR}" ] && [ ! "/data" == "${DATA_DIR}" ]
then
    echo "Data Directory moved from /data to ${DATA_DIR}, moving old data across..."
    #remember config is moved above
    if [ ! -d "${DATA_DIR}" ]
    then
        run_cmd "mkdir -pv \"${DATA_DIR}\""
    fi
    #check if directory actually contains anything first
    if [ -d "${CONFIG_DIR}/www/owncloud/data)" ]
    then
        if test "$(ls -A ${CONFIG_DIR}/www/owncloud/data)"
        then
            run_cmd "find \"${CONFIG_DIR}/www/owncloud/data/\" -maxdepth 1 -exec mv -v \"{}\" \"${DATA_DIR}/\" \\;"
        fi
    fi
fi
if [ -f "/config/www/owncloud/config/config.php" ]
then
    run_cmd "mv /config/www/owncloud/config/config.php \"${OC_DIR}/config/config.php\""
fi
#make sure the data dir is set correctly in ownclouds config file
if [ ! "/config/www/owncloud/data" == "${DATA_DIR}" ]
then
    run_cmd "sed -i s#/config/www/owncloud/data#${DATA_DIR}#g \"${OC_DIR}/config/config.php\""
fi

run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -i 's/key_buffer\\b/key_buffer_size/g' \"{}\" \\;"
run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -ri 's/^(bind-address|skip-networking)/;\\1/' \"{}\" \\;"
run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -i s#/var/log/mysql#${CONFIG_DIR}/log/mysql#g \"{}\" \\;"
run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -i s#/config#${CONFIG_DIR}#g \"{}\" \\;"
run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -i -e \"s/\\(user.*=\\).*/\\1 ${USER}/g\" \"{}\" \\;"
run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -i -e \"s#\\(datadir.*=\\).*#\\1 ${MYSQL_DIR}#g\" \"{}\" \\;"
run_cmd "find /etc/mysql -type f -iname \"*.cnf\" -exec sed -i -e \"s#\\(binlog_format.*=\\).*#\\1 mixed#g\" \"{}\" \\;"
run_cmd "sed -i \"s/user='mysql'/user='${USER}'/g\" /usr/bin/mysqld_safe"
#also move old locations into user defineable ones
if [ ! "/config/database" == "${MYSQL_DIR}" ]
then
    echo "MySQL Directory moved fromm /config/database to ${MYSQL_DIR}, moving old data across..."
    #remember config is moved above
    if [ ! -d "${MYSQL_DIR}" ]
    then
        run_cmd "mkdir -pv \"${MYSQL_DIR}\""
    fi
    if test "$(ls -A ${CONFIG_DIR}/database)"
    then
        run_cmd "find \"${CONFIG_DIR}/database\" -maxdepth 1 -exec mv -v \"{}\" \"${MYSQL_DIR}/\" \\;"
    fi
fi

# configure nginx
#[[ ! -f "${CONFIG_DIR}/nginx/nginx.conf" ]] && cp /defaults/nginx.conf "${CONFIG_DIR}/nginx/nginx.conf"
#[[ ! -f "${CONFIG_DIR}/nginx/nginx-fpm.conf" ]] && cp /defaults/nginx-fpm.conf "${CONFIG_DIR}/nginx/nginx-fpm.conf"
#[[ ! -f "${CONFIG_DIR}/nginx/site-confs/default" ]] && cp /defaults/default "${CONFIG_DIR}/nginx/site-confs/default"
run_cmd "cp -v /defaults/nginx.conf \"${CONFIG_DIR}/nginx/nginx.conf\""
run_cmd "cp -v /defaults/nginx-fpm.conf \"${CONFIG_DIR}/nginx/nginx-fpm.conf\""
run_cmd "cp -v /defaults/default \"${CONFIG_DIR}/nginx/site-confs/default\""
if [ ! "/config" == "${CONFIG_DIR}" ]
then
    run_cmd "sed -i s#/config#${CONFIG_DIR}#g \"${CONFIG_DIR}/nginx/nginx.conf\""
    run_cmd "sed -i s#/config#${CONFIG_DIR}#g \"${CONFIG_DIR}/nginx/nginx-fpm.conf\""
    run_cmd "sed -i s#/config#${CONFIG_DIR}#g \"${CONFIG_DIR}/nginx/site-confs/default\""
fi

run_cmd "chown ${USER}:${GROUP} \"${MYSQL_DIR}\""
run_cmd "chown -R ${USER}:${GROUP} \"${CONFIG_DIR}\" /var/run/php"
run_cmd "chmod -R 777 /var/run/mysqld"
run_cmd "chmod -R 777 /var/lib/mysql"
