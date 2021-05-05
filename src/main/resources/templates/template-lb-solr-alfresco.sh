#!/bin/sh

set -e

HAPROXY_SEND_LOGS=${HAPROXY_SEND_LOGS:-false}
HAPROXY_INCLUDE_FRONTEND_STATS=${HAPROXY_INCLUDE_FRONTEND_STATS:-true}

########## global
echo "
global
  log-send-hostname ${HAPROXY_HOSTNAME:-localhost}
  log stdout format raw local0 debug
  maxconn 4096
  nbthread 1
  uid 99
  gid 99
  stats socket /var/run/haproxy.sock mode 600 level admin
  stats timeout ${HAPROXY_STATS_TIMEOUT:-2m}"

if [[ $HAPROXY_SEND_LOGS = 'true' ]]
then
  echo "
  log ${HAPROXY_LOGS_SERVER:-10.88.10.50:514} len 2048 local0" 
fi

########## defaults
echo "
defaults
  log global
  mode http
  balance ${HAPROXY_BALANCE:-leastconn}
  retries 2
  timeout client ${HAPROXY_TIMEOUT_CLIENT:-30m}
  timeout connect ${HAPROXY_TIMEOUT_CONNECT:-4s}
  timeout server ${HAPROXY_TIMEOUT_SERVER:-30m}
  timeout check ${HAPROXY_TIMEOUT_CHECK:-5s}
  option redispatch
  option httplog"

########## stats frontend
if [[ $HAPROXY_INCLUDE_FRONTEND_STATS = 'true' ]]
then
echo "
frontend ${HAPROXY_FRONTEND_STATS:-stats}
   bind *:8404
   option http-use-htx
   http-request use-service prometheus-exporter if { path /metrics }
   stats enable
   stats uri /stats
   stats refresh 10s"
fi

########## solr frontend
echo "
frontend ${HAPROXY_FRONTEND_SOLR:-solr}
  bind ${HAPROXY_FRONTEND_SOLR_BIND:-*:8880}
  default_backend ${HAPROXY_BACKEND_ALFRESCO:-alfresco}" 

########## alfresco backend
echo "
backend ${HAPROXY_BACKEND_ALFRESCO:-alfresco}
  option httpchk GET ${HAPROXY_BACKEND_ALFRESCO_CHECK:-/alfresco/s/api/server}
  server-template ${HAPROXY_BACKEND_ALFRESCO:-alfresco}- ${HAPROXY_BACKEND_ALFRESCO_COUNT:-1} ${HAPROXY_SERVICE_ALFRESCO:-alfresco}:8080 check resolvers docker init-addr libc,none"

########## resolvers
echo "
resolvers docker
  nameserver docker 127.0.0.11:53
  resolve_retries ${HAPROXY_RESOLVE_RETRIES:-3}
  timeout resolve ${HAPROXY_TIMEOUT_RESOLVE:-1s}
  timeout retry   ${HAPROXY_TIMEOUT_RETRY:-1s}
  hold other      ${HAPROXY_HOLD_OTHER:-10s}
  hold refused    ${HAPROXY_HOLD_REFUSED:-10s}
  hold nx         ${HAPROXY_HOLD_NX:-10s}
  hold timeout    ${HAPROXY_HOLD_TIMEOUT:-10s}
  hold valid      ${HAPROXY_HOLD_VALID:-10s}
  hold obsolete   ${HAPROXY_HOLD_OBSOLETE:-10s}" 
