#!/bin/env bash

EXTCMD=${REQUEST_URI#*\?}
REQUEST_URI=${REQUEST_URI%\?*}
PKGNAME=${REQUEST_URI#/package/}

case $EXTCMD in
  "dep")
    EXTCMD="grep '^Depends On' | cut -f 2 -d ':'"
    ;;
  "rdep")
    EXTCMD="grep '^Required By' | cut -f 2 -d ':'"
    ;;
  "ver")
    EXTCMD="grep '^Version' | cut -f 2 -d ':'"
    ;;
  *)
    EXTCMD="cat"
    ;;
esac


if [ -z "${PKGNAME}" ]; then
cat << EOF
Content-type: text/plain

Usage: /package/<PackageName>
EOF
exit
fi

if [[ $HTTP_USER_AGENT == *"curl"* ]]; then

cat << EOF
Content-type: text/plain

`pacman -Sii $PKGNAME 2>&1 | $EXTCMD`
EOF

else

cat << EOF
Content-type: text/html

<html>
<head><title>Query for $PKGNAME</title></head>
<body>
<pre>`pacman -Sii $PKGNAME 2>&1 | $EXTCMD`</pre>
</body>
</html>
EOF

fi
