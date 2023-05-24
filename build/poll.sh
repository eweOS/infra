#!/bin/bash

build=./build-nspawn.sh

poll_build(){
	PKG_PARAMS=$(
	curl -s -XPOST \
       		-d'{"count":1,"encoding":"auto","ackmode":"ack_requeue_false"}' \
       		$MQ_URL/api/queues/ttzfmhle/dispatch-`uname -m`/get \
		| jq -r '.[] | .payload' | jq -r '.pkgname + " " + .pkgrepo'
	)

	if [ ! -z "$PKG_PARAMS" ]; then
		echo "New task: $PKG_PARAMS."
		$build $PKG_PARAMS	
	else
		sleep 20
	fi
}

while true; do
	poll_build
done
