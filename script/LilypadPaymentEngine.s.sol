// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadPaymentEngine} from "../src/LilypadPaymentEngine.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {LilypadStorage} from "../src/LilypadStorage.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {LilypadTokenomics} from "../src/LilypadTokenomics.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployLilypadPaymentEngine is Script {
    function deployEngine(
        address token,
        address storage_,
        address user_,
        address tokenomics,
        address treasury,
        address rewards,
        address validationPool
    ) internal returns (address) {
        // Note: This is the address[0] from anvil only meant for testing
        // TODO: Change this to the address of the initial owner
        address initialOwner = vm.envAddress("INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN");

        bytes memory initData = abi.encodeWithSelector(
            LilypadPaymentEngine.initialize.selector,
            token,
            storage_,
            user_,
            tokenomics,
            treasury,
            rewards,
            validationPool
        );

        address paymentEngineProxy = Upgrades.deployTransparentProxy(
            "LilypadPaymentEngine.sol",
            initialOwner,
            initData
        );

        return paymentEngineProxy;
    }
    /**
        Note: Once the payment engine is deployed, the roles need to be set manually:
            - The lilypad user contract needs to grant the payment engine the CONTROLLER_ROLE
            - The lilypad storage contract needs to grant the payment engine the CONTROLLER_ROLE
     */
    function run() external returns (address) {
        address lilypadTokenAddress = vm.envAddress("L2_TOKEN_PROXY_ADDRESS");
        address lilypadStorageAddress = vm.envAddress("STORAGE_PROXY_ADDRESS");
        address lilypadUserAddress = vm.envAddress("LILYPAD_USER_PROXY_ADDRESS");
        address lilypadTokenomicsAddress = vm.envAddress("TOKENOMICS_PROXY_ADDRESS");
        address treasuryAddress = vm.envAddress("TREASURY_WALLET_ADDRESS");
        address valueRewardsAddress = vm.envAddress("REWARDS_WALLET_ADDRESS");
        address validationPoolAddress = vm.envAddress("VALIDATION_POOL_WALLET_ADDRESS");

        vm.startBroadcast();

        // Deploy contract
        address paymentEngineProxy = deployEngine(
            lilypadTokenAddress,
            lilypadStorageAddress,
            lilypadUserAddress,
            lilypadTokenomicsAddress,
            treasuryAddress,
            valueRewardsAddress,
            validationPoolAddress
        );

        vm.stopBroadcast();

        console.log("Payment Engine:", paymentEngineProxy);

        return paymentEngineProxy;
    }
}
