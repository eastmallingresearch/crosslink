# build from the same directory as this Dockerfile using:
# docker build -t rjvickerstaff/crosslink:0.1 . 

#to launch into text only commandline use:
#  docker run -it -u crosslink rjvickerstaff/crosslink:0.1

#launch with X11 mounting for graphical output (on a linux host)
#http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/
#http://wiki.ros.org/docker/Tutorials/GUI
#  docker run -it --name=crosslink -u crosslink -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY rjvickerstaff/crosslink:0.1
#then allow access to X11 by entering something like this into the host:
# xhost +local:$(docker ps --filter=name=crosslink -q)

#ubuntu LTS version
FROM ubuntu:16.04
MAINTAINER robert.vickerstaff@emr.ac.uk

#no front end
ENV DEBIAN_FRONTEND noninteractive
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

#update existing packages
RUN apt-get update
RUN apt-get upgrade -y

#install new packages
RUN apt-get install -y gcc libsdl2-2.0-0 libsdl2-dev nano bashdb
RUN apt-get install -y dbus

#set root password
RUN echo 'root:cl_root_uDk5eI' | chpasswd

#add user
RUN useradd -ms /bin/bash crosslink
RUN echo 'crosslink:cl_user_uDk5eI' | chpasswd

WORKDIR /home/crosslink

#add crosslink source
COPY crosslink crosslink

#change ownership from root to crosslink user
RUN chown -R crosslink ./crosslink
RUN chgrp -R crosslink ./crosslink

#fix for: D-Bus library appears to be incorrectly set up; failed to read machine uuid: Failed to open "/etc/machine-id": No such file or directory
RUN dbus-uuidgen > /var/lib/dbus/machine-id

#run as crosslink user
USER crosslink

#build crosslink inside the container
RUN cd crosslink/src && ./make.sh && ./viewer_make.sh

#add crosslink executables to path
ENV PATH ${PATH}:/home/crosslink/crosslink/scripts:/home/crosslink/crosslink/bin:/home/crosslink/crosslink/test_scripts
