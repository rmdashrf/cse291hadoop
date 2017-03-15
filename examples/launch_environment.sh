#!/bin/bash

set -u

DOCKER='docker'

NUM_SLAVES=4
NETWORK_NAME='test_cse291_lab3'
IMAGE_NAME='rmdashrf/cse291hadoop'

# Must use dashes, since this will be interpretted as hostname
CONTAINER_PREFIX='test-cse291-hadoop-'


cleanup() {
    relevant_containers=$($DOCKER ps --format '{{.Names}}' | grep $CONTAINER_PREFIX)
    if [ ! -z "$relevant_containers" ]; then
        for container in $relevant_containers; do
            echo Stopping $container
            $DOCKER stop -t 0 $container >/dev/null
        done
    fi

    echo Removing network $NETWORK_NAME
    $DOCKER network rm $NETWORK_NAME >/dev/null 2>&1
}


start_container() {
    container_name=$1
    shift
    $DOCKER run --rm -d --hostname "$container_name" --name "$container_name" --network $NETWORK_NAME "$IMAGE_NAME" $@
}

launch() {
    # Remove the network if it exists
    $DOCKER network rm $NETWORK_NAME >/dev/null 2>&1

    # Create a new docker network for our containers to reside on
    $DOCKER network create --driver bridge $NETWORK_NAME >/dev/null 2>&1

    # build command line
    MASTER_CONTAINER="${CONTAINER_PREFIX}master"

    CMDLINE="--master $MASTER_CONTAINER"

    for i in $(seq 1 $NUM_SLAVES); do
        CMDLINE="$CMDLINE --slave ${CONTAINER_PREFIX}slave-$i"
    done

    # Start docker containers
    for i in $(seq 1 $NUM_SLAVES); do
        local container_name="${CONTAINER_PREFIX}slave-${i}"
        echo Launching slave container $container_name
        start_container $container_name $CMDLINE > /dev/null 2>&1
    done

    echo Starting the master container in 3 seconds..
    sleep 3
    # Start master container
    echo Starting master container $MASTER_CONTAINER
    start_container $MASTER_CONTAINER $CMDLINE "--i-am-master --format-hdfs" >/dev/null

    while true; do
        sleep 10
    done
}

trap cleanup EXIT
launch
