#!/bin/bash

function error_cli() {
    set +x
    echo "$@" >&2
    return 2
}

function error() {
    set +x
    echo "$@" >&2
    return 1
}

function validate_environment() {
    local required_vars=(
        MINECRAFT_PORT
        SPONGE_VERSION
    )
    local failed=false
    for req_var in ${required_vars[@]}; do
        eval local value=\$$req_var
        if [ -z "$value" ]; then
            echo "$req_var is a required environment variable" >&2
            failed=true
        fi
    done
    if [[ "$failed" == true ]]; then
        return $(error_cli 'Provide all required environment variables before trying again.')
    fi
}

function verify_installed() {
    if [ ! -f "/sponge/spongevanilla-${SPONGE_VERSION}.jar" ]; then
        wget -O "/sponge/spongevanilla-${SPONGE_VERSION}.jar" "https://repo.spongepowered.org/maven/org/spongepowered/spongevanilla/${SPONGE_VERSION}/spongevanilla-${SPONGE_VERSION}.jar"
        if [ -f /sponge/server.jar ]; then
            rm /sponge/server.jar
        fi
        ln -s "/sponge/spongevanilla-${SPONGE_VERSION}.jar" /sponge/server.jar
    fi
    if [ ! -f /sponge/eula.txt ]; then
        echo 'eula=true' > /sponge/eula.txt
    fi
}

function trap_sponge_shutdown() {
    SPONGE_RUNNING=false
    sponge_cmd say Shutting down...
    sponge_cmd stop
    wait $SPONGE_PID
    return 0
}

function prepare_startup() {
    if [[ ! -p server_fifo ]]; then
        mkfifo server_fifo
    fi
    trap trap_sponge_shutdown TERM
    exec 3<>server_fifo
}

function prepare_shutdown() {
    exec 3<&-
}

function sponge_cmd() {
    echo "$@" >&3
}

function run_sponge() {
    # Start the sponge server and attach input
    java $@ -jar /sponge/server.jar < server_fifo | tee /var/log/sponge.log &
    SPONGE_PID=$!
    wait $SPONGE_PID
}

# Exit if any step has non-zero exit code
set -e
# Enable job control
set -m
validate_environment
set -x
verify_installed
prepare_startup
set +x
# Continue running Sponge server until explicitly told to shutdown.
SPONGE_RUNNING=true
while [[ "$SPONGE_RUNNING" == true ]]; do
    echo 'Starting Sponge server...'
    sleep 2
    run_sponge $@
done
prepare_shutdown
