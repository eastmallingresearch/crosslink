#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# build the docker image
#

MYDOCKERUSER=rjvickerstaff
RELEASE=0.2

set -eu

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

cd ${MYTMPDIR}

mkdir -p context

cp -r ~/rjv_mnt/cluster/git_repos/crosslink ./context/crosslink

cp ./context/crosslink/docker/Dockerfile context

sudo docker build -t ${MYDOCKERUSER}/crosslink:${RELEASE} context

rm -rf ${MYTMPDIR}
