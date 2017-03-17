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

if [[ -f "${CONFIG_DIR}/keys/cert.key" && -f "${CONFIG_DIR}/keys/cert.crt" ]]
then
    echo "using existing keys in \"${CONFIG_DIR}/keys\""
else
    echo "generating self-signed keys in ${CONFIG_DIR}/keys, you can replace these with your own keys if required"
    run_cmd "openssl req -new -x509 -days 3650 -nodes -out \"${CONFIG_DIR}/keys/cert.crt\" -keyout \"${CONFIG_DIR}/keys/cert.key\" -subj \"//C=US/ST=CA/L=Carlsbad/O=Linuxserver.io/OU=LSIO Server/CN=*\""
fi

run_cmd "chown -v ${USER}:${GROUP} -R \"${CONFIG_DIR}/keys\""
