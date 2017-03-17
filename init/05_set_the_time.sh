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

if [[ $(cat /etc/timezone) != "${TZ}" ]]
then
    echo "${TZ}" > /etc/timezone
    run_cmd "dpkg-reconfigure -f noninteractive tzdata"
    run_cmd "sed -i -e \"s#;date.timezone.*#date.timezone = ${TZ}#g\" /etc/php/7.0/fpm/php.ini"
    run_cmd "sed -i -e \"s#;date.timezone.*#date.timezone = ${TZ}#g\" /etc/php/7.0/cli/php.ini"
fi

