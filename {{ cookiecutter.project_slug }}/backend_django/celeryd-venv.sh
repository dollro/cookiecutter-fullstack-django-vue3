#!/bin/bash

CELERY_CONFIG_FILE=$1

[ ! -f $CELERY_CONFIG_FILE ] && echo "Error: Config file $CELERY_CONFIG_FILE not found. Aborting." >&2 && exit 1

# source additional config file if given in command line
#[ ! "X$4" == "Xdev" ] && [ ! "X$4" == "Xprod" ]  && source $4

. $CELERY_CONFIG_FILE

if [ "$2" == "worker" ] || [ "$2" == "beat" ] ; then
case $3 in
  start|stop)
       celery_init
       celery_$2_$3
       ;;
  restart)
       celery_init
       celery_$2_stop
       celery_$3_start
       ;;
esac
fi
