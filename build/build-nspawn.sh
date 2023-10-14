#!/bin/bash

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
	/usr/bin/eweos-build-pkg


