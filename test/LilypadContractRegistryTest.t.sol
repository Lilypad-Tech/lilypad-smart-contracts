// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {LilypadContractRegistry} from "../src/LilypadContractRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract LilypadContractRegistryTest is Test {
    LilypadContractRegistry public registry;
    LilypadContractRegistry public implementation;

    address public nonAdmin = address(2);

    // Mock contract addresses
    address public mockL1Token = address(10);
    address public mockL2Token = address(11);
    address public mockUser = address(12);
    address public mockModuleDirectory = address(13);
    address public mockStorage = address(14);
    address public mockPaymentEngine = address(15);
    address public mockProxy = address(16);
    address public mockVesting = address(17);

    // New mock addresses for updates
    address public newMockL2Token = address(21);
    address public newMockUser = address(22);
    address public newMockModuleDirectory = address(23);
    address public newMockStorage = address(24);
    address public newMockPaymentEngine = address(25);
    address public newMockProxy = address(26);
    address public newMockVesting = address(27);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Custom Errors
    error LilypadContractRegistryTest__NotController();

    event LilypadContractRegistry__ContractAddressSet(string name, address indexed contractAddress);

    function setUp() public {
        // Deploy implementation
        implementation = new LilypadContractRegistry();

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            LilypadContractRegistry.initialize.selector,
            mockL1Token,
            mockL2Token,
            mockUser,
            mockModuleDirectory,
            mockStorage,
            mockPaymentEngine,
            mockProxy,
            mockVesting
        );

        // Deploy proxy with implementation and initialization data
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Get registry instance from proxy
        registry = LilypadContractRegistry(address(proxy));
    }

    // Test initialization
    function test_Initialization() public {
        assertEq(registry.l1LilypadTokenAddress(), mockL1Token);
        assertEq(registry.l2LilypadTokenAddress(), mockL2Token);
        assertEq(registry.lilypadUserAddress(), mockUser);
        assertEq(registry.lilypadModuleDirectoryAddress(), mockModuleDirectory);
        assertEq(registry.lilypadStorageAddress(), mockStorage);
        assertEq(registry.lilypadPaymentEngineAddress(), mockPaymentEngine);
        assertEq(registry.lilypadProxyAddress(), mockProxy);
        assertEq(registry.lilypadVestingAddress(), mockVesting);
    }

    // Test setting L2 token address
    function test_SetL2LilypadTokenAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("L2 Lilypad Token", newMockL2Token);

        registry.setL2LilypadTokenAddress(newMockL2Token);
        assertEq(registry.l2LilypadTokenAddress(), newMockL2Token);

        vm.stopPrank();
    }

    // Test setting Lilypad User address
    function test_SetLilypadUserAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("Lilypad User", newMockUser);

        registry.setLilypadUserAddress(newMockUser);
        assertEq(registry.lilypadUserAddress(), newMockUser);

        vm.stopPrank();
    }

    // Test setting Lilypad Module Directory address
    function test_SetLilypadModuleDirectoryAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Module Directory", newMockModuleDirectory);

        registry.setLilypadModuleDirectoryAddress(newMockModuleDirectory);
        assertEq(registry.lilypadModuleDirectoryAddress(), newMockModuleDirectory);

        vm.stopPrank();
    }

    // Test setting Lilypad Storage address
    function test_SetLilypadStorageAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Storage", newMockStorage);

        registry.setLilypadStorageAddress(newMockStorage);
        assertEq(registry.lilypadStorageAddress(), newMockStorage);

        vm.stopPrank();
    }

    // Test setting Lilypad Payment Engine address
    function test_SetLilypadPaymentEngineAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Payment Engine", newMockPaymentEngine);

        registry.setLilypadPaymentEngineAddress(newMockPaymentEngine);
        assertEq(registry.lilypadPaymentEngineAddress(), newMockPaymentEngine);

        vm.stopPrank();
    }

    // Test setting Lilypad Proxy address
    function test_SetLilypadProxyAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Proxy", newMockProxy);

        registry.setLilypadProxyAddress(newMockProxy);
        assertEq(registry.lilypadProxyAddress(), newMockProxy);

        vm.stopPrank();
    }

    // Test setting Lilypad Vesting address
    function test_SetLilypadVestingAddress() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, false, true);
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Vesting", newMockVesting);

        registry.setLilypadVestingAddress(newMockVesting);
        assertEq(registry.lilypadVestingAddress(), newMockVesting);

        vm.stopPrank();
    }

    // Test access control - non-admin cannot set addresses
    function test_RevertWhen_NonAdminSetsAddresses() public {
        vm.startPrank(nonAdmin);

        bytes32 role = DEFAULT_ADMIN_ROLE;

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setL2LilypadTokenAddress(newMockL2Token);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setLilypadUserAddress(newMockUser);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setLilypadModuleDirectoryAddress(newMockModuleDirectory);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setLilypadStorageAddress(newMockStorage);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setLilypadPaymentEngineAddress(newMockPaymentEngine);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setLilypadProxyAddress(newMockProxy);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, role)
        );
        registry.setLilypadVestingAddress(newMockVesting);

        vm.stopPrank();
    }
}
