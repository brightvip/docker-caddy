#!/bin/bash

for t in 1 3 5 10 30 60 90 120 150 200; do
    sleep $t
    sync
    new_md5=`md5sum /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}'`
    if [ "$new_md5" != "${CADDY_FILE_MD5:-}" ]; then
        echo "reload"
        caddy fmt /etc/caddy/Caddyfile --overwrite
        sync
        caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
        export CADDY_FILE_MD5="$new_md5"
    fi
done
