#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# build the docker image
#

BUILD_DIR=/home/vicker/rjv_files/docker/docker_crosslink_build

set -eu

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR} || exit
mkdir -p context

#get up to date copy of crosslink
git clone https://github.com/eastmallingresearch/crosslink
mv ./crosslink ./context
rm -rf ./context/crosslink/.git
cp ./context/crosslink/docker/Dockerfile context
cp ~/rjv_mnt/cluster/git_repos/crosslink/docker/Dockerfile context

docker build -t rjvickerstaff/crosslink:0.1 context
