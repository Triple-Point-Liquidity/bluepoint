# Bluepoint

A blueprint for code experiments on the Triple Point platform.

## Set up the hyperledger network
```sh

git clone git@github.com:opxtechventures/tpltest.git
cd tpltest

./setup-network.sh

```

## Tear down the hyperledger network
```sh
cd tpltest  # if needed

./teardown-network.sh

```

## Set up the API
```sh
cd tpltest  # if needed

./setup-api.sh

```

## Try the API

```sh

cd tpltest  # if needednt

cd asset-transfer-basic/application-typescript
npm run start

# Get all assets from the ledger
curl -X GET 'http://localhost:8000/assets'

# Add an asset to the ledger
curl -X POST -H "Content-Type: application/json" \
  -d '{"id": 10, "owner": "Tom", "color": "Cyan"}' \
  http://localhost:8000/asset

# Get a specific asset from the ledger
curl -X GET 'http://localhost:8000/asset?id=1'
curl -X GET 'http://localhost:8000/asset?id=10'

```
