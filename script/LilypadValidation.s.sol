// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {LilypadValidation} from "../src/LilypadValidation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLilypadValidation is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        // 1. Deploy the implementation contract
        LilypadValidation implementation = new LilypadValidation();

        // 2. Encode the initialization data
        bytes memory initData = abi.encodeWithSelector(LilypadValidation.initialize.selector);

        // 3. Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        // Return the proxy address - this is the address users will interact with
        return address(proxy);
    }
}
