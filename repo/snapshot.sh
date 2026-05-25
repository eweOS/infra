#!/bin/bash

SYNC_OBJ=${1:-eweos}

SRC="/data/eweos-repo/$SYNC_OBJ/"
DEST_BASE="/data/eweos-repo-snapshot/$SYNC_OBJ"

mkdir -p "$DEST_BASE"

TODAY_YYYY=$(date +%Y)
TODAY_MM=$(date +%m)
TODAY_DD=$(date +%d)
TODAY_DIR="$DEST_BASE/$TODAY_YYYY/$TODAY_MM/$TODAY_DD"

### do rsync snapshot

LATEST_SNAPSHOT=$(find "$DEST_BASE" -mindepth 3 -maxdepth 3 -type d | sort -r | grep -v "^${TODAY_DIR}$" | head -n 1)

LINK_OPTS=""
if [ -n "$LATEST_SNAPSHOT" ]; then
    LINK_OPTS="--link-dest=$LATEST_SNAPSHOT"
fi

mkdir -p "$TODAY_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start: $TODAY_DIR"
if [ -n "$LATEST_SNAPSHOT" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Reference: $LATEST_SNAPSHOT"
fi

rsync -a --delete $LINK_OPTS "$SRC" "$TODAY_DIR/"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished."

### do purging

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Purging..."

TODAY_STR=$(date +%Y-%m-%d)
CUTOFF_60_DAYS=$(date -d "$TODAY_STR - 60 days" +%s)
CUTOFF_12_MONTHS=$(date -d "$TODAY_STR - 12 months" +%s)
CUTOFF_3_YEARS=$(date -d "$TODAY_STR - 3 years" +%s)

for DIR in $(find "$DEST_BASE" -mindepth 3 -maxdepth 3 -type d | sort); do
    REL_PATH="${DIR#$DEST_BASE/}"
    YYYY=$(echo "$REL_PATH" | cut -d/ -f1)
    MM=$(echo "$REL_PATH" | cut -d/ -f2)
    DD=$(echo "$REL_PATH" | cut -d/ -f3)

    DIR_TS=$(date -d "$YYYY-$MM-$DD" +%s 2>/dev/null)
    if [ -z "$DIR_TS" ]; then
        continue # ignore non-standard dir
    fi

    KEEP=0

    # keep 60d
    if [ "$DIR_TS" -ge "$CUTOFF_60_DAYS" ]; then
        KEEP=1
    # keep 12m d=1
    elif [ "$DD" == "01" ] && [ "$DIR_TS" -ge "$CUTOFF_12_MONTHS" ]; then
        KEEP=1
    # keep 3y m=1 d=1
    elif [ "$MM" == "01" ] && [ "$DD" == "01" ] && [ "$DIR_TS" -ge "$CUTOFF_3_YEARS" ]; then
        KEEP=1
    fi

    if [ "$KEEP" -eq 0 ]; then
        echo "--> Remove: $DIR"
        rm -rf "$DIR"
    fi
done

### do cleanup

find "$DEST_BASE" -mindepth 1 -maxdepth 2 -type d -empty -delete

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished"
echo "---------------------------------------------------------"
