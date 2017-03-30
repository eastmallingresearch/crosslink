#!/bin/bash

#
# delete all existing mstmap runs
#

set -eu

for x in [0-9][0-9]*
do
    COUNT='0'
    cd ${x}
    if [ -e score ]; then
        COUNT=$(cat score | grep mstmap | wc --lines)
    fi
    cd ..
    
    if [ "${COUNT}" == "1" ] ; then
        #echo delete ${x}
        cat ${x}/score
        ##rm -rf ${x}
    fi
done
