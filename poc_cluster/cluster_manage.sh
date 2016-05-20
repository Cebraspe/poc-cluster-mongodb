#!/bin/bash

SCRIPT_FILENAME="$( readlink -m $0 )"
SCRIPT_DIRNAME="$( echo $SCRIPT_FILENAME | sed 's/\(.*\)\/.*$/\1/' )"
CONFIG_DIRNAME="${SCRIPT_DIRNAME}/etc"

DIRMAPS="${CONFIG_DIRNAME}/dirmaps.conf"
RSCONFIG="${CONFIG_DIRNAME}/rsconfig.js"

MONGODB_DIR="/srv/mongodb"
REPLICA_SET_NAME="rs0"
OP_LOG_SIZE=128


# - - - - -


function port_start() {
  mongod --port ${1}                \
         --dbpath ${2}                  \
         --logpath ${2}.log             \
         --replSet ${REPLICA_SET_NAME}  \
         --oplogSize ${OP_LOG_SIZE}     \
         --fork                         \
         --smallfiles
}


function port_stop() {
  mongod --port ${1}    \
         --dbpath ${2}  \
         --shutdown
}


function mongocmd() {
    mongo --port ${1} \
          --eval "db = connect(\"localhost:${1}/clusterdb\"); db.getMongo().setSlaveOk(); ${2};"
}


function usage() {
  echo "Usage: ${0} ${1} [PORT]"
  exit 1
}


# - - - - -


case "$1" in
  start)
    [ ! -d ${MONGODB_DIR} ] && mkdir -p ${MONGODB_DIR}

    while IFS= read -r line; do
      port="$( echo ${line} | cut -d':' -f1 )"
      node="$( echo ${line} | cut -d':' -f2 )"

      rm -rf ${MONGODB_DIR}/${node} 2> /dev/null
      rm -rf ${MONGODB_DIR}/${node}.log 2> /dev/null
      mkdir -p ${MONGODB_DIR}/${node}

      port_start "${port}" "${MONGODB_DIR}/${node}"
    done < <( cat ${DIRMAPS} | grep -v '^#' | sed '/^ *$/d' )

    mongo --port "${port}" "${RSCONFIG}"
  ;;

  stop)
    while IFS= read -r line; do
      port="$( echo ${line} | cut -d':' -f1 )"
      node="$( echo ${line} | cut -d':' -f2 )"

      port_stop "${port}" "${MONGODB_DIR}/${node}"
    done < <( cat ${DIRMAPS} | grep -v '^#' | sed '/^ *$/d' )
  ;;

  port-start)
    [ -z "$2" ] && usage "port-start"

    while IFS= read -r line; do
      port="$( echo ${line} | cut -d':' -f1 )"
      node="$( echo ${line} | cut -d':' -f2 )"

      port_start "${port}" "${MONGODB_DIR}/${node}"
    done < <( cat ${DIRMAPS} | grep "^$2" )
  ;;

  port-stop)
    [ -z "$2" ] && usage "port-stop"

    while IFS= read -r line; do
      port="$( echo ${line} | cut -d':' -f1 )"
      node="$( echo ${line} | cut -d':' -f2 )"

      port_stop "${port}" "${MONGODB_DIR}/${node}"
    done < <( cat ${DIRMAPS} | grep "^$2" )
  ;;

  rs-conf)
    [ -z "$2" ] && usage "rs-conf"

    mongocmd ${2} "rs.conf()"
  ;;

  rs-status)
    [ -z "$2" ] && usage "rs-status"

    mongocmd ${2} "rs.status()"
  ;;

  query)
    [ -z "$2" ] && usage "query"

    mongocmd ${2} "db.clustercol.find()"
  ;;

  status)
    ports="$( netstat -tunlp | grep 'mongod *$' | sed 's/  */:/g' | cut -d':' -f5 )"

    if [ -z "$ports" ]; then
      echo "mongodb cluster is NOT running."
    else
      echo -e "mongodb is RUNNING on ports:\n$ports"
    fi
  ;;

  *)
    echo "Usage: $0 (start|stop|port-start|port-stop|rs-conf|rs-status|query|status)"
    exit 1
  ;;
esac

exit 0
