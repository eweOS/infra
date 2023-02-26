#!/bin/bash

RHOST=obs_server

BASE_DIR=/mirror/data/eweos
REPOS=(
        Main
        Testing
)
ARCHS=(
        x86_64
        aarch64
)

for REPO_NAMEX in ${REPOS[@]}; do
        REPO_NAME=${REPO_NAMEX,,}
        mkdir -p ${BASE_DIR}/${REPO_NAME}/os/${REPO_ARCH}

        for REPO_ARCH in ${ARCHS[@]}; do

                echo "Syncing repo ${REPO_NAME} ${REPO_ARCH}"

                if rsync --list-only \
                        rsync://$RHOST/Repo/$REPO_NAMEX/Rolling/$REPO_ARCH/ \
                                | grep ".db$" \
                                | grep -q "^-"; then

                        rsync -atrzlu --delete-after \
                                rsync://$RHOST/Repo/$REPO_NAMEX/Rolling/$REPO_ARCH/ \
                                        $BASE_DIR/$REPO_NAME/os/$REPO_ARCH/

                        for f in ${BASE_DIR}/${REPO_NAME}/os/$REPO_ARCH/eweOS_${REPO_NAMEX}_Rolling*; do
                                fn=$(echo $f | sed "s/eweOS_${REPO_NAMEX}_Rolling/${REPO_NAME}/g")
                                mv "$f" "$fn"
                        done
                else
                        echo "${REPO_NAME} ${REPO_ARCH} db file error, skipped."
                fi
        done
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

echo "Syncing images for x86_64 ..."
rsync -atrzlu --delete-after \
        rsync://$RHOST/Image/Arch/x86_64/:repo/ \
        $BASE_DIR-images/x86_64

echo "Syncing images for aarch64 ..."
rsync -atrzlu --delete-after \
        rsync://$RHOST/Image/ArchArm/aarch64/:repo/ \
        $BASE_DIR-images/aarch64
