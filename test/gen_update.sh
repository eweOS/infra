#!/bin/bash

cat <<EOF > /tmp/upd-info.html
<!DOCTYPE html>
<html>
<head>
<title>eweOS Test Server | Software Update</title>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="generator" content="http://chalarangelo.github.io/htmltemplategenerator/">
</head>
<body>
<h1>eweOS Software Update</h1>
<hr />
<pre>
`archversion check -n 2>&1`
</pre>
</body>
</html>
EOF

cp /tmp/upd-info.html /var/ewe/update.html
