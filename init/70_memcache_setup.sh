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

if [ ! -f "${OC_DIR}/config/config.php" ]
then
    run_cmd "cp -v /defaults/config.php \"${OC_DIR}/config/config.php\""
    run_cmd "chown -v ${USER}:${GROUP} \"${OC_DIR}/config/config.php\""
fi
