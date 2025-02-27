# How to deploy the Lilypad contracts

To deploy the Lilypad protocol contracts, we need to follow a specific deployment order to fufill dependencies of certain contracts:
- LilypadUser
- LilypadStorage
- LilypadTokenomics
- LilypadToken
- LilypadModuleDirectory
- LilypadPaymentEngine
- LilypadProxy
- LilypadVesting
- LilypadContractRegistry

The deployment scripts use the OpenZepplin Upgrade library as a large amount of the core contracts are upgradable (folliowing the TransparentProxy pattern), you learn more about how to use that library with foundry [here](https://docs.openzeppelin.com/upgrades-plugins/foundry-upgrades).

A note on transparent proxy contracts:
A transparent proxy contract is a contract that acts as the main usage point for the contract when it's deployed.  It points to the actual implementation contract in its storage slot and then delegates calls to it.  This allows for the implementation contract to be upgraded without having to deploy a new proxy contract.

There are many gotcha's with proxt contracts such as storage slot collisions, contract inheritance issues, function collision and the like.  Below are some great resources from OpenZeppelin that cover these topics:
- [Proxy Upgrade Patterns](https://docs.openzeppelin.com/upgrades-plugins/proxies)
- [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable)

## Prerequisites:
- Anvil testnet node running (if running locally)
- A private key for the deployer (this will be the admin of the proxy contracts and the admin of the contracts)
- The deployer's address (this will be the admin of the proxy contracts and the admin of the contracts)

- Note: If you would like to verify the contract deployments, this will require you to have an API Key from Arbiscan and Etherscan to work and set in your enviroment variables as ARBISCAN_API_KEY and ETHERSCAN_API_KEY respectively.

- Note: If you manke any changes to the contracts after the initial deployment, you will need to run `forge clean && forge build` again to ensure the contract bytecode is up to date.

## 0. Create a .env file

Create a .env file in the root of the project and copy over the contents of the sample.env file.

By default the `TREASURY_WALLET_ADDRESS`, `REWARDS_WALLET_ADDRESS` and `VALIDATION_POOL_WALLET_ADDRESS` wallets are set to the default anvil addresses but will need to be updated to the actual addresses when deploying to a testnet or mainnet.

Additionally, the `INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN` variable is also set to the default anvil address but will need to be updated to the actual address of the deployer when deploying to a testnet or mainnet.

## 1. Deploy the Lilypad User Contract

The Lilypad User contract is the first contract to be deployed. It is used to manage user accounts and their associated data.  Choose the command that corresponds to the network you are deploying to.

Anvil (Anvil private key used below):
```shell
forge script script/LilypadUser.s.sol:DeployLilypadUser --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:
```shell
forge script script/LilypadUser.s.sol:DeployLilypadUser -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):
```shell
forge script script/LilypadUser.s.sol:DeployLilypadUser -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as USER_PROXY_ADDRESS

## 2. Deploy the Lilypad Storage Contract

The Lilypad Storage contract is the second contract to be deployed. It is used to manage the storage of deals, results and validations for the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil (Anvil private key used below):
```shell
forge script script/LilypadStorage.s.sol:DeployLilypadStorage --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:
```shell
forge script script/LilypadStorage.s.sol:DeployLilypadStorage -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):
```shell
forge script script/LilypadStorage.s.sol:DeployLilypadStorage -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as STORAGE_PROXY_ADDRESS

## 3. Deploy the Lilypad Tokenomics Contract

The Lilypad Tokenomics contract is the third contract to be deployed. It is used to manage the tokenomics of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Anvil (Anvil private key used below):

```shell
forge script script/LilypadTokenomics.s.sol:DeployLilypadTokenomics --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadTokenomics.s.sol:DeployLilypadTokenomics -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadTokenomics.s.sol:DeployLilypadTokenomics -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as TOKENOMICS_PROXY_ADDRESS

## 4. Deploy the Lilypad Token Contract

The Lilypad Token contract is the fourth contract to be deployed. It is used to manage the token of the Lilypad protocol.  The token is to be deployed on a L1 network and then bridged to the L2 network. Choose the command that corresponds to the network you are deploying to.

Anvil (Anvil private key used below):

```shell
forge script script/LilypadToken.s.sol:DeployLilypadToken --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Sepolia:

```shell
forge script script/LilypadToken.s.sol:DeployLilypadToken -rpc-url https://1rpc.io/sepolia --private-key $PRIVATE_KEY --broadcast
```

Sepolia with verification (note: have the ETHERSCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadToken.s.sol:DeployLilypadToken -rpc-url https://1rpc.io/sepolia --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as L1_TOKEN_ADDRESS for reference

### Bridging the token to Arbitrum
Note: This only needed when deploying to testnet and can be skipped if you are deploying locally through anvil.  To get around this step for local deploment, you can simply just use the address of the L1_TOKEN_ADDRESS as the L2_TOKEN_PROXY_ADDRESS in your .env file and move on to step 5.

To bridge the token to Arbitrum, you will need to use the Arbitrum Bridge.  You will need to have some Sepolia ETH in your wallet to pay for the bridge fee.

Testnet:
1. Head over to https://bridge.arbitrum.io/?destinationChain=arbitrum-sepolia&sourceChain=sepolia
2. Connect your wallet (make sure you on the Arbitrum Sepolia network)
3. Bridge your token
4. Wait for the transaction to be confirmed
5. Click on the txn history tab
6. Click on the details and click on the arbiscan link in the txn history
7. Look at the transaction and find the proxy contract address it created, this will be the proxy l2 token address that the Arbitrum Token Bridge will have deployed for us.  Record this address for future use in your .env file as L2_TOKEN_PROXY_ADDRESS


## 5. Deploy the Module Directory Contract

The Module Directory contract is the fifth contract to be deployed. It is used to manage the modules of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Dependencies:
- The Lilpad User Proxy Contract

Anvil (Anvil private key used below):

```shell
forge script script/LilypadModuleDirectory.s.sol:DeployLilypadModuleDirectory --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadModuleDirectory.s.sol:DeployLilypadModuleDirectory -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadModuleDirectory.s.sol:DeployLilypadModuleDirectory -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as MODULE_DIRECTORY_PROXY_ADDRESS for reference

### Upgrading the Module Directory Contract

As an example of how to upgrade the Module Directory Contract, we have a mock script that can be used to upgrade the contract to a new implementation.  This script is only meant for auditors to assess the correctness of the upgrade process as all the other contracts will then have a similar upgrade process. While not applicatiable to this particular contract, if other contracts require new variables to be set (i.e. those that are set in the initialize function), we will be calling the corresponding setter functions defined for those variable after the upgrade has completed.

Anvil (Anvil private key used below):

```shell
forge script script/upgrades/MockUpgradeLilypadModuleDirectory.s.sol:MockUpgradeLilypadModuleDirectory --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

## 6. Deploy the Payment Engine Contract

The Payment Engine contract is the sixth contract to be deployed. It is used to manage and orchestrate the payment rails of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Dependencies:
- The Lilpad User Proxy Contract
- The Lilypad Tokenomics Proxy Contract
- The Lilypad Storage Proxy Contract
- The Lilypad L2 Token Proxy Contract

Anvil (Anvil private key used below):

```shell
forge script script/LilypadPaymentEngine.s.sol:DeployLilypadPaymentEngine --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadPaymentEngine.s.sol:DeployLilypadPaymentEngine -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadPaymentEngine.s.sol:DeployLilypadPaymentEngine -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as PAYMENT_ENGINE_PROXY_ADDRESS

## 7. Deploy the Lilypad Proxy Contract

The Lilypad Proxy contract is the seventh contract to be deployed. It is used as the main entry point for users of the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Dependencies:
- The Lilypad User Proxy Contract
- The Lilypad Storage Proxy Contract
- The Lilypad Payment Engine Proxy Contract
- The Lilypad L2 Token Proxy Contract

Anvil (Anvil private key used below):

```shell
forge script script/LilypadProxy.s.sol:DeployLilypadProxy --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadProxy.s.sol:DeployLilypadProxy -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadProxy.s.sol:DeployLilypadProxy -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the address of proxy contract deployed and add it to the .env file as LILYPAD_PROXY_ADDRESS

## 8. Deploy the Lilypad Vesting Contract

The Lilypad Vesting contract is the eighth contract to be deployed. It is used to manage the vesting of the Lilypad protocol.  This contract will be deployed to the l2 network having the l2 token as a dependency. Choose the command that corresponds to the network you are deploying to.

Dependencies:
- The Lilypad L2 Token Proxy Contract

Anvil (Anvil private key used below):

```shell
forge script script/LilypadVesting.s.sol:DeployLilypadVesting --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadVesting.s.sol:DeployLilypadVesting -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```     

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadVesting.s.sol:DeployLilypadVesting -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```     

Make note of the address of the contract deployed and add it to the .env file as VESTING_ADDRESS

## 9. Deploy the Lilypad Contract Registry

The Lilypad Contract Registry is the ninth contract to be deployed. It is used as a registry of all the contracts in the Lilypad protocol. Choose the command that corresponds to the network you are deploying to.

Dependencies:
- The Lilypad User Proxy Contract
- The Lilypad Storage Proxy Contract
- The Lilypad Tokenomics Proxy Contract
- The Lilypad Payment Engine Proxy Contract
- The Lilypad L2 Token Proxy Contract
- The L1 Lilypad Token Contract 
- The Lilypad Vesting Contract
- The Lilypad Module Directory Proxy Contract

Anvil (Anvil private key used below):

```shell
forge script script/LilypadContractRegistry.s.sol:DeployLilypadContractRegistry --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

Arbitrum Sepolia:

```shell
forge script script/LilypadContractRegistry.s.sol:DeployLilypadContractRegistry -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast
```

Arbitrum Sepolia with verification (note: have the ARBISCAN_API_KEY set in your environment variables):

```shell
forge script script/LilypadContractRegistry.s.sol:DeployLilypadContractRegistry -rpc-url https://arbitrum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

Make note of the contract address once deployed for record keeping purposes

## 10. Granting roles to the various contracts

The following steps are to grant the necessary roles to the various contracts.  This is to ensure that the contracts are properly configured and working together.  You will need to interact with the contracts using the `INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN` wallet as this one will be granted the DEFAULT_ADMIN_ROLE after every deployment.

After the Module Directory contract is deployed, you will need to grant the necessary roles to the contract:
- Call the `grantRole` function on the lilypad user contract to grant the module directory the CONTROLLER_ROLE

After the Payment Engine contract is deployed, you will need to grant the necessary roles to the contract:
- Call the `grantRole` function on the lilypad user contract to grant the payment engine the CONTROLLER_ROLE
- Call the `grantRole` function on the lilypad storage contract to grant the payment engine the CONTROLLER_ROLE

After the Lilypad Proxy contract is deployed, you will need to grant the necessary roles to the contract:
- Call the `grantRole` function on the lilypad user contract to grant the proxy the CONTROLLER_ROLE
- Call the `grantRole` function on the lilypad storage contract to grant the proxy the CONTROLLER_ROLE
- Call the `grantRole` function on the payment engine contract to grant the proxy the CONTROLLER_ROLE