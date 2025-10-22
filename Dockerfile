FROM caddy:latest

COPY bin /usr/app/bin

RUN apk update && \
    apk upgrade && \
    apk add curl bash unzip openssl procps

EXPOSE 8080 8443

CMD /bin/bash -c "cat /usr/app/bin/start.sh | tr -d '\r'  | sh" && \
    caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
