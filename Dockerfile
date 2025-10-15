FROM caddy:latest

COPY entrypoint.sh /entrypoint.sh
COPY bin /usr/app/bin

RUN chmod +x /entrypoint.sh && \
    apk update && \
    apk upgrade && \
    apk add curl bash unzip openssl procps

EXPOSE 8080
EXPOSE 8443
ENTRYPOINT ["/entrypoint.sh"]
CMD /bin/bash -c "cat /usr/app/bin/start.sh | tr -d '\r'  | sh" \
    && caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
