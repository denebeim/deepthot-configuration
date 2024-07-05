#! /bin/bash

sudo wg-quick up deepthot
sudo resolvconf -a deepthot <<EOF
nameserver 192.168.42.4
nameserver 192.168.42.2
search local.deepthot.org deepthot.aa deepthot.org
EOF
