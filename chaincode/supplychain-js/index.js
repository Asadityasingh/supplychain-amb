'use strict';

const { Contract } = require('fabric-contract-api');

class SupplyChainContract extends Contract {

    // Create new asset
    async CreateAsset(ctx, assetId, name, location, owner) {
        const asset = {
            ID: assetId,
            Name: name,
            Location: location,
            Owner: owner,
            Timestamp: new Date().toISOString()
        };

        await ctx.stub.putState(assetId, Buffer.from(JSON.stringify(asset)));
        return JSON.stringify(asset);
    }

    // Query asset by ID
    async QueryAsset(ctx, assetId) {
        const assetJSON = await ctx.stub.getState(assetId);
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`Asset ${assetId} does not exist`);
        }
        return assetJSON.toString();
    }

    // Transfer asset to new owner
    async TransferAsset(ctx, assetId, newOwner, newLocation) {
        const assetString = await this.QueryAsset(ctx, assetId);
        const asset = JSON.parse(assetString);
        
        asset.Owner = newOwner;
        asset.Location = newLocation;
        asset.Timestamp = new Date().toISOString();
        
        await ctx.stub.putState(assetId, Buffer.from(JSON.stringify(asset)));
        return JSON.stringify(asset);
    }

    // Get all assets
    async GetAllAssets(ctx) {
        const allResults = [];
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            allResults.push(record);
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }
}

module.exports = SupplyChainContract;
