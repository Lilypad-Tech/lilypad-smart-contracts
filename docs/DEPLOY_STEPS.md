# How to deploy the Lilypad contracts

To deploy the Lilypad core protocol contracts, we need to follow a specific order to fufill dependencies of certain contracts:
- LilypadUser
- LilypadStorage
- LilypadTokenomics
- LilypadToken
- LilypadModuleDirectory
- LilypadPaymentEngine
- LilypadProxy
- LilypadVesting

The deployment scripts use the OpenZepplin Upgrade library as a large amount of the core contracts are upgradable (folliowing the TransparentProxy pattern), you learn more using that library with foundry [here](https://docs.openzeppelin.com/upgrades-plugins/foundry-upgrades).

A note on the proxy contracts:
A proxy contract is a contract that acts as the main usage point for the contract when it's deployed.  It points to the actual implementation contract in its storage slot and then delegates calls to it.  This allows for the implementation contract to be upgraded without having to deploy a new proxy contract.

There are many gotcha's with proxt contracts such as storage slot collisions, contract inheritance issues, function collision and the like.  Below are some great resources from OpenZeppelin that cover these topics:
- [Proxy Upgrade Patterns](https://docs.openzeppelin.com/upgrades-plugins/proxies)
- [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable)

## Prerequisites:
- Anvil testnet node running (if running locally)
- A private key for the deployer (this will be the admin of the proxy contracts and the admin of the contracts)
- The deployer's address (this will be the admin of the proxy contracts and the admin of the contracts)

- Note: If you would like to verify the contract deployments, this will require you to have an API Key from Aribican to work and set in your enviroment variables as ARBISCAN_API_KEY

- Note: If you manke any changes to the contracts after the initial deployment, you will need to run `forge clean && forge build` again to ensure the contract bytecode is up to date.

## 0. Create a .env file

Create a .env file in the root of the project and add the following copying the contents of the sample.env file.

By default the `TREASURY_WALLET_ADDRESS`, `REWARDS_WALLET_ADDRESS` and `VALIDATION_POOL_WALLET_ADDRESS` wallets are set to the default anvil addresses but will need to be updated to the actual addresses when deploying to a testnet or mainnet.

Additionally, the `INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN` variable is also set to the default anvil address but will need to be updated to the actual address of the deployer when deploying to a testnet or mainnet.

## 1. Deploy the Lilypad User Contract

The Lilypad User contract is the first contract to be deployed. It is used to manage user accounts and their associated data.  Choose the command that corresponds to the network you are deploying to.

Anvil:
```shell
forge script script/LilypadUser.s.sol:DeployLilypadUser --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:
```shell
forge script script/LilypadUser.s.sol:DeployLilypadUser -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification:
```shell
forge script script/LilypadUser.s.sol:DeployLilypadUser -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as USER_PROXY_ADDRESS

## 2. Deploy the Lilypad Storage Contract

The Lilypad Storage contract is the second contract to be deployed. It is used to manage the storage of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil:
```shell
forge script script/LilypadStorage.s.sol:DeployLilypadStorage --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:
```shell
forge script script/LilypadStorage.s.sol:DeployLilypadStorage -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification:
```shell
forge script script/LilypadStorage.s.sol:DeployLilypadStorage -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as STORAGE_PROXY_ADDRESS

## 3. Deploy the Lilypad Tokenomics Contract

The Lilypad Tokenomics contract is the third contract to be deployed. It is used to manage the tokenomics of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil:

```shell
forge script script/LilypadTokenomics.s.sol:DeployLilypadTokenomics --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadTokenomics.s.sol:DeployLilypadTokenomics -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification:

```shell
forge script script/LilypadTokenomics.s.sol:DeployLilypadTokenomics -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as TOKENOMICS_PROXY_ADDRESS

## 4. Deploy the Lilypad Token Contract

The Lilypad Token contract is the fourth contract to be deployed. It is used to manage the token of the Lilypad protocol.  The token is to be deployed on a L1 network and then bridged to the L2 network. Choose the command that corresponds to the network you are deploying to.

Anvil:

```shell
forge script script/LilypadToken.s.sol:DeployLilypadToken --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Sepolia:

```shell
forge script script/LilypadToken.s.sol:DeployLilypadToken -rpc-url https://1rpc.io/sepolia --private-key $PRIVATE_KEY --broadcast
```

Sepolia with verification:

```shell
forge script script/LilypadToken.s.sol:DeployLilypadToken -rpc-url https://1rpc.io/sepolia --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as TOKEN_ADDRESS

### Bridging the token to Arbitrum
Note: This only needed when deploying to testnet and can be skipped if you are deploying locally through anvil.  To get around this step for local testting, you can simply deploy the token locally and then use the token address as the L2_TOKEN_PROXY_ADDRESS in your .env file.

To bridge the token to Arbitrum, you will need to use the Arbitrum Bridge.  You will need to have some Sepolia ETH in your wallet to pay for the bridge fee.

Testnet:
1. Head over to https://bridge.arbitrum.io/?destinationChain=arbitrum-sepolia&sourceChain=sepolia
2. Connect your wallet
3. Bridge your token
4. Wait for the transaction to be confirmed
5. click on the txn history tab
6. click on the details and click on the arbiscan link in the txn history
7. Look at the transaction and find the proxy contract address it created, this will be the proxy l2 token address that the Arbitrum Token Bridge will have deployed for us.  Record this address for future use in your .env file as L2_TOKEN_PROXY_ADDRESS


## 5. Deploy the Module Directory Contract

The Module Directory contract is the fifth contract to be deployed. It is used to manage the modules of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil:

```shell
forge script script/LilypadModuleDirectory.s.sol:DeployLilypadModuleDirectory --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadModuleDirectory.s.sol:DeployLilypadModuleDirectory -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification:

```shell
forge script script/LilypadModuleDirectory.s.sol:DeployLilypadModuleDirectory -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as MODULE_DIRECTORY_PROXY_ADDRESS

## 6. Deploy the Payment Engine Contract

The Payment Engine contract is the sixth contract to be deployed. It is used to manage and orchestrate the payment rails of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil:

```shell
forge script script/LilypadPaymentEngine.s.sol:DeployLilypadPaymentEngine --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadPaymentEngine.s.sol:DeployLilypadPaymentEngine -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification:

```shell
forge script script/LilypadPaymentEngine.s.sol:DeployLilypadPaymentEngine -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as PAYMENT_ENGINE_PROXY_ADDRESS

## 7. Deploy the Lilypad Proxy Contract

The Lilypad Proxy contract is the seventh contract to be deployed. It is used as the main entry point for the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil:

```shell
forge script script/LilypadProxy.s.sol:DeployLilypadProxy --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadProxy.s.sol:DeployLilypadProxy -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification:

```shell
forge script script/LilypadProxy.s.sol:DeployLilypadProxy -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as LILYPAD_PROXY_ADDRESS

## 8. Deploy the Lilypad Vesting Contract

The Lilypad Vesting contract is the eighth contract to be deployed. It is used to manage the vesting of the Lilypad protocol.  This contract will be deployed to the l2 network using the l2 token proxy address. Choose the command that corresponds to the network you are deploying to.

Anvil:

```shell
forge script script/LilypadVesting.s.sol:DeployLilypadVesting --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadVesting.s.sol:DeployLilypadVesting -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```     

Arbitrum Sepolia with verification:

```shell
forge script script/LilypadVesting.s.sol:DeployLilypadVesting -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```     

Make note of the address of the contract deployed and add it to the .env file as VESTING_ADDRESS

## 9. Granting roles to the various contracts

The following steps are to grant the necessary roles to the various contracts.  This is to ensure that the contracts are properly configured and working together.  You will need to interact with the contracts using the `INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN` wallet as this one will be granted the DEFAULT_ADMIN_ROLE after every deployment.

After the Module Directory contract is deployed, you will need to grant the necessary roles to the contract:
- The lilypad user contract needs to grant the module directory the CONTROLLER_ROLE

After the Payment Engine contract is deployed, you will need to grant the necessary roles to the contract:
- The lilypad user contract needs to grant the payment engine the CONTROLLER_ROLE
- The lilypad storage contract needs to grant the payment engine the CONTROLLER_ROLE

After the Lilypad Proxy contract is deployed, you will need to grant the necessary roles to the contract:
- The lilypad user contract needs to grant the proxy the CONTROLLER_ROLE
- The lilypad storage contract needs to grant the proxy the CONTROLLER_ROLE
- The payment engine needs to grant the proxy the CONTROLLER_ROLE