## v2.5.0 - breaking changes in the configuration
#FROM haproxy:alpine
FROM haproxy:2.3.10-alpine

ADD templates /docker-config
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
