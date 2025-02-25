// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadContractRegistry} from "../src/LilypadContractRegistry.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployLilypadContractRegistry is Script {
    function run() external returns (address) {
        // Get initial owner address from environment
        address initialOwner = vm.envAddress("INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN");

        // Get contract addresses from environment
        address l1TokenAddress = vm.envAddress("L1_TOKEN_ADDRESS");
        address l2TokenAddress = vm.envAddress("L2_TOKEN_PROXY_ADDRESS");
        address userAddress = vm.envAddress("USER_PROXY_ADDRESS");
        address moduleDirectoryAddress = vm.envAddress("MODULE_DIRECTORY_PROXY_ADDRESS");
        address storageAddress = vm.envAddress("STORAGE_PROXY_ADDRESS");
        address paymentEngineAddress = vm.envAddress("PAYMENT_ENGINE_PROXY_ADDRESS");
        address proxyAddress = vm.envAddress("LILYPAD_PROXY_ADDRESS");
        address vestingAddress = vm.envAddress("VESTING_PROXY_ADDRESS");

        vm.startBroadcast();

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            LilypadContractRegistry.initialize.selector,
            l1TokenAddress,
            l2TokenAddress,
            userAddress,
            moduleDirectoryAddress,
            storageAddress,
            paymentEngineAddress,
            proxyAddress,
            vestingAddress
        );

        // Deploy proxy contract pointing to implementation
        address proxy = Upgrades.deployTransparentProxy("LilypadContractRegistry.sol", initialOwner, initData);

        vm.stopBroadcast();

        console.log("LilypadContractRegistry deployed at:", proxy);
        console.log("L1 Token Address:", l1TokenAddress);
        console.log("L2 Token Address:", l2TokenAddress);
        console.log("User Address:", userAddress);
        console.log("Module Directory Address:", moduleDirectoryAddress);
        console.log("Storage Address:", storageAddress);
        console.log("Payment Engine Address:", paymentEngineAddress);
        console.log("Lilypad Proxy Address:", proxyAddress);
        console.log("Vesting Address:", vestingAddress);

        return proxy;
    }
}
