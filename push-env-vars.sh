#!/bin/bash

# Read certificates
USER_CERT=$(cat certs/cert.pem)
USER_KEY=$(cat certs/key.pem)
TLS_CERT=$(cat certs/orderer-tls.pem)
CA_TLS=$(cat certs/ca.pem)

# Export as environment variables for amplify
export AMPLIFY_function_supplyChainAPI_caEndpoint="ca.m-ktgjmti7hfgtzku7ecmps4fquu.n-cfcacd47iza7dalldsyz32fuzy.managedblockchain.us-east-1.amazonaws.com:30002"
export AMPLIFY_function_supplyChainAPI_memberId="m-KTGJMTI7HFGTZKU7ECMPS4FQUU"
export AMPLIFY_function_supplyChainAPI_networkId="n-CFCACD47IZA7DALLDSYZ32FUZY"
export AMPLIFY_function_supplyChainAPI_userCert="$USER_CERT"
export AMPLIFY_function_supplyChainAPI_userPrivateKey="$USER_KEY"
export AMPLIFY_function_supplyChainAPI_tlsCert="$TLS_CERT"
export AMPLIFY_function_supplyChainAPI_caTlsCert="$CA_TLS"

amplify push --yes
