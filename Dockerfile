FROM caddy:latest

COPY bin /usr/app/bin

RUN apk update && \
    apk upgrade && \
    apk add curl bash unzip openssl procps && \
    sed -i 's/\r$//' /usr/app/bin/start.sh && chmod +x /usr/app/bin/start.sh

EXPOSE 8080 8443

ENTRYPOINT ["/usr/app/bin/start.sh"]
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
