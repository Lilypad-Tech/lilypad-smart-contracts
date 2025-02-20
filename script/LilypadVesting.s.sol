// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadVesting} from "../src/LilypadVesting.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {SharedStructs} from "../src/SharedStructs.sol";

contract DeployLilypadVesting is Script {
    function deployToken() internal returns (LilypadToken) {
        uint256 initialSupply = 10_000_000 * 10 ** 18;
        return new LilypadToken(initialSupply);
    }

    function run() external {
        vm.startBroadcast();

        // Deploy contracts

        // Note: This token deployment here is for testing purposes.  The actual token deployment will be done on the L1 chain and the address that will be passed into the vesting contract will be the address of the token on the L2 chain.
        LilypadToken token = deployToken();
        LilypadVesting vestingContract = new LilypadVesting(address(token));

        // Setup roles
        token.grantRole(SharedStructs.CONTROLLER_ROLE, address(vestingContract));
        vestingContract.grantRole(SharedStructs.VESTING_ROLE, address(vestingContract));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nDeployment Summary:");
        console.log("------------------");
        console.log("LilypadToken:", address(token));
        console.log("LilypadVesting:", address(vestingContract));
    }
}
