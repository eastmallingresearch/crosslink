#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
# can be built using the ${CROSSLINK_PATH}/docker/build.sh script

#to launch into text only command line use:
#  docker run -it -u crosslink_user rjvickerstaff/crosslink:${RELEASE}

#launch with X11 mounting for graphical output (on a linux host)
#  docker run -it --name=crosslink -u crosslink_user -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY rjvickerstaff/crosslink:${RELEASE}

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
RUN apt-get install -y apt-utils
RUN apt-get install -y less sudo
RUN apt-get install -y gcc libsdl2-2.0-0 libsdl2-dev nano bashdb
RUN apt-get install -y dbus python-numpy python-scipy python-matplotlib
RUN apt-get install -y libsdl2-image-2.0.0 libsdl2-image-dev

#set root password
#RUN echo 'root:crosslink_root' | chpasswd

#add user
RUN useradd -ms /bin/bash crosslink_user
RUN adduser crosslink_user sudo
RUN echo 'crosslink_user:crosslink' | chpasswd

WORKDIR /home/crosslink_user

#add crosslink source
COPY crosslink crosslink

#change ownership from root to crosslink user
RUN chown -R crosslink_user ./crosslink
RUN chgrp -R crosslink_user ./crosslink

#fix for: D-Bus library appears to be incorrectly set up; failed to read machine uuid: Failed to open "/etc/machine-id": No such file or directory
RUN dbus-uuidgen > /var/lib/dbus/machine-id

#run as crosslink user
USER crosslink_user

#build crosslink inside the container
RUN cd crosslink/src && ./make.sh && ./viewer_make.sh

#add crosslink executables to path
ENV PATH /home/crosslink_user/crosslink/scripts:/home/crosslink_user/crosslink/bin:${PATH}
