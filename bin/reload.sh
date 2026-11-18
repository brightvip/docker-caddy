#!/bin/bash

for t in 1 3 5 10 30 60 90 120 150 200; do
    sleep $t
    sync
    caddy fmt /etc/caddy/Caddyfile --overwrite
    sync
    caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
done
