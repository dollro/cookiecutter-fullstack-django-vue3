#!/bin/bash
trap "kill 0" EXIT

usage() {
	echo "Usage: $0 [-c] [-r <django|vue|all>] [-e <path to file>]" 1>&2;
  echo "-r: select which dvmnt servers to start";
	echo "-e: path to file with environment variables to source";
	exit 1;
	}

while getopts ":e:r:" opt; do
  case $opt in
    e)
			envfile="$OPTARG"
    	;;
    r)
			run="$OPTARG"
			(( $run == "django" || $run == "vue" || $run == "all" )) || usage
			;;
    *)
			usage
			;;
  esac
done
[ -z $envfile ] && [ -z $run ] && usage

if [ ! -z $envfile ]; then
	echo "sourcing environment variables from $envfile"
	set -a
	source $envfile
	set +a
fi

if [ "$run" = "django" ] || [ "$run" = "all" ] ; then
		touch mailhog.log
		echo "------ START MAILHOG SESSION ------" >> mailhog.log
		docker run -p 1025:1025 -p 8025:8025 mailhog/mailhog >> log/mailhog.log 2>&1 &
		PID_MAILHOG=$!
		echo "DOCKER MAILHOG STARTED (PID: $PID_MAILHOG)"

		if [ "$run" = "all" ]; then
			pnpm --prefix ./frontend_vue run dev 2>&1 &
			PID_VUE=$!
			echo "VUE FRONTEND STARTED (PID: $PID_VUE)"
		fi

		#Start local django development server, and wait until it is manually stopped
		python backend_django/manage.py runserver 127.0.0.1:8000 --nothreading
		#python backend_django/manage.py runserver_plus --cert-file cert/cert.pem --key-file cert/key.pem 127.0.0.1:8000 --nothreading

		echo ""
		echo ""
		echo "Django development server, mailhog, npm vite subprocesses stopped"

fi

if [ "$run" = "vue" ]; then
	pnpm --dir ./frontend_vue run dev
fi
