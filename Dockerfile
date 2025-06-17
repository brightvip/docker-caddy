FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-l4

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN apk update && apk upgrade && apk add curl bash unzip openssl procps


COPY bin /usr/app/bin
EXPOSE 8080
EXPOSE 8443
CMD /bin/bash -c "cat /usr/app/bin/start.sh | tr -d '\r'  | sh" \
    && caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
