#!/bin/bash

RHOST=os-repo-rsync-origin.ewe.moe
OBS_API=https://os-build.ewe.moe

BASE_DIR=/data/eweos-repo/eweos
REPOS=(
        main
        testing
)
ARCHS=(
        x86_64
        aarch64
        riscv64
        loongarch64
)

: "${OBS_USER:?OBS_USER is not set}" "${OBS_PASS:?OBS_PASS is not set}"

if [ -f /tmp/eweos-sync ]; then
  exit 0
fi

touch /tmp/eweos-sync

for REPO_NAME in ${REPOS[@]}; do
        mkdir -p ${BASE_DIR}/${REPO_NAME}/os/${REPO_ARCH}

        for REPO_ARCH in ${ARCHS[@]}; do

                echo "Syncing repo ${REPO_NAME} ${REPO_ARCH}"

                if curl -fsS -u "$OBS_USER:$OBS_PASS" \
                        "$OBS_API/build/eweOS:${REPO_NAME^}/_result?repository=rolling&arch=$REPO_ARCH&view=summary" |
                        grep -q '<result [^>]*state="published"'; then

                        rsync -atrzlu --delete-after \
                                rsync://$RHOST/repo-$REPO_NAME/$REPO_ARCH/ \
                                        $BASE_DIR/$REPO_NAME/os/$REPO_ARCH/

                        for f in ${BASE_DIR}/${REPO_NAME}/os/$REPO_ARCH/eweOS_${REPO_NAME^}_rolling*; do
                                fn=$(echo $f | sed "s/eweOS_${REPO_NAME^}_rolling/${REPO_NAME}/g")
                                if [ ! -L "$fn" ]; then
                                        ln -s "$f" "$fn"
                                fi
                        done
                else
                        echo "${REPO_NAME} ${REPO_ARCH} not published, skipped."
                fi
        done
done

rm /tmp/eweos-sync
