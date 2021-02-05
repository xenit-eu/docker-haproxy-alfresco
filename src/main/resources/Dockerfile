FROM haproxy:alpine

ADD templates /docker-config
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
