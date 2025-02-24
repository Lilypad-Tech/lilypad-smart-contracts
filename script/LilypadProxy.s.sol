//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {LilypadProxy} from "../src/LilypadProxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {console} from "forge-std/console.sol";

contract DeployLilypadProxy is Script {
    /**
     * Note: Once the proxy is deployed, the roles need to be set manually:
     *         - The lilypad user contract needs to grant the proxy the CONTROLLER_ROLE
     *         - The lilypad storage contract needs to grant the proxy the CONTROLLER_ROLE
     *         - The payment engine needs to grant the proxy the CONTROLLER_ROLE
     */
    function run() external returns (address) {
        // Note: This is the address[0] from anvil only meant for testing
        // TODO: Change this to the address of the initial owner
        address initialOwner = vm.envAddress("INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN");

        address lilypadTokenAddress = vm.envAddress("L2_TOKEN_PROXY_ADDRESS");
        address lilypadStorageAddress = vm.envAddress("STORAGE_PROXY_ADDRESS");
        address lilypadUserAddress = vm.envAddress("LILYPAD_USER_PROXY_ADDRESS");
        address lilypadPaymentEngineAddress = vm.envAddress("PAYMENT_ENGINE_PROXY_ADDRESS");

        vm.startBroadcast();

        // Deploy contract
        bytes memory initData = abi.encodeWithSelector(
            LilypadProxy.initialize.selector,
            lilypadStorageAddress,
            lilypadPaymentEngineAddress,
            lilypadUserAddress,
            lilypadTokenAddress
        );

        address proxyProxy = Upgrades.deployTransparentProxy("LilypadProxy.sol", initialOwner, initData);

        vm.stopBroadcast();

        console.log("Lilypad Proxy:", proxyProxy);

        return proxyProxy;
    }
}
