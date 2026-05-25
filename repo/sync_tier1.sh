#!/bin/bash

RHOST=os-repo-rsync.ewe.moe
REPOPATH=/srv/eweos/eweos-repo

if [ -f /tmp/eweos-sync ]; then
  exit 0
fi

touch /tmp/eweos-sync

for repo in eweos eweos-images; do

  rsync -atrzlu --delete-after \
    rsync://$RHOST/$repo/ $REPOPATH/$repo/

done

rm /tmp/eweos-sync
