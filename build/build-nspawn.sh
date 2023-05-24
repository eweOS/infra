#!/bin/bash

CONFIG_TOKEN=
CONFIG_RSYNC_TOKEN=

if [ -z $1 ]; then
	PKGNAME=filesystem
else
	PKGNAME=$1
fi
PKGREPO=eweOS/packages

BUILDDATE=$(date +%F_%H-%M-%S)

cp scripts/* build/rootfs/usr/bin && chmod +x build/rootfs/usr/bin/eweos-build-*

systemd-nspawn -D ./build/rootfs \
	/usr/bin/eweos-build-init

systemd-nspawn -D ./build/rootfs -x \
	--tmpfs=/build \
	-E PKG_NAME=$PKGNAME \
	-E PKG_REPO=$PKGREPO \
	-E SUBMIT_TOKEN=$CONFIG_TOKEN \
	-E RSYNC_TOKEN=$CONFIG_RSYNC_TOKEN \
	/usr/bin/eweos-build-pkg


