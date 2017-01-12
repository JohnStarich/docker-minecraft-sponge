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

function ensure_correct_sponge_version() {
    set -e
    set -x
    if [[ "$SPONGE_VERSION" == 'latest' || \
          "$SPONGE_VERSION" == 'latest-stable' || \
          "$SPONGE_VERSION" == 'latest-unstable' || \
          "$SPONGE_VERSION" == 'latest-bleeding' ]]; then
        local unstable_version='.buildTypes.bleeding.latest.version'
        local stable_version='.buildTypes.stable.latest.version'
        local version_api='https://dl-api.spongepowered.org/v1/org.spongepowered/spongevanilla'

        local version_req=$(curl -L "$version_api")
        local versions=$(jq -r "$unstable_version,$stable_version" <<<$version_req)
        local versions=$(tr '\n' ' ' <<<$versions)
        local unstable_v=$(awk '{ print $1 }' <<< $versions)
        local stable_v=$(awk '{ print $2 }' <<< $versions)

        if [[ "$SPONGE_VERSION" == 'latest' || "$SPONGE_VERSION" == 'latest-stable' ]]; then
            SPONGE_VERSION=$stable_v
        else
            SPONGE_VERSION=$unstable_v
        fi
    fi
}

function validate_environment() {
    ensure_correct_sponge_version
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
    if [ ! -f /sponge/server.properties ]; then
        cat > /sponge/server.properties <<EOT
server-port=$MINECRAFT_PORT
motd=A Docker-Powered Minecraft Server
EOT
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
    java $@ -jar /sponge/server.jar <&3 | tee /var/log/sponge.log &
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
