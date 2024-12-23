// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {LilypadToken} from "../src/LilypadToken.sol";

contract DeployLilypadToken is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        // TODO: Change this to the actual initial supply once we have it
        uint256 initialSupply = 1_670_000 * 10**18;
        LilypadToken implementation = new LilypadToken(initialSupply);

        vm.stopBroadcast();

        return address(implementation);
    }
}
