// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadTokenomics} from "../src/LilypadTokenomics.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLilypadTokenomics is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        // 1. Deploy the implementation contract
        LilypadTokenomics implementation = new LilypadTokenomics();

        // 2. Encode the initialization data
        bytes memory initData = abi.encodeWithSelector(LilypadTokenomics.initialize.selector);

        // 3. Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        // Return the proxy address - this is the address users will interact with
        return address(proxy);
    }
}
