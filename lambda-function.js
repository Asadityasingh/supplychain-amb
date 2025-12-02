const { Gateway, Wallets } = require('fabric-network');

const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT'
};

class FabricService {
    async connectToNetwork() {
        const gateway = new Gateway();
        
        const connectionProfile = {
            name: 'supplychain-network',
            version: '1.0.0',
            client: {
                organization: 'member1',
                connection: {
                    timeout: { peer: { endorser: '300' }, orderer: '300' }
                }
            },
            organizations: {
                member1: {
                    mspid: process.env.MSP_ID || 'Org1MSP',
                    peers: [process.env.PEER_ENDPOINT]
                }
            },
            peers: {
                [process.env.PEER_ENDPOINT]: {
                    url: `grpcs://${process.env.PEER_ENDPOINT}`,
                    tlsCACerts: { pem: process.env.TLS_CERT }
                }
            }
        };

        const wallet = await Wallets.newInMemoryWallet();
        const identity = {
            credentials: {
                certificate: process.env.USER_CERT,
                privateKey: process.env.USER_PRIVATE_KEY
            },
            mspId: process.env.MSP_ID || 'Org1MSP',
            type: 'X.509'
        };
        
        await wallet.put('appUser', identity);

        await gateway.connect(connectionProfile, {
            identity: 'appUser',
            wallet: wallet,
            discovery: { enabled: true, asLocalhost: false }
        });
        
        const network = await gateway.getNetwork(process.env.CHANNEL_NAME || 'mychannel');
        const contract = network.getContract(process.env.CHAINCODE_NAME || 'supplychain');
        
        return { gateway, contract };
    }
}

const fabricService = new FabricService();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const { httpMethod, path, pathParameters, body } = event;
        const parsedBody = body ? JSON.parse(body) : {};

        if (httpMethod === 'OPTIONS') {
            return { statusCode: 200, headers, body: JSON.stringify({ message: 'CORS' }) };
        }

        // Health check
        if (httpMethod === 'GET' && path === '/health') {
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ status: 'running', timestamp: new Date().toISOString() })
            };
        }

        // Create Asset
        if (httpMethod === 'POST' && path === '/assets') {
            const { assetId, name, location, owner } = parsedBody;
            
            if (!assetId || !name || !location || !owner) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({ error: 'Missing required fields: assetId, name, location, owner' })
                };
            }

            const { gateway, contract } = await fabricService.connectToNetwork();
            const result = await contract.submitTransaction('CreateAsset', assetId, name, location, owner);
            await gateway.disconnect();
            
            return {
                statusCode: 201,
                headers,
                body: JSON.stringify({ success: true, data: JSON.parse(result.toString()) })
            };
        }

        // Get Asset by ID
        if (httpMethod === 'GET' && pathParameters?.id) {
            const { gateway, contract } = await fabricService.connectToNetwork();
            const result = await contract.evaluateTransaction('QueryAsset', pathParameters.id);
            await gateway.disconnect();
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ success: true, data: JSON.parse(result.toString()) })
            };
        }

        // Transfer Asset
        if (httpMethod === 'PUT' && pathParameters?.id && path.includes('/transfer')) {
            const { newOwner, newLocation } = parsedBody;
            
            if (!newOwner || !newLocation) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({ error: 'Missing required fields: newOwner, newLocation' })
                };
            }

            const { gateway, contract } = await fabricService.connectToNetwork();
            const result = await contract.submitTransaction('TransferAsset', pathParameters.id, newOwner, newLocation);
            await gateway.disconnect();
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ success: true, data: JSON.parse(result.toString()) })
            };
        }

        // Get All Assets
        if (httpMethod === 'GET' && path === '/assets') {
            const { gateway, contract } = await fabricService.connectToNetwork();
            const result = await contract.evaluateTransaction('GetAllAssets');
            await gateway.disconnect();
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ success: true, data: JSON.parse(result.toString()) })
            };
        }

        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Route not found' })
        };

    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: error.message })
        };
    }
};