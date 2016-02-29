#!/bin/bash

#
# build the docker image
#

BUILD_DIR=/home/vicker/rjv_files/docker/docker_crosslink_build

set -eu

rm -rf ${BUILD_DIR}

mkdir -p ${BUILD_DIR}

cd ${BUILD_DIR} || exit

#get up to date copies of crosslink and rjvbio
git clone https://github.com/robertvi/rjvbio
git clone https://github.com/eastmallingresearch/crosslink

mkdir -p context

mv ./crosslink ./context
mv ./rjvbio ./context
rm -rf ./context/crosslink/.git
rm -rf ./context/rjvbio/.git

cp ./context/crosslink/docker/Dockerfile context

docker build -t rjvickerstaff/crosslink:0.1 context
