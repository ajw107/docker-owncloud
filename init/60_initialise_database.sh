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

# set start function that creates user and password, used later
start_mysql(){
mysqld --init-file="$tempSqlFile" &
pid="$!"
RET=1
while [[ RET -ne 0 ]]
do
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
    sleep 1
done
}

# test for existence of mysql file in datadir and start initialise if not present
if [ ! -d "${MYSQL_DIR}/mysql" ]
then
    echo "MYSQL_DIR: [${MYSQL_DIR}]"
    # set basic sql command
    tempSqlFile='/tmp/mysql-first-time.sql'
    cat > "$tempSqlFile" <<-EOSQL
DELETE FROM mysql.user ;
EOSQL

    # set what to display if no password set with variable DB_PASS
    NOPASS_SET='/tmp/no-pass.nfo'
    cat > "$NOPASS_SET" <<-EOFPASS
###############################################################################
# No owncloud mysql password or too short a password set, min of 4 characters #
# default password 'owncloud' will be used this will be both the password for #
# the root user and the owncloud database                                     #
###############################################################################
EOFPASS

    # test for empty password variable, if it's set to 0 or less than 4 characters
    if [ -z "${DB_PASSWORD}" ]
    then
        TEST_LEN="0"
    else
        TEST_LEN=${#DB_PASSWORD}
    fi
    if [ "$TEST_LEN" -lt "4" ]
    then
        OWNCLOUD_PASS="owncloud"
    else
        OWNCLOUD_PASS="${DB_PASSWORD}"
    fi

    echo "OwnCloud DB Password will be [${DB_PASSWORD}]"

    # add rest of sql commands based on password set or not
    cat >> "$tempSqlFile" <<-EONEWSQL
CREATE USER 'root'@'%' IDENTIFIED BY '${OWNCLOUD_PASS}' ;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
CREATE USER 'owncloud'@'localhost' IDENTIFIED BY '${OWNCLOUD_PASS}' ;
CREATE DATABASE IF NOT EXISTS owncloud;
GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY '${OWNCLOUD_PASS}' ;
EONEWSQL
    echo "Setting Up Initial Databases"

    # set some permissions needed before we begin initialising
    run_cmd "chown -R ${USER}:${GROUP} \"${CONFIG_DIR}/log/mysql\" /var/run/mysqld"
    run_cmd "chmod -R 777 \"${CONFIG_DIR}/log/mysql\" /var/run/mysqld"

    # initialise database structure
    run_cmd "sudo mysqld --initialize-insecure --datadir=\"${MYSQL_DIR}\""

    # start mysql and apply our sql commands we set above
    run_cmd "start_mysql"

    # shut down after apply sql commands, waiting for pid to stop
    run_cmd "mysqladmin -u root  shutdown"
    run_cmd "wait \"$pid\""
    echo "Database Setup Completed"

    # display a message about password if not set or too short
    if [ "$TEST_LEN" -lt "4" ]
    then
        less /tmp/no-pass.nfo
        sleep 5s
    fi

    # do some more owning to finish our first run sequence
    run_cmd "chown -R ${USER}:${GROUP} \"${MYSQL_DIR}\" \"${CONFIG_DIR}/log/mysql\""
fi

# own the folder the pid for mysql runs in
run_cmd "chown -R ${USER}:${GROUP} /var/run/mysqld"
run_cmd "chown -R ${USER}:${GROUP} /var/lib/mysql"


# clean up any old install files from /tmp
if [ -f "/tmp/no-pass.nfo" ]
then
    run_cmd "rm -v /tmp/no-pass.nfo"
fi

if [ -f "/tmp/mysql-first-time.sql" ]
then
    run_cmd "rm -v /tmp/mysql-first-time.sql"
fi

run_cmd "sed -i s#/var/www/owncloud#${OC_DIR}#g /defaults/owncloud"
run_cmd "crontab -u ${USER} /defaults/owncloud"
echo "Crontab updated"
run_cmd "crontab -u ${USER} -l"
#won't the line below undo everything above???
#chown -R ${USER}:${GROUP} "{CONFIG_DIR}"
