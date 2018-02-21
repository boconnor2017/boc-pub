#!/bin/sh
#
#     Version: 1.0
#     Author: Brendan O'Connor (VMWare Professional Services)
#     Date: February 2018
#
#     Disclaimer: this solution is not a validated or copywrite solution from VMWare.
#                 This solution is an open source tool for vRealize Administrators to
#                 utilize at their discression. You may copy, edit, and redistribute
#                 this solution as you like.
#
#     Purpose of this script: automate installation of NodeJS on PhotonOS
#
#    Procedure:
#      1. Create local directory (for example: mkdir /usr/local/nodejs)
#      2. Download nodejs tar file (manually or through wget https://nodejs.org/dist/v8.9.4/node-v8.9.4.tar.gz) to directory
#      3. Copy this script to the directory
#      4. Run script: sh installNodeJS.sh 
#      5. Open a browser, navigate to <photon_ip_address>:3000

CURDIR=$(pwd)

echo "Downloading nodejs from nodejs.org"
wget https://nodejs.org/dist/v8.9.4/node-v8.9.4.tar.gz
NODEJSTARFILE=node-v8.9.4.tar.gz
NODEJSTARFOLD=node-v8.9.4

echo "Current Directory: " $CURDIR
echo "NodeJS Tar File: " $NODEJSTARFILE


tar -xf $NODEJSTARFILE
cd $NODEJSTARFOLD
mkdir html
cd html

echo "// content of index.js" >> index.js
echo "const http = require('http')" >> index.js
echo "const port = 3000" >> index.js
echo " " >> index.js
echo "const requestHandler = (request, response) => {" >> index.js
echo "  console.log(request.url)" >> index.js
echo "  response.end('Hello Node.js Server!')" >> index.js
echo " }" >> index.js
echo " " >> index.js
echo " const server = http.createServer(requestHandler)" >> index.js
echo " " >> index.js
echo " server.listen(port, (err) => {" >> index.js
echo "  if (err) {" >> index.js
echo "    return console.log('something bad happened', err)" >> index.js
echo "  }" >> index.js
echo " " >> index.js
echo "  console.log(\`server is listening on \${port}\`)" >> index.js
echo " })" >> index.js

NODEPATH=$CURDIR/$NODEJSTARFOLD/bin/
export PATH=$NODEPATH:$PATH

node $CURDIR/$NODEJSTARFOLD/html/index.js
