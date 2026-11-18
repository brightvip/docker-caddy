#!/bin/bash

sleep 10s
sync
caddy fmt /etc/caddy/Caddyfile --overwrite
sync
caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
