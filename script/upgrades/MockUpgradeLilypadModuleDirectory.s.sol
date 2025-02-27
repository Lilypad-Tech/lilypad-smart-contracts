//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {LilypadModuleDirectory} from "../../src/LilypadModuleDirectory.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

/**
 * @notice This is a mock script that can theotically be used to upgrade the LilypadModuleDirectory contract to a new implementation.
 * @dev This script is only meant for auditors to assess the correctness of the upgrade process.
 */
contract MockUpgradeLilypadModuleDirectory is Script {
    function run() external {
        address LilypadModuleDirectoryProxy = vm.envAddress("MODULE_DIRECTORY_PROXY_ADDRESS");

        vm.startBroadcast();

        // 1. Declare the reference to the original proxy contract
        Options memory opts;
        opts.referenceContract = "LilypadModuleDirectory.sol";

        // 2. Upgrade the proxy to the new implementation
        /* Note: LilypadModuleDirectoryV2 does not currently exist in the codebase but the idea would be to create a v2 folder inside of src
                and then create a LilypadModuleDirectoryV2.sol file that has the new implementation.
        **/
        Upgrades.upgradeProxy(LilypadModuleDirectoryProxy, "LilypadModuleDirectoryV2.sol", "", opts);

        vm.stopBroadcast();
    }
}
