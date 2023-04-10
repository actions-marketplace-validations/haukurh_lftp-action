FROM alpine:latest

RUN apk add --no-cache openssh-client lftp

COPY resources/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
