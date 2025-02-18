// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LilypadPaymentEngine} from "../src/LilypadPaymentEngine.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {LilypadStorage} from "../src/LilypadStorage.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLilypadPaymentEngine is Script {
    function deployToken() internal returns (LilypadToken) {
        // This is a test supply for test deployment purposes
        uint256 initialSupply = 10_000_000 * 10 ** 18;
        return new LilypadToken(initialSupply);
    }

    function deployStorage() internal returns (LilypadStorage, address) {
        LilypadStorage storageImpl = new LilypadStorage();
        bytes memory initData = abi.encodeWithSelector(LilypadStorage.initialize.selector);
        ERC1967Proxy proxy = new ERC1967Proxy(address(storageImpl), initData);
        return (LilypadStorage(address(proxy)), address(proxy));
    }

    function deployUser() internal returns (LilypadUser, address) {
        LilypadUser userImpl = new LilypadUser();
        bytes memory initData = abi.encodeWithSelector(LilypadUser.initialize.selector);
        ERC1967Proxy proxy = new ERC1967Proxy(address(userImpl), initData);
        return (LilypadUser(address(proxy)), address(proxy));
    }

    function deployEngine(
        address token,
        address storage_,
        address user_,
        address treasury,
        address rewards,
        address validationPool
    ) internal returns (LilypadPaymentEngine, address) {
        LilypadPaymentEngine engineImpl = new LilypadPaymentEngine();
        bytes memory initData = abi.encodeWithSelector(
            LilypadPaymentEngine.initialize.selector, token, storage_, user_, treasury, rewards, validationPool
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(engineImpl), initData);
        return (LilypadPaymentEngine(address(proxy)), address(proxy));
    }

    function run() external {
        // These are test wallets from anvil for testing purposes
        address treasuryWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address valueRewardsWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address validationPoolWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.startBroadcast();

        // Deploy contracts
        LilypadToken token = deployToken();
        (LilypadStorage lilypadStorage, address storageProxy) = deployStorage();
        (LilypadUser user, address userProxy) = deployUser();
        (LilypadPaymentEngine paymentEngine, address engineProxy) = deployEngine(
            address(token),
            address(lilypadStorage),
            address(user),
            treasuryWallet,
            valueRewardsWallet,
            validationPoolWallet
        );

        // Setup roles
        user.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));
        lilypadStorage.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));
        paymentEngine.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));

        console.log("Deployment Addresses:");
        console.log("Token:", address(token));
        console.log("Storage:", storageProxy);
        console.log("User:", userProxy);
        console.log("Payment Engine:", engineProxy);

        vm.stopBroadcast();
    }
}
