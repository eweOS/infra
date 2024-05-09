#!/bin/env bash

EXTCMD=${REQUEST_URI#*\?}
REQUEST_URI=${REQUEST_URI%\?*}
PKGNAME=${REQUEST_URI#/package/}

case $EXTCMD in
  "dep")
    GREPSTR='^Depends On'
    ;;
  "rdep")
    GREPSTR='^Required By'
    ;;
  "ver")
    GREPSTR='^Version'
    ;;
  *)
    unset $PKGNAME
    ;;
esac

if [ -z "${PKGNAME}" ]; then
cat << EOF
Content-type: text/plain

Usage: /package/<PackageName>[?{dep,rdep,ver}]
EOF
exit
fi

if [ ! -z $GREPSTR ]; then
  OUTPUT=`pacman -Sii $PKGNAME 2>&1 | grep "$GREPSTR" | cut -f 2 -d ':'`
fi

if [[ $HTTP_USER_AGENT == *"curl"* ]]; then

cat << EOF
Content-type: text/plain

`( test $OUTPUT && echo $OUTPUT) || (pacman -Sii $PKGNAME 2>&1 )`
EOF

else

cat << EOF
Content-type: text/html

<html>
<head><title>Query for $PKGNAME</title></head>
<body>
<pre>
`( test $OUTPUT && echo $OUTPUT) || (pacman -Sii $PKGNAME 2>&1 )`
</pre>
</body>
</html>
EOF

fi
