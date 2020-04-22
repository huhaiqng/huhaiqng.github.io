#!/bin/bash
set -e
cd /var/log/nginx/
rm -f `ls -t error.log-*.gz | tail -n +15`
rm -f `ls -t access.log-*.gz | tail -n +15`
