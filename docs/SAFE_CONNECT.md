# Safe Smart Account Integration and Deployment Guide

This guide provides step-by-step instructions for deploying a Safe Smart Account using the Safe{Wallet} UI at [app.safe.global](https://app.safe.global) or by manually setting up and running the Safe{Wallet} web application locally as per the instructions in the [Safe Wallet Monorepo](https://github.com/safe-global/safe-wallet-monorepo/blob/dev/apps/web/README.md).

## Option 1: Deploying Safe via Safe{Wallet} UI

The Safe{Wallet} UI provides a user-friendly interface to create and deploy a Safe Smart Account without writing code.

### Prerequisites

- A compatible Web3 wallet (e.g., MetaMask, WalletConnect) installed in your browser.
- An Ethereum account with sufficient funds to cover gas fees in the desired network (e.g., Mainnet, Sepolia, etc.).
- Access to a supported browser (e.g., Chrome, Firefox).

### Steps

1. **Visit Safe{Wallet} UI**:

   - Navigate to [https://app.safe.global](https://app.safe.global).

2. **Connect Your Wallet**:

   - Click **"Connect Wallet"** in the top-right corner.
   - Select your wallet provider (e.g., MetaMask) and connect your account.
   - Ensure your wallet is set to the desired network (e.g., Sepolia for testnet or Mainnet for production).

3. **Create a New Safe**:

   - Click **"Create New Safe"** on the dashboard.
   - Select the network where you want to deploy the Safe (e.g., Sepolia, Ethereum Mainnet, etc.).

4. **Configure Safe Parameters**:

   - **Name**: Enter a name for your Safe (e.g., "MySafeAccount").
   - **Owners**: Add the Ethereum addresses of the owners (e.g., `0xYourAddress1`, `0xYourAddress2`). These are the accounts that will control the Safe.
   - **Threshold**: Specify the number of signatures required to confirm transactions (e.g., 2 out of 3 owners).
   - Review the settings and click **"Next"**.

5. **Review and Deploy**:

   - The UI will display the estimated gas fees for deploying the Safe proxy contract and calling the `setup` function.
   - Confirm the transaction in your connected wallet (e.g., MetaMask).
   - Wait for the transaction to be mined. This typically takes a few seconds on testnets or minutes on Mainnet.

6. **Access Your Safe**:
   - Once deployed, the Safe address will be displayed in the UI.
   - You can now use the Safe{Wallet} interface to manage assets, propose transactions, and configure additional settings (e.g., adding modules).

### Notes

- **Gas Fees**: Ensure your wallet has enough funds to cover gas costs. Fees vary by network and market conditions.
- **Supported Networks**: Check [Safe{Wallet} documentation](https://docs.safe.global) for a list of supported networks.
- **Security**: Double-check owner addresses and threshold settings to avoid locking yourself out of the Safe.

---

## Option 2: Running Safe{Wallet} Locally

This guide explains how to set up and run the Safe{Wallet} web application locally using the [Safe Wallet Monorepo](https://github.com/safe-global/safe-wallet-monorepo/blob/dev/apps/web/README.md).

## Prerequisites

- **Node.js**: v18+ (LTS recommended).
- **Yarn**: Install via `npm install -g yarn`.
- **Git**: To clone the repository.
- A Web3 wallet (e.g., MetaMask) with funds for gas fees.
- An Ethereum node (e.g., [Infura](https://infura.io) or Alchemy).

## Setup

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/safe-global/safe-wallet-monorepo.git
   cd safe-wallet-monorepo
   ```

2. **Install Dependencies**:

   ```bash
   yarn install
   ```

3. **Configure Environment**:

   - Navigate to `apps/web`:
     ```bash
     cd apps/web
     ```
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Update `.env` with required variables:
     - `NEXT_PUBLIC_INFURA_TOKEN`: Get from [Infura](https://docs.infura.io).
     - Optional: `NEXT_PUBLIC_WC_PROJECT_ID` for WalletConnect ([WalletConnect Docs](https://docs.walletconnect.com)).
     - See [README](https://github.com/safe-global/safe-wallet-monorepo/blob/dev/apps/web/README.md) for all variables.

4. **Run the App**:

   - From the monorepo root:
     ```bash
     yarn workspace @safe-global/web start
     ```
   - Or from `apps/web`:
     ```bash
     yarn start
     ```
   - Open [http://localhost:3000](http://localhost:3000) in your browser.

5. **Deploy a Safe**:
   - Connect your wallet (e.g., MetaMask) in the UI.
   - Follow the UI prompts to create a Safe (set owners, threshold, etc.).
   - Confirm the transaction in your wallet.

## Option 3: Deploying Safe Smart Account Contracts (v1.4.1-3)

This guide outlines the steps to deploy Safe Smart Account contracts (version 1.4.1-3) using the [Safe Smart Account repository](https://github.com/safe-global/safe-smart-account/tree/v1.4.1-3).

## Prerequisites

- **Node.js**: v18+ (LTS recommended).
- **npm**: Installed with Node.js.
- **Git**: To clone the repository.
- An Ethereum account with funds for gas fees.
- Access to an Ethereum node (e.g., [Infura](https://infura.io) or Alchemy).
- **Mnemonic**: A valid mnemonic for the deployer account.
- **Solidity**: v0.7.6 (default for v1.4.1).

## Setup

1. **Clone the Repository**:

   ```bash
   git clone --branch v1.4.1-3 https://github.com/safe-global/safe-smart-account.git
   cd safe-smart-account
   ```

2. **Install Dependencies**:

   ```bash
   npm install
   ```

3. **Install Safe Singleton Factory**:
   For deterministic deployment, install the Safe Singleton Factory:

   ```bash
   npm install --save-dev @safe-global/safe-singleton-factory
   ```

4. **Configure Environment**:
   - Create a `.env` file in the project root:
     ```bash
     cp .env.example .env
     ```
   - Add the following variables to `.env`:
     ```
     MNEMONIC=your_12_or_24_word_mnemonic
     INFURA_KEY=your_infura_api_key
     ```
     - Get `INFURA_KEY` from [Infura](https://docs.infura.io).
     - Optionally, set `NODE_URL` for custom EVM networks (e.g., `https://rpc.ankr.com/your_network`).

## Deploy Contracts

1. **Build Contracts**:

   ```bash
   npm run build
   ```

2. **Deploy to a Network**:

   - For a supported network (e.g., `sepolia`, `mainnet`):
     ```bash
     npm run deploy-all <network>
     ```
     Example for Sepolia:
     ```bash
     npm run deploy-all sepolia
     ```
   - For a custom EVM network, set `NODE_URL` in `.env` and run:
     ```bash
     npm run deploy-all custom
     ```

3. **What Happens**:
   - Compiles contracts using Solidity 0.7.6.
   - Deploys contracts deterministically via [Safe Singleton Factory](https://github.com/safe-global/safe-singleton-factory).
   - Verifies contracts on [Sourcify](https://sourcify.dev) and [Etherscan](https://etherscan.io).
   - Performs local verification to ensure on-chain code matches.

## Notes

- **Deterministic Deployment**: Uses Safe Singleton Factory for consistent addresses across networks. Ensure the factory is deployed on your target network (see [Safe Singleton Factory](https://github.com/safe-global/safe-singleton-factory)).
- **Network Support**: Check supported networks in [Safe Deployments](https://github.com/safe-global/safe-deployments).
- **Version**: Always use the audited [v1.4.1 release](https://github.com/safe-global/safe-smart-account/tree/v1.4.1-3) to avoid untested changes.
- **Verification**:
  - Verify on-chain code:
    ```bash
    npx hardhat --network <network> local-verify
    ```
  - Upload to Etherscan:
    ```bash
    npx hardhat --network <network> etherscan-verify
    ```

# Granting Roles to Safe Smart Account for LilypadToken

This section explains how to grant roles (`CONTROLLER_ROLE`, `MINTER_ROLE`, `PAUSER_ROLE`, `VESTING_ROLE`) to a Safe Smart Account for managing the `LilypadToken` contract, as defined in `SharedStructs.sol`.

## Prerequisites

- Deployed Safe Smart Account (see [Safe{Wallet} Docs](https://docs.safe.global)).
- Deployed `LilypadToken` contract with `DEFAULT_ADMIN_ROLE` assigned to an account (e.g., your wallet).
- Access to Safe{Wallet} UI ([app.safe.global](https://app.safe.global) or local instance at [http://localhost:3000](http://localhost:3000)) or a Hardhat setup.
- Role identifiers from `SharedStructs.sol`:
  - `CONTROLLER_ROLE`: `keccak256("CONTROLLER_ROLE")`
  - `MINTER_ROLE`: `keccak256("MINTER_ROLE")`
  - `PAUSER_ROLE`: `keccak256("PAUSER_ROLE")`
  - `VESTING_ROLE`: `keccak256("VESTING_ROLE")`

## Option 1: Grant Roles via Safe{Wallet} UI

1. **Connect to Safe{Wallet} UI**:

   - Navigate to [app.safe.global](https://app.safe.global) or your local instance.
   - Connect your wallet and select the Safe.

2. **Propose Role Assignment**:

   - Go to **"New Transaction"** > **"Contract Interaction"**.
   - Enter the `LilypadToken` contract address.
   - Select the `grantRole` function (from OpenZeppelin's `AccessControl`).
   - Input parameters:
     - `role`: Use the `keccak256` hash of the role (e.g., `0x523a704056deb4170eb6a3ff34525c1045954e9fc07f7c24c9605f4df3db5c5c` for `MINTER_ROLE`). Calculate hashes using a tool like [keccak256 online](https://emn178.github.io/online-tools/keccak_256.html).
     - `account`: The Safe address.
   - Repeat for each role (`CONTROLLER_ROLE`, `MINTER_ROLE`, `PAUSER_ROLE`, `VESTING_ROLE`).
   - Submit the transaction.

3. **Approve and Execute**:
   - Owners approve the transaction in the Safe UI.
   - Execute once the threshold is met.

## Option 2: Grant Roles via Hardhat Script

1. **Setup Hardhat**:

   - Ensure `LilypadToken` and Safe are deployed.
   - Add `LilypadToken` ABI to your Hardhat project (e.g., copy from contract code).

2. **Create Script** (`scripts/grantRoles.js`):

   ```javascript
   const { ethers } = require("hardhat");

   async function grantRoles() {
     const [deployer] = await ethers.getSigners();
     const lilypadTokenAddress = "YOUR_LILYPAD_TOKEN_ADDRESS";
     const safeAddress = "YOUR_SAFE_ADDRESS";

     const LilypadToken = await ethers.getContractAt(
       "LilypadToken",
       lilypadTokenAddress,
       deployer
     );

     const roles = [
       {
         name: "CONTROLLER_ROLE",
         hash: ethers.utils.keccak256(
           ethers.utils.toUtf8Bytes("CONTROLLER_ROLE")
         ),
       },
       {
         name: "MINTER_ROLE",
         hash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE")),
       },
       {
         name: "PAUSER_ROLE",
         hash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("PAUSER_ROLE")),
       },
       {
         name: "VESTING_ROLE",
         hash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("VESTING_ROLE")),
       },
     ];

     for (const role of roles) {
       console.log(`Granting ${role.name} to Safe...`);
       const tx = await LilypadToken.grantRole(role.hash, safeAddress);
       await tx.wait();
       console.log(`${role.name} granted to Safe: ${safeAddress}`);
     }
   }

   grantRoles().catch((error) => {
     console.error(error);
     process.exit(1);
   });
   ```

3. **Run Script**:
   - Update `lilypadTokenAddress` and `safeAddress` in the script.
   - Execute:
     ```bash
     npx hardhat run scripts/grantRoles.js --network <network>
     ```
     Example for Sepolia:
     ```bash
     npx hardhat run scripts/grantRoles.js --network sepolia
     ```

## Notes

- **Permissions**: Only an account with `DEFAULT_ADMIN_ROLE` can call `grantRole`.
- **Role Hashes**: Use a tool like [keccak256 online](https://emn178.github.io/online-tools/keccak_256.html) to compute role hashes if needed.
- **Security**: Verify the Safe address and role hashes to avoid errors.
- **Testing**: Test role assignments on a testnet (e.g., Sepolia) before Mainnet.
- **Safe Management**: Use the Safe UI to execute token operations (e.g., minting, pausing) after roles are granted.

## Resources

- [Safe{Wallet} Docs](https://docs.safe.global)
- [OpenZeppelin AccessControl](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl)
- [Safe Deployments](https://github.com/safe-global/safe-deployments)
- [LilypadToken Contract](https://github.com/your-repo/LilypadToken)
