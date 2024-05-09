#!/bin/env bash

PKGNAME=${REQUEST_URI#/package/}

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

`pacman -Sii $PKGNAME 2>&1`
EOF

else

cat << EOF
Content-type: text/html

<html>
<head><title>Query for $PKGNAME</title></head>
<body>
<pre>`pacman -Si $PKGNAME 2>&1`</pre>
</body>
</html>
EOF

fi
