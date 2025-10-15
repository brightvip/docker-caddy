#!/bin/bash

fallocate -l 512M /usr/app/bin/swapfile
chmod 0600 /usr/app/bin/swapfile
mkswap /usr/app/bin/swapfile
swapon /usr/app/bin/swapfile
echo 10 > /proc/sys/vm/swappiness
echo 1 > /proc/sys/vm/overcommit_memory
