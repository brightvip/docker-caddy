FROM caddy:latest

RUN apk update && apk upgrade && apk add curl bash unzip openssl procps


COPY bin /usr/app/bin
EXPOSE 8080
EXPOSE 8443
EXPOSE 9400
CMD /bin/bash -c "cat /usr/app/bin/start.sh | tr -d '\r'  | sh" \
    && caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
