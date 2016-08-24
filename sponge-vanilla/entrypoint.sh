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
	if [ ! -f /sponge/spongevanilla-${SPONGE_VERSION}.jar ]; then
		wget -O /sponge/spongevanilla-${SPONGE_VERSION}.jar https://repo.spongepowered.org/maven/org/spongepowered/spongevanilla/${SPONGE_VERSION}/spongevanilla-${SPONGE_VERSION}.jar
		if [ -f /sponge/server.jar ]; then
			rm /sponge/server.jar
		fi
		ln -s /sponge/spongevanilla-${SPONGE_VERSION}.jar /sponge/server.jar
	fi
	if [ ! -f /sponge/eula.txt ]; then
		echo 'eula=true' > /sponge/eula.txt
	fi
}

function start_sponge() {
	java $@ -jar /sponge/server.jar
}

set -e
validate_environment
set -x
verify_installed
start_sponge "$@"

