// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployLilypadUser is Script {
    function run() external returns (address) {
        //Note: This is the address[0] from anvil only meant for testing
        //TODO: Change this to the address of the initial owner
        address initialOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.startBroadcast();

        // 1. Deploy the implementation contract
        LilypadUser implementation = new LilypadUser();

        // 2. Encode the initialization data
        bytes memory initData = abi.encodeWithSelector(LilypadUser.initialize.selector);

        // 3. Deploy the proxy contract pointing to the implementation.  Take note of the proxy address that is returned as this will be the address users will interact with
        address proxy = Upgrades.deployTransparentProxy(
            "LilypadUser.sol",
            initialOwner,
            initData
        );

        vm.stopBroadcast();

        console.log("LilypadUser deployed at:", address(proxy));

        // Return the proxy address - this is the address users will interact with
        return address(proxy);
    }
}