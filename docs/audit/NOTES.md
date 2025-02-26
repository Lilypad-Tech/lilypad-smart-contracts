# Notes for the auditor

Feburary 25th, 2025

- 9 Core Implementation contracts with unit/fuzz tests
- 9 deployment scripts
- 7 Interface contracts
- Source lines of code (SLOC) in source files: 1955 (from slither)
  - Counting lines of code reported on GitHub: 2538
- Aiming to deploy core protocol to Arbitrum
- Aiming to deploy L1 token on Ethereum Mainnet. The token will be bridged to Aribitrum using the Arbitrum Bridge UI creating [a StandardArbERC20 token](https://github.com/OffchainLabs/token-bridge-contracts/blob/main/contracts/tokenbridge/arbitrum/StandardArbERC20.sol).  This bridged token will be used in the core protocol
- Key areas to concentrate on
  - LilypadPaymentEngine
  - LilypadProxy
  - LilpadToken
  - Making sure we have contracts properly set up to be upgradable
- Contract to ignore for audit
  - LilypadValidaton (this is out of scope for our MVP and will be revisited post MVP)
