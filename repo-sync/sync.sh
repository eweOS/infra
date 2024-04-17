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
        riscv64
)

for REPO_NAME in ${REPOS[@]}; do
        mkdir -p ${BASE_DIR}/${REPO_NAME}/os/${REPO_ARCH}

        for REPO_ARCH in ${ARCHS[@]}; do

                echo "Syncing repo ${REPO_NAME} ${REPO_ARCH}"

                if rsync --list-only \
                        rsync://$RHOST/repo-$REPO_NAME/$REPO_ARCH/ \
                                | grep ".db.tar.gz$" \
                                | grep -q "^-"; then

                        rsync -atrzlu --delete-after \
                                rsync://$RHOST/repo-$REPO_NAME/$REPO_ARCH/ \
                                        $BASE_DIR/$REPO_NAME/os/$REPO_ARCH/

                        for f in ${BASE_DIR}/${REPO_NAME}/os/$REPO_ARCH/eweOS_${REPO_NAME^}_rolling*; do
                                fn=$(echo $f | sed "s/eweOS_${REPO_NAME^}_rolling/${REPO_NAME}/g")
                                mv "$f" "$fn"
                        done
                else
                        echo "${REPO_NAME} ${REPO_ARCH} db file error, skipped."
                fi
        done
done
