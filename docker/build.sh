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

#wget https://github.com/eastmallingresearch/crosslink/archive/v${RELEASE}.tar.gz
#tar -xzf crosslink-${RELEASE}.tar.gz
#mv ./crosslink-${RELEASE} ./context/crosslink

#git clone https://github.com/eastmallingresearch/crosslink
mv ./crosslink ./context/crosslink

cp ./context/crosslink/docker/Dockerfile context

cp ~/rjv_mnt/cluster/git_repos/crosslink/docker/Dockerfile context

sudo docker build -t ${MYDOCKERUSER}/crosslink:${RELEASE} context

rm -rf ${MYTMPDIR}
