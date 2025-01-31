// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/LilypadVesting.sol";
import "../src/LilypadToken.sol";
import {SharedStructs} from "../src/SharedStructs.sol";

contract DeployLilypadVesting is Script {
    function deployToken() internal returns (LilypadToken) {
        uint256 initialSupply = 10_000_000 * 10 ** 18;
        return new LilypadToken(initialSupply);
    }

    function run() external {
        vm.startBroadcast();

        // Deploy contracts
        // NOTE: This is a temporary token for testing purposes, when we have a real token, we should use that instead
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
