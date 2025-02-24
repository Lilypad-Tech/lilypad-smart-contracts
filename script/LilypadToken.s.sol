// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadToken} from "../src/LilypadToken.sol";

contract DeployLilypadToken is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        uint256 initialSupply = 167_500_000 * 10 ** 18;
        LilypadToken implementation = new LilypadToken(initialSupply);

        vm.stopBroadcast();

        console.log("LilypadToken deployed at:", address(implementation));

        return address(implementation);
    }
}
