#! /bin/bash

# The purpose of this wrapper script is to allow somw hosts to export gluster
# metrics while others don't. So, we probe for the gluster metrics and use
# the result to choose

function gethost {
    while [[ $# -gt 0 ]]; do
        if [ "$1" == "-h" ]; then
            echo "$2"
            return
        fi
        shift
    done
}

remotehost=$(gethost "$@")

# Collect samples for between 12 and 48 hrs before restarting
samples=$((720 + RANDOM%2160))

if pminfo -h "$remotehost" gluster >& /dev/null; then
    pcp2zabbix "$@" gluster -s $samples
else
    pcp2zabbix "$@" -s $samples
fi
