#!/bin/bash

SCRIPT_FILENAME="$( readlink -m $0 )"
SCRIPT_DIRNAME="$( echo $SCRIPT_FILENAME | sed 's/\(.*\)\/.*$/\1/' )"

# - - - - -

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install apt-transport-https build-essential
wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_4.x jessie main" >  /etc/apt/sources.list.d/node.list
echo "deb-src https://deb.nodesource.com/node_4.x jessie main" >> /etc/apt/sources.list.d/node.list
apt-get update
apt-get -y install nodejs
