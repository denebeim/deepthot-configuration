#!/usr/bin/env bash
# Usage: restorek8s "date/time"

machines="401 402 403 405 406 407 411 412 413 414 415"
bups=$(pvesm list pbs | grep $1)

for m in $machines; do
    bak=$(
        awk "/$m/{print \$1}" <<<"$bups"
    )
    qmrestore $bak $m --force
