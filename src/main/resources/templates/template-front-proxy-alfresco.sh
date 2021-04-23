#!/bin/sh

set -e

HAPROXY_INCLUDE_WORKSPACE=${HAPROXY_INCLUDE_WORKSPACE:-false}
HAPROXY_INCLUDE_SHARE=${HAPROXY_INCLUDE_SHARE:-false}
HAPROXY_INCLUDE_FINDER=${HAPROXY_INCLUDE_FINDER:-false}
HAPROXY_INCLUDE_OOI=${HAPROXY_INCLUDE_OOI:-false}
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
  tune.ssl.default-dh-param 2048
  ssl-default-bind-ciphers ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
  ssl-default-bind-options no-sslv3 no-tls-tickets
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
  cookie ${HAPROXY_COOKIE:-JSESSIONID} prefix nocache
  balance ${HAPROXY_BALANCE:-hdr(X-Forwarded-For)}
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

########## internet frontend
echo "
frontend ${HAPROXY_FRONTEND_INTERNET:-internet}
  bind ${HAPROXY_FRONTEND_INTERNET_BIND:-*:80}
  default_backend ${HAPROXY_BACKEND_ALFRESCO:-alfresco}
  capture request header X-Forwarded-For len 15"
if [[ $HAPROXY_INCLUDE_SHARE = 'true' ]]
then
  echo "  use_backend ${HAPROXY_BACKEND_SHARE:-share} if { path_beg /share }" 
fi
if [[ $HAPROXY_INCLUDE_WORKSPACE = 'true' ]]
then
  echo "  use_backend ${HAPROXY_BACKEND_WORKSPACE:-workspace} if { path_beg /workspace }
  redirect code 301 prefix / drop-query append-slash if { path_reg ^/workspace$ }" 
fi
if [[ $HAPROXY_INCLUDE_FINDER = 'true' ]]
then
  echo "  use_backend ${HAPROXY_BACKEND_FINDER:-finder} if { path_beg /finder }"
fi
if [[ $HAPROXY_INCLUDE_OOI = 'true' ]]
then
  echo "  use_backend ${HAPROXY_BACKEND_OOI:-ooi-service} if { path_beg /ooi-service }"
fi

########## alfresco backend
echo "
backend ${HAPROXY_BACKEND_ALFRESCO:-alfresco}
  option httpchk OPTIONS ${HAPROXY_BACKEND_ALFRESCO_CHECK:-/alfresco/s/api/server}
  server-template ${HAPROXY_BACKEND_ALFRESCO:-alfresco}- ${HAPROXY_BACKEND_ALFRESCO_COUNT:-1} ${HAPROXY_SERVICE_ALFRESCO:-alfresco}:8080 check resolvers docker init-addr libc,none
  acl blacklist_alfresco path_sub /proxy/alfresco/api/solr/
  acl blacklist_alfresco path_sub /-default-/proxy/alfresco/api/
  acl blacklist_alfresco path_sub /service/api/solr/
  acl blacklist_alfresco path_sub /s/api/solr/
  acl blacklist_alfresco path_sub /wcservice/api/solr/
  acl blacklist_alfresco path_sub /wcs/api/solr/
  http-request deny if blacklist_alfresco"

########## share backend
if [[ $HAPROXY_INCLUDE_SHARE = 'true' ]]
then
echo "
backend ${HAPROXY_BACKEND_SHARE:-share}
  option httpchk OPTIONS ${HAPROXY_BACKEND_SHARE_CHECK:-/share}
  server-template ${HAPROXY_BACKEND_SHARE:-share}- ${HAPROXY_BACKEND_SHARE_COUNT:-1} ${HAPROXY_SERVICE_SHARE:-share}:8080 check resolvers docker init-addr libc,none"
fi

########## digital workspace backend
if [[ $HAPROXY_INCLUDE_WORKSPACE = 'true' ]]
then
echo "
backend ${HAPROXY_BACKEND_WORKSPACE:-workspace}
  option httpchk GET ${HAPROXY_BACKEND_WORKSPACE_CHECK:-/workspace}
  http-request replace-uri ([^\ :]*?)/workspace(.*) \1/\2
  server-template ${HAPROXY_BACKEND_WORKSPACE:-workspace}- ${HAPROXY_BACKEND_WORKSPACE_COUNT:-1} ${HAPROXY_SERVICE_WORKSPACE:-digital-workspace}:8080 check resolvers docker init-addr libc,none"
fi

########## finder backend
if [[ $HAPROXY_INCLUDE_FINDER = 'true' ]]
then
echo "
backend ${HAPROXY_BACKEND_FINDER:-finder}
  option httpchk GET ${HAPROXY_BACKEND_FINDER_CHECK:-/}
  http-request replace-uri ([^\ :]*?)/finder(.*) \1/\2
  server-template ${HAPROXY_BACKEND_FINDER:-finder}- ${HAPROXY_BACKEND_FINDER_COUNT:-1} ${HAPROXY_SERVICE_FINDER:-alfred-finder}:80 check resolvers docker init-addr libc,none"
fi

########## ooi-service backend
if [[ $HAPROXY_INCLUDE_OOI = 'true' ]]
then
echo "
backend ${HAPROXY_BACKEND_OOI:-ooi-service}
  server-template ${HAPROXY_BACKEND_OOI:-ooi-service}- ${HAPROXY_BACKEND_OOI_COUNT:-1} ${HAPROXY_SERVICE_OOI:-alfresco-ooi-service}:9095 check resolvers docker init-addr libc,none"
fi

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
