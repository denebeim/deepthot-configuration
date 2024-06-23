#! /bin/bash

sudo wg-quick up deepthot
sudo resolvconf -a deepthot <<EOF
nameserver 192.168.42.2
nameserver 192.168.42.4
search deepthot.aa local.deepthot.org deepthot.org
EOF
