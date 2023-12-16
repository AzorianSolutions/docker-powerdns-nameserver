#!/bin/bash

[ -n "$DEBUG" ] && [ "$DEBUG" -gt 0 ] && set -x

set -eo pipefail

convert_file_vars() {
    for line in $(env)
    do
        if [[ $line == PDNS_* ]] || [[ $line == AS_* ]];
        then
            if [[ $line =~ ^.*_FILE ]];
            then
                local INDEX=$( echo $line | grep -aob '=' | grep -oE '[0-9]+')
                local LEN=$( echo $line | wc -c)
                local NAME_END_INDEX=$(($INDEX - 5))
                local NAME_FULL=$( echo $line | cut -c1-$INDEX)
                local NAME=$( echo $line | cut -c1-$NAME_END_INDEX)
                INDEX=$(($INDEX + 2))
                local VALUE=$( echo $line | cut -c$INDEX-$LEN)
                local FILE_VALUE=`cat $VALUE`
                export $NAME=$FILE_VALUE
                unset $NAME_FULL
            fi
        fi
    done
}

verify_mysql_ready() {
        local host=$1
        local port=$2
        local retry_count=${AS_MYSQL_CHECK_RETRY:-10}
        local retry_sleep=${AS_MYSQL_CHECK_INTERVAL:-4}
        local retry_remaining=$retry_count
        local retry_executed=$(($retry_count - $retry_remaining))
        echo "Executing TCP connection test cycle number $retry_executed to $host:$port."
        set +eo pipefail
        while ! nc -w 1 -z $host $port >& /dev/null
        do
        	# The connection test to the MySQL server port failed at this point
        	# Decrement remaining retry counter by one
                retry_remaining=$(( $retry_remaining - 1 ))
                # Increment the retry execution counter
                retry_executed=$(( $retry_count - $retry_remaining ))
                # If the remaining retry counter falls to zero, exit the connection test cycle
                if [ $retry_remaining -eq 0 ]; then
                        break
                else
                        echo "The TCP connection test cycle number $retry_executed has failed to $host:$port."
                fi
                echo "Waiting for $retry_sleep seconds before executing next TCP connection test."
                # Pause the script for the configured delay interval
                sleep $retry_sleep
                echo "check host: retry check $host:$port interval=$retry_sleep rest=$retry_count"
                retry_executed=$(( $retry_count - $retry_remaining ))
                echo "Executing TCP connection test cycle number $retry_executed to $host:$port."
        done
        set -eo pipefail
        if [ $retry_remaining -eq 0 ]; then
                echo "The maximum number ($retry_count) of TCP connection tests has been executed without success. This container will now exit."
                return 1
        fi
        echo "The TCP connection test cycle number $retry_executed has succeeded to $host:$port."
        return 0
}

# if command starts with an option, prepend the appropriate PDNS server command name
if [ "${1:0:1}" = '-' ]; then
	set -- pdns_server "$@"
fi

# Automatically convert any environment variables that are prefixed with "PDNS_" or "AS_" and suffixed with "_FILE"
convert_file_vars

# Verify that the configured MySQL server is ready for connections
verify_mysql_ready "${PDNS_gmysql_host}" "${PDNS_gmysql_port:-3306}"

config_file=/etc/pdns/pdns.conf

# Create the PowerDNS config file from the service config template
cd /srv
source venv/bin/activate
envtpl < /srv/service.conf.tpl > $config_file

# Apply appropriate ownership to the PowerDNS config file
chown ${PDNS_setuid}:${PDNS_setgid} $config_file

exec "$@"
