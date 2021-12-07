#!/bin/sh
set -e

echo "Custom haproxy init start"

HAPROXY_TEMPLATE=${HAPROXY_TEMPLATE:-"template-front-proxy-alfresco.sh"}
sh /docker-config/${HAPROXY_TEMPLATE} >/usr/local/etc/haproxy/haproxy.cfg

echo "Custom haproxy init stop"

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	shift # "haproxy"
	# if the user wants "haproxy", let's add a couple useful flags
	#   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
	#   -db -- disables background mode
	set -- haproxy -W -db "$@"
fi

exec "$@"
