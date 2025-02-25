# Lilypad Network

The Lilypad Network is a distributed compute network powering AI inference with a three-sided marketplace for users, hardware providers and app builders.

You can learn more about Lilypad by visiting our [docs page](https://docs.lilypad.tech).

## Actors in the Lilypad ecosystem and nomenclature

### Job Creators

Job creators are users who run jobs that are executed on the Lilypad network.

### Resource Providers

Resource providers are users who provide their hardware resources that allow jobs to run on the network.

### Module Creators

Module Creators are the "app builders" of the Lilypad ecosystem who create modules that run as jobs on the network.

### Module
Modules are the compute jobs that are run on the Lilypad network of Resource Provider nodes.  [Here is an example of a module](https://github.com/narbs91/lilypad-ollama-deepseek-r1-1-5b) allowing users to run the deepseek 1.5b model for inference

### Validators

Validators are users in the network who validate the work done by Resource Providers to ensure that the work is correct and meets the requirements of the job creator.

### Solver

The Solver is the match maker in the network that matches Job Creators who want to run jobs with Resource Providers who are capable and willing to run them. The result of a match is a deal and the Solver earns a fee for the creation of each deal.

### Deal

A deal is a match between a Job Creator who wants to run a module on the network and a Resource Provider who will run the job.  Sensitive details about the deal are not stored on-chain

### Result

A result is metadata about a job that has run on the network. Sensitive details about the result and actual job outputs are not stored on-chain.

### Validation Results

A validation result is the output of a process to check the correctness of a job run.

## Lilypad Protocol

The Lilypad protocol is a set of smart contracts that are used to power the Lilypad network. At a high level, the protocol represents a DeFi protocol allowing people to deposit LILY tokens to be able to request and run compute jobs, moving funds around for various actors when a job is complete, and supporting storage of data.  Here are the contracts that make up the protocol:

- **LilypadUser** : A contract that allows for the creation and management of users on the network
- **LilypadStorage** : A contract that allows for the storage of deals, results and validation results on the network
- **LilypadToken** : A contract that represents the LILY token on the network
- **LilypadModuleDirectory** : A contract that allows for the creation and management of modules on the network
- **LilypadPaymentEngine** : The contract that represents the core payment rails of the protocol allowing for escrow deposits and payouts
- **LilypadValidation** : A contract that allows for the validation of modules on the network (This is currently incomplete and slated for a future release)
- **LilypadVesting** : A contract that allows for the vesting of tokens on the network for various stakeholders
- **LilypadProxy** : The main access point for users of the protocol
- **LilypadTokenomics** : A contract that stores the tokenomics values used in the protocol
- **LilypadContractRegistry** : A contract that stores all the addresses of the contracts in the protocol

With the exception of the Token and Vesting Contracts, all other contracts are upgradable using the OpenZeppelin Upgrades Plugin.

## Foundry Documentation

This project uses [Foundry](https://getfoundry.sh/) to compile, test and deploy the contracts.

For more information on Foundry, please refer to the [Foundry Book](https://book.getfoundry.sh/).

## Usage

### Install Foundry

```shell
$ curl -L https://foundry.paradigm.xyz | bash
```

### Install Dependencies

```shell
$ forge install
```

### Clean

```shell
$ forge clean
```

### Build

Regular build
```shell
$ forge build
```

Build with contract sizes
```shell
$ forge build --sizes
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploying the Contracts

Please refer to the [Deploy](./docs/DEPLOY_STEPS.md) file for more information on how to deploy the contracts locally and to a testnet.

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Gas Reports

```shell
$ forge test --gas-report
```