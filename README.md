# Bluepoint

A blueprint for code experiments on the Triple Point platform.

## High Level

There is not much here in the way of app code.  Most of this code pertains to [the HLF bootstrap/docs stuff](https://wiki.hyperledger.org/display/fabric), put in a repo.  Use this as the ‘base’ for a sample.

You will find that, though this contains a typescript app + environment, none of the code leverages typescript.  

Please expand upon the typescript application patterns and framework idioms.  Somes reminders and tips: 

* The HLF smart contract endpoints can act like CRUD endpoints, but could also act RPC-style
* Leveraging and ORM or building ORM-like patterns will need to work with this constraint.
* The HLF peer can respond very slowly at times (2-5 seconds when congested), while the API service may get faster requests
* Expect that this API service could grow to a meso-scale or monolith codebase, or a suite of microservices that require consistent semantics and structure across all.

#### TS server here

```
cd asset-transfer-basic/application-typescript/
```

## Setup
### Set up the hyperledger network

*Apologies that the repo is 200 MB, today, due to binaries.*

```sh

git clone git@github.com:opxtechventures/bluepoint.git
cd bluepoint

./setup-network.sh

```

### Tear down the hyperledger network

```sh
cd bluepoint  # if needed

./teardown-network.sh

```

### Set up the API

```sh
cd bluepoint  # if needed

./setup-api.sh

```

### Try the API

```sh

cd bluepoint

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
