#!/usr/bin/env bash

cd asset-transfer-basic/application-typescript
# remove any leftovers
rm -rf node_modules dist
# check node version
node -v
# install dependencies
npm install
