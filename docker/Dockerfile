# build from the same directory as this Dockerfile using:
# docker build -t rjvickerstaff/crosslink:0.1 . 
#to launch use: docker run -it -u crosslink rjvickerstaff/crosslink:0.1

#the most recent (as of 2016-02-26) ubuntu LTS version
FROM ubuntu:14.04
MAINTAINER robert.vickerstaff@emr.ac.uk

#no front end
ENV DEBIAN_FRONTEND noninteractive
#alternatively: RUN DEBIAN_FRONTEND=noninteractive apt-get update
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

#update existing packages
RUN apt-get update
RUN apt-get upgrade -y

#install new packages
RUN apt-get install -y gcc libsdl2-2.0-0 libsdl2-dev
RUN apt-get install -y nano

#set root password
RUN echo 'root:cl_root_uDk5eI' | chpasswd

#add user
RUN useradd -ms /bin/bash crosslink
RUN echo 'crosslink:cl_user_uDk5eI' | chpasswd

WORKDIR /home/crosslink

#add crosslink source
COPY crosslink crosslink
COPY rjvbio rjvbio

#change ownership from root to crosslink user
RUN chown -R crosslink ./crosslink
RUN chown -R crosslink ./rjvbio
RUN chgrp -R crosslink ./crosslink
RUN chgrp -R crosslink ./rjvbio

#run as crosslink user
USER crosslink

#build crosslink inside the container
RUN cd crosslink/scripts && ./make.sh && ./viewer_make.sh

#add crosslink executables to path
ENV PATH ${PATH}:/home/crosslink/crosslink/scripts
