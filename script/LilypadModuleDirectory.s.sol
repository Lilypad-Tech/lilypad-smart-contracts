// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadModuleDirectory} from "../src/LilypadModuleDirectory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployLilypadModuleDirectory is Script {
    function run() external returns (address) {
        //Note: This is the address[0] from anvil only meant for testing
        //TODO: Change this to the address of the initial owner
        address initialOwner = vm.envAddress("INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN");

        //TODO: Add the actual address of the deployed lilypad user proxy contract here
        address lilypadUserProxyAddress = vm.envAddress("LILYPAD_USER_PROXY_ADDRESS");

        vm.startBroadcast();

        // 1. Encode the initialization data
        bytes memory initData =
            abi.encodeWithSelector(LilypadModuleDirectory.initialize.selector, lilypadUserProxyAddress);

        // 2. Deploy the proxy contract pointing to the implementation
        address proxy = Upgrades.deployTransparentProxy("LilypadModuleDirectory.sol", initialOwner, initData);

        vm.stopBroadcast();

        // Return the proxy address - this is the address users will interact with
        return address(proxy);
    }
}
