import * as express from "express";
import * as bodyParser from 'body-parser';
import { Contract, Gateway, GatewayOptions } from 'fabric-network';
import * as path from 'path';
import { 
    buildCCPOrg1,
    buildWallet,
    prettyJSONString
} from './utils//AppUtil';
import { 
    buildCAClient,
    enrollAdmin,
    registerAndEnrollUser
} from './utils/CAUtil';

const channelName = 'mychannel';
const chaincodeName = 'basic';
const mspOrg1 = 'Org1MSP';
const walletPath = path.join(__dirname, 'wallet');
const org1UserId = 'appUser';

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(bodyParser.raw());
const PORT = 8000;

let contract: Contract, gateway: Gateway;

// functions
async function initialize() {
    try {
        const ccp = buildCCPOrg1();  // connection profile

        const caClient = buildCAClient(ccp, 'ca.org1.example.com');  // instance of fabric ca services client

        const wallet = await buildWallet(walletPath);  // wallet to hold app user creds

        // test app flow only
        await enrollAdmin(caClient, wallet, mspOrg1); 
        await registerAndEnrollUser(caClient, wallet, mspOrg1, org1UserId, 'org1.department1');

        gateway = new Gateway();

        const gatewayOpts: GatewayOptions = {
            wallet,
            identity: org1UserId,
            discovery: { enabled: true, asLocalhost: true },
        };

        // setup the gateway instance
        await gateway.connect(ccp, gatewayOpts);

        // network with channel holding the smart contract
        const network = await gateway.getNetwork(channelName);

        contract = network.getContract(chaincodeName);

        console.log('\n--> Submit Transaction: InitLedger, function creates the initial set of assets on the ledger');
        await contract.submitTransaction('InitLedger');
        console.log('*** Ledger Initialized');

    } catch (error) {
        console.error(`******** FAILED to run initialize(): ${error}`);
    }
}

async function finalize() {
    gateway.disconnect();
}

// routes

// basic route
app.get('/', (req,res) => {
  res.send("Hyperledger and Typescript test for Triple Point Liquidity");
});

// create an asset
// curl -X POST -H "Content-Type: application/json" -d '{"id": 10, "owner": "Tom", "color": "Cyan"}' http://localhost:8000/asset

app.post('/asset', async (req, res) => {
    const body = req.body;
    const assetId = `asset${body.id || "23"}`; 
    const color = `${body.color || "Cyan"}`;
    const owner = `${body.owner || "Jared"}`;
    const appraisedValue = "8675309";
    const size = "7";

    console.log('\n--> Submit Transaction: CreateAsset, creates new asset');
    await contract.submitTransaction('CreateAsset', assetId, color, size, owner, appraisedValue);
    res.send('Committed');
});

// get an asset. Defaults to 3
// http://localhost:8000/asset?id=1
app.get('/asset', async (req, res) => {
    const assetId = `asset${req.query.id || "3"}`;

    console.log(`\n--> Evaluate Transaction: ReadAsset, function returns an asset with assetID = ${assetId}`);
    const result = await contract.evaluateTransaction('ReadAsset', assetId);
    res.send(`${prettyJSONString(result.toString())}`);
});


// get all assets
// http://localhost:8000/assets
app.get('/assets', async (req,res) => {
    console.log('\n--> Evaluate Transaction: GetAllAssets, function returns all current assets on the ledger');
    let result = await contract.evaluateTransaction('GetAllAssets');
    res.send(`${prettyJSONString(result.toString())}`);
});

// entrypoint
const server = app.listen(PORT, async () => {
    await initialize();
    console.log(`Running at https://localhost:${PORT}`); 
});

process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: exiting Api')
    server.close(async () => {
        await finalize();
    })
})
