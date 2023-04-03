#!/bin/bash

pacman -Sy

cat <<EOF > /tmp/www-info.html
<!DOCTYPE html>
<html>
<head>
<title>eweOS Test Server</title>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="generator" content="http://chalarangelo.github.io/htmltemplategenerator/">
</head>
<body>
<h1>eweOS Test Server</h1>
<hr />
<p>This server is powered by eweOS rolling.</p>
<p>If you need user account in this test platform, please ask in Matrix or Telegram.</p>

<pre>
EOF

neofetch --stdout >> /tmp/www-info.html

cat <<EOF >> /tmp/www-info.html
`free -h`

`df -hT`

Total packages in repo: `pacman -Sl | wc -l`
-------------
Updated: `date`
</pre>
</body>
</html>
EOF

cp /tmp/www-info.html /var/ewe/index.html

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
`archversion report -n`
</pre>
</body>
</html>
EOF

cp /tmp/upd-info.html /var/ewe/update.html
