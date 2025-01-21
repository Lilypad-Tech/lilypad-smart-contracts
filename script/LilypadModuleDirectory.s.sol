// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {LilypadModuleDirectory} from "../src/LilypadModuleDirectory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLilypadModuleDirectory is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        // 1. Deploy the implementation contract
        LilypadModuleDirectory implementation = new LilypadModuleDirectory();

        // 2. Encode the initialization data
        bytes memory initData = abi.encodeWithSelector(LilypadModuleDirectory.initialize.selector);

        // 3. Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        // Return the proxy address - this is the address users will interact with
        return address(proxy);
    }
}
