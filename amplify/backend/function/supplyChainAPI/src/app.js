let fabricNetworkModule, AWS;
try {
    fabricNetworkModule = require('fabric-network');
} catch (e) {
    console.log('fabric-network not available, using mock mode only');
}

try {
    AWS = require('aws-sdk');
} catch (e) {
    console.log('AWS SDK not available');
}

const { Gateway, Wallets } = fabricNetworkModule || {};
const secretsManager = AWS ? new AWS.SecretsManager({ region: process.env.REGION || 'us-east-1' }) : null;

let cachedCredentials = null;

const BLOCKCHAIN_CONFIG = {
    PEER_ENDPOINT: process.env.PEER_ENDPOINT || 'nd-zqx2ijvxhbcwzotry5kxm2kdva.m-ktgjmti7hfgtzku7ecmps4fquu.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30003',
    ORDERER_ENDPOINT: process.env.ORDERER_ENDPOINT || 'orderer.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30001',
    CA_ENDPOINT: process.env.CA_ENDPOINT || 'ca.m-ktgjmti7hfgtzku7ecmps4fquu.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30002',
    MSP_ID: process.env.MSP_ID || 'm-KTGJMTI7HFGTZKU7ECMPS4FQUU',
    CHANNEL_NAME: process.env.CHANNEL_NAME || 'mychannel',
    CHAINCODE_NAME: process.env.CHAINCODE_NAME || 'supplychain',
    MEMBER_ID: process.env.MEMBER_ID || 'm-KTGJMTI7HFGTZKU7ECMPS4FQUU',
    NETWORK_ID: process.env.NETWORK_ID || 'n-CFCACD47IZA7DALLDSYZ32FUZY'
};

const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE',
    'Content-Type': 'application/json'
};

let mockAssets = [];

class FabricService {
    async getCredentials() {
        if (cachedCredentials) {
            return cachedCredentials;
        }
        
        let creds = null;
        
        // Try Secrets Manager first
        if (secretsManager) {
            try {
                const secret = await secretsManager.getSecretValue({ SecretId: 'blockchain/fabric-admin-credentials' }).promise();
                creds = JSON.parse(secret.SecretString);
                console.log('✅ Loaded credentials from Secrets Manager');
            } catch (e) {
                console.log('Secrets Manager not available, checking environment variables');
            }
        }
        
        // Fall back to environment variables
        if (!creds) {
            creds = {
                userCert: process.env.USER_CERT,
                userPrivateKey: process.env.USER_PRIVATE_KEY,
                tlsCert: process.env.TLS_CERT,
                caTlsCert: process.env.CA_TLS_CERT
            };
        }
        
        cachedCredentials = creds;
        return creds;
    }

    async buildConnectionProfile() {
        const peerName = 'peer0.org1.example.com';
        const ordererName = 'orderer.example.com';
        const caName = 'ca.org1.example.com';
        const creds = await this.getCredentials();
        
        return {
            name: 'supplychain-network',
            version: '1.0.0',
            client: {
                organization: 'Org1',
                connection: {
                    timeout: {
                        peer: { endorser: '300s', eventHub: '300s' },
                        orderer: '300s'
                    }
                }
            },
            organizations: {
                Org1: {
                    mspid: BLOCKCHAIN_CONFIG.MEMBER_ID,
                    peers: [peerName],
                    certificateAuthorities: [caName]
                }
            },
            peers: {
                [peerName]: {
                    url: `grpcs://${BLOCKCHAIN_CONFIG.PEER_ENDPOINT}`,
                    tlsCACerts: { 
                        pem: creds.tlsCert || '' 
                    },
                    grpcOptions: {
                        'grpc.keepalive_time_ms': 600000,
                        'grpc.keepalive_timeout_ms': 30000
                    }
                }
            },
            orderers: {
                [ordererName]: {
                    url: `grpcs://${BLOCKCHAIN_CONFIG.ORDERER_ENDPOINT}`,
                    tlsCACerts: { 
                        pem: creds.tlsCert || '' 
                    },
                    grpcOptions: {
                        'grpc.keepalive_time_ms': 600000,
                        'grpc.keepalive_timeout_ms': 30000
                    }
                }
            },
            certificateAuthorities: {
                [caName]: {
                    url: `https://${BLOCKCHAIN_CONFIG.CA_ENDPOINT}`,
                    caName: 'ca-org1',
                    tlsCACerts: {
                        pem: process.env.CA_TLS_CERT || ''
                    },
                    httpOptions: {
                        verify: false
                    }
                }
            },
            channels: {
                [BLOCKCHAIN_CONFIG.CHANNEL_NAME]: {
                    orderers: [ordererName],
                    peers: {
                        [peerName]: {
                            endorsingPeer: true,
                            chaincodeQuery: true,
                            ledgerQuery: true,
                            eventSource: true
                        }
                    }
                }
            }
        };
    }

    async connectToNetwork() {
        if (!fabricNetworkModule || !Gateway || !Wallets) {
            throw new Error('Fabric network module not available');
        }
        
        try {
            const gateway = new Gateway();
            const creds = await this.getCredentials();
            const connectionProfile = await this.buildConnectionProfile();

            const wallet = await Wallets.newInMemoryWallet();
            
            if (!creds.userCert || !creds.userPrivateKey) {
                throw new Error('User certificate or private key not found');
            }

            const identity = {
                credentials: {
                    certificate: creds.userCert,
                    privateKey: creds.userPrivateKey
                },
                mspId: BLOCKCHAIN_CONFIG.MEMBER_ID,
                type: 'X.509'
            };
            
            await wallet.put('appUser', identity);

            await gateway.connect(connectionProfile, {
                identity: 'appUser',
                wallet: wallet,
                discovery: { enabled: false, asLocalhost: false }
            });
            
            const network = await gateway.getNetwork(BLOCKCHAIN_CONFIG.CHANNEL_NAME);
            const contract = network.getContract(BLOCKCHAIN_CONFIG.CHAINCODE_NAME);
            
            return { gateway, contract, connected: true };
        } catch (error) {
            console.error('Blockchain connection error:', error.message);
            throw error;
        }
    }

    async getNetworkStatus() {
        try {
            const { gateway, connected } = await this.connectToNetwork();
            await gateway.disconnect();
            return {
                connected: true,
                network: BLOCKCHAIN_CONFIG.NETWORK_ID,
                member: BLOCKCHAIN_CONFIG.MEMBER_ID,
                peer: BLOCKCHAIN_CONFIG.PEER_ENDPOINT,
                orderer: BLOCKCHAIN_CONFIG.ORDERER_ENDPOINT
            };
        } catch (error) {
            return {
                connected: false,
                error: error.message,
                network: BLOCKCHAIN_CONFIG.NETWORK_ID,
                member: BLOCKCHAIN_CONFIG.MEMBER_ID
            };
        }
    }


}

const fabricService = new FabricService();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const { requestContext, rawPath, body: rawBody } = event;
        const httpMethod = requestContext?.http?.method || event.httpMethod || 'GET';
        const path = rawPath || event.path || '/';
        
        const parsedBody = rawBody ? (typeof rawBody === 'string' ? JSON.parse(rawBody) : rawBody) : {};

        if (httpMethod === 'OPTIONS') {
            return { statusCode: 200, headers, body: JSON.stringify({ message: 'CORS OK' }) };
        }

        // Health check with blockchain status
        if (path === '/health' || path.endsWith('/health')) {
            const networkStatus = await fabricService.getNetworkStatus();
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ 
                    status: 'running', 
                    timestamp: new Date().toISOString(),
                    blockchain: networkStatus
                })
            };
        }

        // Upload certificates for blockchain authentication
        if ((path === '/certificates' || path.endsWith('/certificates')) && httpMethod === 'POST') {
            try {
                const { userCert, userPrivateKey, tlsCert, caTlsCert } = parsedBody;
                if (!userCert || !userPrivateKey) {
                    return {
                        statusCode: 400,
                        headers,
                        body: JSON.stringify({ error: 'Missing userCert or userPrivateKey' })
                    };
                }

                process.env.USER_CERT = userCert;
                process.env.USER_PRIVATE_KEY = userPrivateKey;
                if (tlsCert) process.env.TLS_CERT = tlsCert;
                if (caTlsCert) process.env.CA_TLS_CERT = caTlsCert;

                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ 
                        success: true, 
                        message: 'Certificates uploaded successfully'
                    })
                };
            } catch (error) {
                console.error('Certificate upload error:', error.message);
                return {
                    statusCode: 500,
                    headers,
                    body: JSON.stringify({ error: 'Certificate upload failed: ' + error.message })
                };
            }
        }

        // Get All Assets
        if ((path === '/assets' || path.endsWith('/assets')) && httpMethod === 'GET') {
            try {
                const { gateway, contract } = await fabricService.connectToNetwork();
                const result = await contract.evaluateTransaction('GetAllAssets');
                await gateway.disconnect();
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ success: true, data: JSON.parse(result.toString()), source: 'blockchain' })
                };
            } catch (fabricError) {
                console.log('Fabric error, using mock data:', fabricError.message);
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ success: true, data: mockAssets, source: 'mock', warning: 'Fabric unavailable' })
                };
            }
        }

        // Create Asset
        if ((path === '/assets' || path.endsWith('/assets')) && httpMethod === 'POST') {
            const { assetId, name, location, owner } = parsedBody;
            
            if (!assetId || !name || !location || !owner) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({ error: 'Missing required fields: assetId, name, location, owner' })
                };
            }

            try {
                const { gateway, contract } = await fabricService.connectToNetwork();
                const transaction = contract.createTransaction('CreateAsset');
                const transactionId = transaction.getTransactionId();
                await transaction.submit(assetId, name, location, owner);
                await gateway.disconnect();
                
                const newAsset = { ID: assetId, name, location, owner, timestamp: new Date().toISOString(), transactionId };
                return {
                    statusCode: 201,
                    headers,
                    body: JSON.stringify({ success: true, data: newAsset, source: 'blockchain', transactionId })
                };
            } catch (fabricError) {
                console.log('Fabric error, using mock:', fabricError.message);
                const newAsset = { ID: assetId, Name: name, Location: location, Owner: owner, Timestamp: new Date().toISOString() };
                mockAssets.push(newAsset);
                return {
                    statusCode: 201,
                    headers,
                    body: JSON.stringify({ success: true, data: newAsset, source: 'mock' })
                };
            }
        }

        // Get Asset by ID
        if (path.includes('/assets/') && path.split('/').length === 3 && httpMethod === 'GET' && !path.includes('/transfer')) {
            const assetId = path.split('/').pop();
            try {
                const { gateway, contract } = await fabricService.connectToNetwork();
                const result = await contract.evaluateTransaction('QueryAsset', assetId);
                await gateway.disconnect();
                
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ success: true, data: JSON.parse(result.toString()), source: 'blockchain' })
                };
            } catch (fabricError) {
                console.log('Fabric error, using mock:', fabricError.message);
                const asset = mockAssets.find(a => a.ID === assetId);
                if (asset) {
                    return {
                        statusCode: 200,
                        headers,
                        body: JSON.stringify({ success: true, data: asset, source: 'mock' })
                    };
                }
                return {
                    statusCode: 404,
                    headers,
                    body: JSON.stringify({ error: 'Asset not found' })
                };
            }
        }

        // Get Asset History
        if (path.includes('/assets/') && path.includes('/history') && httpMethod === 'GET') {
            const assetId = path.split('/')[2];
            try {
                const { gateway, contract, connected } = await fabricService.connectToNetwork();
                const network = gateway.getCurrentIdentity() ? await gateway.getNetwork(BLOCKCHAIN_CONFIG.CHANNEL_NAME) : null;
                
                if (network) {
                    const channel = network.getChannel();
                    const peer = channel.getPeers()[0];
                    
                    // Use Fabric's getHistoryForKey to get complete audit trail
                    const historyIterator = await channel.queryByChaincode({
                        chaincodeId: BLOCKCHAIN_CONFIG.CHAINCODE_NAME,
                        fcn: 'GetAssetHistory',
                        args: [assetId]
                    }, peer);
                    
                    await gateway.disconnect();
                    
                    if (historyIterator && historyIterator[0]) {
                        const history = JSON.parse(historyIterator[0].toString());
                        return {
                            statusCode: 200,
                            headers,
                            body: JSON.stringify({ success: true, data: history, source: 'blockchain' })
                        };
                    }
                }
                
                await gateway.disconnect();
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ success: true, data: [], source: 'blockchain', message: 'No history available' })
                };
            } catch (fabricError) {
                console.log('Fabric history error:', fabricError.message);
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ success: true, data: [], source: 'mock', warning: 'History unavailable' })
                };
            }
        }

        // Transfer Asset
        if (path.includes('/assets/') && path.includes('/transfer') && httpMethod === 'PUT') {
            const assetId = path.split('/')[2];
            const { newOwner, newLocation } = parsedBody;
            
            if (!newOwner || !newLocation) {
                return {
                    statusCode: 400,
                    headers,
                    body: JSON.stringify({ error: 'Missing required fields: newOwner, newLocation' })
                };
            }

            try {
                const { gateway, contract } = await fabricService.connectToNetwork();
                const transaction = contract.createTransaction('TransferAsset');
                const transactionId = transaction.getTransactionId();
                await transaction.submit(assetId, newOwner, newLocation);
                await gateway.disconnect();
                
                const updatedAsset = { ID: assetId, owner: newOwner, location: newLocation, timestamp: new Date().toISOString(), transactionId };
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ success: true, data: updatedAsset, source: 'blockchain', transactionId })
                };
            } catch (fabricError) {
                console.log('Fabric error, using mock:', fabricError.message);
                const asset = mockAssets.find(a => a.ID === assetId);
                if (asset) {
                    asset.Owner = newOwner;
                    asset.Location = newLocation;
                    asset.Timestamp = new Date().toISOString();
                    return {
                        statusCode: 200,
                        headers,
                        body: JSON.stringify({ success: true, data: asset, source: 'mock' })
                    };
                }
                return {
                    statusCode: 404,
                    headers,
                    body: JSON.stringify({ error: 'Asset not found' })
                };
            }
        }

        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Route not found', path, method: httpMethod })
        };

    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: error.message, stack: error.stack })
        };
    }
};