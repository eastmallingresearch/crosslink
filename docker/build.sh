#!/bin/bash

#
# build the docker image
# run from with in the docker context directory

#get a fresh copy of crosslink files


docker build -t rjvickerstaff/crosslink:0.1 .
