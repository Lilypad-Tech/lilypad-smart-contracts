// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadVesting} from "../src/LilypadVesting.sol";

contract DeployLilypadVesting is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        /**
         * Note: This contract is to be deployed on the L2 chain
         *       - The Lilypad token will be deployed on the L1 chain and the bridged to L2 which will result in a parallel token on that chain
         *       - The address of the L2 token will be passed into the constructor of this contract
         *       - If testsing locally via anvil, you can deploy the LilypadToken first and then save that address into the L2_TOKEN_ADDRESS environment variable
         */
        address lilypadL2TokenAddress = vm.envAddress("L2_TOKEN_ADDRESS");
        LilypadVesting vestingContract = new LilypadVesting(lilypadL2TokenAddress);

        vm.stopBroadcast();

        console.log("LilypadVesting deployed at:", address(vestingContract));

        return address(vestingContract);
    }
}
