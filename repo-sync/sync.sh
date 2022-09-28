#!/bin/bash

SYNC_HOST=192.168.1.150

BASE_DIR=/mirror/data/eweos
REPOS=(
        Main
        Testing
)

for REPO_NAMEX in ${REPOS[@]}; do
        REPO_NAME=${REPO_NAMEX,,}
                
        echo "Syncing repo ${REPO_NAME} ..."

        mkdir -p ${BASE_DIR}/${REPO_NAME}/os/${REPO_ARCH}

        if rsync --list-only \
                rsync://$SYNC_HOST/Repo/$REPO_NAMEX/Rolling/x86_64/ \
                | grep ".db$" \
                | grep -q "^-"; then

        rsync -atrzlu --delete-after \
                rsync://$SYNC_HOST/Repo/$REPO_NAMEX/Rolling/ \
                $BASE_DIR/$REPO_NAME/os/

        for f in ${BASE_DIR}/${REPO_NAME}/os/*/eweOS_${REPO_NAMEX}_Rolling*; do
                fn=$(echo $f | sed "s/eweOS_${REPO_NAMEX}_Rolling/${REPO_NAME}/g")
                mv "$f" "$fn"
        done

        else
                echo "${REPO_NAME} db file error, skipped."
        fi
done

cat <<EOF >$BASE_DIR/pacman.conf
[options]
HoldPkg     = pacman musl busybox
Architecture = auto
Color
CheckSpace
ParallelDownloads = 8

EOF

for REPO_NAMEX in ${REPOS[@]}; do
REPO_NAME=${REPO_NAMEX,,}
cat <<EOF >>$BASE_DIR/pacman.conf
[$REPO_NAME]
SigLevel = Never
Server = http://os-repo.ewe.moe/eweos/$REPO_NAME/os/\$arch/

EOF
done

echo "Syncing images ..."
rsync -atrzlu --delete-after \
        rsync://$SYNC_HOST/Repo/Image/Arch/ \
        $BASE_DIR-images/
