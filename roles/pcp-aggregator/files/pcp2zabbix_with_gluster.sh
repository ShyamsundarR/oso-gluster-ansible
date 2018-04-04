#! /bin/bash

# The purpose of this wrapper script is to allow somw hosts to export gluster
# metrics while others don't. So, we first try with, and if that fails, without.

pcp2zabbix "$@" gluster || pcp2zabbix "$@"
