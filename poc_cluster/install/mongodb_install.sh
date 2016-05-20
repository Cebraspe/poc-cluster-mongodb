#!/bin/bash

SCRIPT_FILENAME="$( readlink -m $0 )"
SCRIPT_DIRNAME="$( echo $SCRIPT_FILENAME | sed 's/\(.*\)\/.*$/\1/' )"

# - - - - -

export DEBIAN_FRONTEND=noninteractive
echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" > /etc/apt/sources.list.d/mongodb.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
apt-get update
apt-get -y install mongodb-org

if [ "$( pwd )" == "/home/vagrant" ]; then
  patchfile="/home/vagrant/poc_cluster/install/mongod.patch"
else
  patchfile="${SCRIPT_DIRNAME}/mongod.patch"
fi

echo patch /etc/init.d/mongod ${patchfile}
systemctl daemon-reload
systemctl disable mongod
systemctl stop mongod
