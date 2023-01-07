#!/bin/bash

BASE_DIR=/mirror/data/eweos

LANG=C
DATA="[]"
DATA_ITEM="{}"
STATE=0

while read -r;
do
        if [ -z "$REPLY" ]; then
                STATE=0
                DATA=`echo $DATA | jq ". + [ $DATA_ITEM ]"`
                DATA_ITEM="{}"
        else
                if [[ "$STATE" == 0 ]]; then
                        STATE=1
                fi
                K=$(echo $REPLY | cut -d ':' -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                V=$(echo $REPLY | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\"/\'/g")
                if [[ "$K" == "Name" ]]; then
                        echo $V
                fi
                DATA_ITEM=`echo $DATA_ITEM | jq ". + {\"$K\":\"$V\"}"`
        fi
done <<<$(pacman -Syi --config $BASE_DIR/pacman.conf -b /tmp)
DATA=`echo $DATA | jq ". + [ $DATA_ITEM ]"`

echo $DATA | jq > $BASE_DIR/pkgs.json
