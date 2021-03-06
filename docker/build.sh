#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# build the docker image
#

MYDOCKERUSER=rjvickerstaff
RELEASE=0.4

set -eu

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

cd ${MYTMPDIR}

mkdir -p context

###use this to get a crosslink release
#wget https://github.com/eastmallingresearch/crosslink/archive/v${RELEASE}.tar.gz
#tar -xzf crosslink-${RELEASE}.tar.gz
#mv ./crosslink-${RELEASE} ./context/crosslink

###use this to get the very latest code from the repository
git clone https://github.com/eastmallingresearch/crosslink
mv ./crosslink ./context/crosslink

cp ./context/crosslink/docker/Dockerfile context

sudo docker build -t ${MYDOCKERUSER}/crosslink:${RELEASE} context\
    && sudo docker tag ${MYDOCKERUSER}/crosslink:${RELEASE} rjvickerstaff/crosslink:latest\
    && sudo docker login\
    && sudo docker push rjvickerstaff/crosslink:latest\
    && sudo docker push rjvickerstaff/crosslink:${RELEASE}

rm -rf ${MYTMPDIR}
