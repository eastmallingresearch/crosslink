#Crosslink, Copyright (C) 2016  NIAB EMR

#
# screen capture every 60s to record what joinmap is doing
#

set -eu

while true
do
    timestamp=$(date -u +%Y%m%d%H%M%S)
    import -window root ${timestamp}.jpg
    
    sleep 60
done
