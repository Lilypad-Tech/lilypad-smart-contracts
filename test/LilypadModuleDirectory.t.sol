// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LilypadModuleDirectory} from "../src/LilypadModuleDirectory.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LilypadModuleDirectoryTest is Test {
    LilypadModuleDirectory public moduleDirectory;
    LilypadUser public lilypadUser;
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant CONTROLLER = address(0x3);
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Events
    event LilypadModuleDirectory__ModuleRegistered(address indexed owner, string moduleName, string moduleUrl);
    event LilypadModuleDirectory__ModuleNameUpdated(address indexed owner, string oldModuleName, string newModuleName);
    event LilypadModuleDirectory__ModuleUrlUpdated(address indexed owner, string moduleName, string newModuleUrl);
    event LilypadModuleDirectory__ModuleTransferApproved(
        address indexed owner, address indexed purchaser, string moduleName, string moduleUrl
    );
    event LilypadModuleDirectory__ModuleTransferred(
        address indexed newOwner, address indexed previousOwner, string moduleName, string moduleUrl
    );
    event LilypadModuleDirectory__ModuleTransferRevoked(
        address indexed owner, address indexed revokedFrom, string moduleName
    );
    event LilypadModuleDirectory__ControllerRoleGranted(address indexed controller, address indexed grantedBy);
    event LilypadModuleDirectory__ControllerRoleRevoked(address indexed controller, address indexed revokedBy);
    event LilypadModuleDirectory__ModuleCreatorRegistered(address indexed creator);
    event LilypadModuleDirectory__LilypadUserUpdated(address indexed lilypadUser, address indexed caller);

    function setUp() public {
        // Deploy lilypadUser
        lilypadUser = new LilypadUser();
        lilypadUser.initialize();

        // Deploy implementation
        LilypadModuleDirectory implementation = new LilypadModuleDirectory();

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(LilypadModuleDirectory.initialize.selector, address(lilypadUser));

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to LilypadModuleDirectory
        moduleDirectory = LilypadModuleDirectory(address(proxy));

        // Grant controller role to CONTROLLER address
        moduleDirectory.grantRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER);
        lilypadUser.grantRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER);
        lilypadUser.grantRole(SharedStructs.CONTROLLER_ROLE, address(moduleDirectory));
    }

    // Version Tests
    function test_InitialVersion() public view {
        assertEq(moduleDirectory.version(), "1.0.0");
    }

    function test_GetVersion() public view {
        assertEq(moduleDirectory.getVersion(), "1.0.0");
    }

    function test_InitialRoles() public view {
        assertTrue(moduleDirectory.hasRole(DEFAULT_ADMIN_ROLE, address(this)));
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER));
    }

    function test_HasControllerRole() public {
        // Test initial controller roles
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER));
        assertFalse(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, ALICE));

        // Test after granting role
        moduleDirectory.grantRole(SharedStructs.CONTROLLER_ROLE, ALICE);
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, ALICE));

        // Test after revoking role
        moduleDirectory.revokeRole(SharedStructs.CONTROLLER_ROLE, ALICE);
        assertFalse(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, ALICE));
    }

    // Revoke Role
    function test_GrantAndRevokeControllerRole() public {
        address newController = address(0x4);

        // Test zero address revert
        vm.startPrank(address(this));

        // Test granting role
        vm.expectEmit(true, true, true, true);
        emit IAccessControl.RoleGranted(SharedStructs.CONTROLLER_ROLE, newController, address(this));
        moduleDirectory.grantRole(SharedStructs.CONTROLLER_ROLE, newController);
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, newController));

        // Test already assigned role
        moduleDirectory.grantRole(SharedStructs.CONTROLLER_ROLE, newController);
        assertTrue(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, newController));

        // Test new controller can register
        vm.startPrank(newController);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        // Test revoking role
        vm.startPrank(address(this));
        vm.expectEmit(true, true, true, true);
        emit IAccessControl.RoleRevoked(SharedStructs.CONTROLLER_ROLE, newController, address(this));
        moduleDirectory.revokeRole(SharedStructs.CONTROLLER_ROLE, newController);
        assertFalse(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, newController));

        // Test revoking non-existent role
        moduleDirectory.revokeRole(SharedStructs.CONTROLLER_ROLE, newController);
        assertFalse(moduleDirectory.hasRole(SharedStructs.CONTROLLER_ROLE, newController));

        // Test revoked controller cannot register
        vm.startPrank(newController);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__NotController.selector);
        moduleDirectory.registerModuleForCreator(ALICE, "module2", "url2");
    }

    // Module Registration Tests
    function test_RevertWhen_NonControllerRegistersModule() public {
        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__NotController.selector);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");
    }

    function test_SetLilypadUser() public {
        vm.startPrank(address(this));
        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__LilypadUserUpdated(address(lilypadUser), address(this));
        moduleDirectory.setLilypadUser(address(lilypadUser));
        vm.stopPrank();
    }

    function test_SetLilypadUser_Reverts_WhenZeroAddress() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__ZeroAddressNotAllowed.selector);
        moduleDirectory.setLilypadUser(address(0));
        vm.stopPrank();
    }

    function test_RegisterAndGetModule() public {
        vm.startPrank(CONTROLLER);

        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleRegistered(ALICE, "module1", "url1");

        bool success = moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");
        assertTrue(success);
        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(ALICE);

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleOwner, ALICE);
        assertEq(modules[0].moduleName, "module1");
        assertEq(modules[0].moduleUrl, "url1");
    }

    // Long String Tests
    function test_ModuleWithLongStrings() public {
        string memory longModuleName = "ThisIsAVeryLongModuleNameThatShouldStillWorkFineWithTheContract";
        string memory longUrl =
            "https://this-is-a-very-long-url-that-should-still-work-fine-with-the-contract.com/some/very/long/path";

        vm.startPrank(CONTROLLER);
        bool success = moduleDirectory.registerModuleForCreator(ALICE, longModuleName, longUrl);
        assertTrue(success);

        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(ALICE);
        assertEq(modules[0].moduleName, longModuleName);
        assertEq(modules[0].moduleUrl, longUrl);
    }

    function test_RegisterModulesWithDifferentCasing() public {
        vm.startPrank(CONTROLLER);

        // Register the first module with name "Module1"
        bool success1 = moduleDirectory.registerModuleForCreator(ALICE, "Module1", "url1");
        assertTrue(success1);

        // Register the second module with name "module1" (different casing)
        bool success2 = moduleDirectory.registerModuleForCreator(ALICE, "module1", "url2");
        assertTrue(success2);

        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(ALICE);

        // Assert that both modules are registered
        assertEq(modules.length, 2);
        assertEq(modules[0].moduleName, "Module1");
        assertEq(modules[1].moduleName, "module1");
    }

    // Multiple Modules Tests
    function test_MultipleModulesForSameOwner() public {
        vm.startPrank(CONTROLLER);

        // Register multiple modules
        string[3] memory moduleNames = ["module1", "module2", "module3"];
        string[3] memory urls = ["url1", "url2", "url3"];

        for (uint256 i = 0; i < moduleNames.length; i++) {
            bool success = moduleDirectory.registerModuleForCreator(ALICE, moduleNames[i], urls[i]);
            assertTrue(success);
        }

        // Verify all modules
        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(ALICE);
        assertEq(modules.length, 3);

        for (uint256 i = 0; i < modules.length; i++) {
            assertEq(modules[i].moduleOwner, ALICE);
            assertEq(modules[i].moduleName, moduleNames[i]);
            assertEq(modules[i].moduleUrl, urls[i]);
        }
    }

    function test_ModuleRegistrationWithNewModuleCreatorBeingCreated() public {
        vm.startPrank(CONTROLLER);

        vm.expectRevert(LilypadUser.LilypadUser__UserNotFound.selector);
        lilypadUser.getUser(BOB);

        moduleDirectory.registerModuleForCreator(BOB, "module1", "url1");

        SharedStructs.User memory user = lilypadUser.getUser(BOB);
        assertEq(user.userAddress, BOB);
        assertTrue(lilypadUser.hasRole(BOB, SharedStructs.UserType.ModuleCreator));
        assertEq(user.metadataID, "");
        assertEq(user.url, "");

        vm.stopPrank();
    }

    // Module Update Tests
    function test_UpdateModuleName() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleNameUpdated(ALICE, "module1", "newModule1");

        bool success = moduleDirectory.updateModuleName(ALICE, "module1", "newModule1");
        assertTrue(success);

        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(ALICE);
        assertEq(modules[0].moduleName, "newModule1");
    }

    function test_UpdateModuleUrl() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleUrlUpdated(ALICE, "module1", "newUrl1");

        bool success = moduleDirectory.updateModuleUrl(ALICE, "module1", "newUrl1");
        assertTrue(success);

        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(ALICE);
        assertEq(modules[0].moduleUrl, "newUrl1");
    }

    // Module Transfer Tests
    function test_ApproveAndTransferModule() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleTransferApproved(ALICE, BOB, "module1", "url1");

        bool approvalSuccess = moduleDirectory.approveTransfer(ALICE, BOB, "module1", "url1");
        assertTrue(approvalSuccess);
        assertTrue(moduleDirectory.isTransferApproved(ALICE, "module1", BOB));

        bool transferSuccess = moduleDirectory.transferModuleOwnership(ALICE, BOB, "module1", "url1");
        assertTrue(transferSuccess);

        SharedStructs.Module[] memory aliceModules = moduleDirectory.getOwnedModules(ALICE);
        SharedStructs.Module[] memory bobModules = moduleDirectory.getOwnedModules(BOB);

        assertEq(aliceModules.length, 0);
        assertEq(bobModules.length, 1);
        assertEq(bobModules[0].moduleOwner, BOB);
        assertEq(bobModules[0].moduleName, "module1");
    }

    function test_IsTransferApproved() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        assertFalse(moduleDirectory.isTransferApproved(ALICE, "module1", BOB));

        vm.startPrank(ALICE);
        moduleDirectory.approveTransfer(ALICE, BOB, "module1", "url1");
        assertTrue(moduleDirectory.isTransferApproved(ALICE, "module1", BOB));

        moduleDirectory.revokeTransferApproval(ALICE, "module1");
        assertFalse(moduleDirectory.isTransferApproved(ALICE, "module1", BOB));
    }

    function test_RevokeTransferApproval() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        moduleDirectory.approveTransfer(ALICE, BOB, "module1", "url1");

        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleTransferRevoked(ALICE, BOB, "module1");

        bool success = moduleDirectory.revokeTransferApproval(ALICE, "module1");
        assertTrue(success);
        assertFalse(moduleDirectory.isTransferApproved(ALICE, "module1", BOB));
    }

    // Error Tests UpdateModuleName
    function test_RevertWhen_UpdatingNonexistentModule() public {
        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__ModuleNotFound.selector);
        moduleDirectory.updateModuleName(ALICE, "nonexistent", "newName");
    }

    function test_RevertWhen_NonOwnerUpdatesModule() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(BOB);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__NotModuleOwner.selector);
        moduleDirectory.updateModuleName(ALICE, "module1", "newName");
    }

    function test_RevertWhen_UpdatingToExistingModuleName() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");
        moduleDirectory.registerModuleForCreator(ALICE, "module2", "url2");

        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__ModuleAlreadyExists.selector);
        moduleDirectory.updateModuleName(ALICE, "module1", "module2");
    }

    // Error Tests UpdateModuleUrl
    function test_RevertWhen_UpdatingModuleUrlWithEmptyString() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__EmptyModuleUrl.selector);
        moduleDirectory.updateModuleUrl(ALICE, "module1", "");
    }

    // Error Tests RegisterModuleForCreator
    function test_RevertWhen_RegisteringWithEmptyModuleName() public {
        vm.startPrank(CONTROLLER);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__EmptyModuleName.selector);
        moduleDirectory.registerModuleForCreator(ALICE, "", "url1");
    }

    function test_RevertWhen_RegisteringWithZeroAddress() public {
        vm.startPrank(CONTROLLER);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__InvalidAddress.selector);
        moduleDirectory.registerModuleForCreator(address(0), "module1", "url1");
    }

    // Error Tests ApproveTransfer
    function test_RevertWhen_ApprovingTransferToZeroAddress() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__InvalidAddress.selector);
        moduleDirectory.approveTransfer(ALICE, address(0), "module1", "url1");
    }

    function test_RevertWhen_ApprovingTransferToSameOwner() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__SameOwnerAddress.selector);
        moduleDirectory.approveTransfer(ALICE, ALICE, "module1", "url1");
    }

    function test_RevertWhen_TransferringToAddressWithSameModuleName() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");
        moduleDirectory.registerModuleForCreator(BOB, "module1", "url2");

        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__ModuleAlreadyExists.selector);
        moduleDirectory.approveTransfer(ALICE, BOB, "module1", "url1");
    }

    // Error Tests TransferModuleOwnership
    function test_RevertWhen_TransferringWithoutApproval() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(BOB);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__TransferNotApproved.selector);
        moduleDirectory.transferModuleOwnership(ALICE, BOB, "module1", "url1");
    }

    function test_RevertWhen_TransferringNonExistentModule() public {
        vm.startPrank(ALICE);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__ModuleNotFound.selector);
        moduleDirectory.transferModuleOwnership(ALICE, BOB, "nonexistent", "url1");
    }

    // Error Tests RevokeTransferApproval
    function test_RevokeNonExistentTransferApproval() public {
        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "url1");

        vm.startPrank(ALICE);
        bool success = moduleDirectory.revokeTransferApproval(ALICE, "module1");
        assertTrue(success);
    }

    // Module Creator Registration Tests
    function test_RegisterModuleCreator() public {
        address creator = address(0x123);

        vm.startPrank(CONTROLLER);

        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleCreatorRegistered(creator);

        bool success = moduleDirectory.registerModuleCreator(creator);
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(creator);
        assertEq(user.userAddress, creator);
        assertTrue(lilypadUser.hasRole(creator, SharedStructs.UserType.ModuleCreator));

        vm.stopPrank();
    }

    function test_RegisterModuleCreatorWithExistingUserThatHoldsADifferentRole() public {
        address creator = address(0x123);

        vm.startPrank(CONTROLLER);
        lilypadUser.insertUser(creator, "", "", SharedStructs.UserType.ResourceProvider);

        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleCreatorRegistered(creator);

        bool success = moduleDirectory.registerModuleCreator(creator);
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(creator);
        assertEq(user.userAddress, creator);
        assertTrue(lilypadUser.hasRole(creator, SharedStructs.UserType.ModuleCreator));
        assertTrue(lilypadUser.hasRole(creator, SharedStructs.UserType.ResourceProvider));

        vm.stopPrank();
    }

    function test_RevertWhen_RegisteringZeroAddress() public {
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__InvalidAddress.selector);
        moduleDirectory.registerModuleCreator(address(0));
    }

    function test_RegisterModuleCreatorWithExistingUser() public {
        address newUser = address(0x123);

        vm.startPrank(CONTROLLER);
        lilypadUser.insertUser(newUser, "", "", SharedStructs.UserType.ModuleCreator);

        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadModuleDirectory.LilypadModuleDirectory__ModuleCreatorAlreadyExists.selector, newUser
            )
        );
        moduleDirectory.registerModuleCreator(newUser);

        vm.stopPrank();
    }

    function testFuzz_RegisterModuleCreator(address creator) public {
        vm.assume(creator != address(0));

        vm.startPrank(CONTROLLER);

        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleCreatorRegistered(creator);

        bool success = moduleDirectory.registerModuleCreator(creator);
        assertTrue(success);

        // Verify the user exists and has the correct role
        SharedStructs.User memory user = lilypadUser.getUser(creator);
        assertEq(user.userAddress, creator);
        assertTrue(lilypadUser.hasRole(creator, SharedStructs.UserType.ModuleCreator));

        vm.stopPrank();
    }

    function testFuzz_RevertWhen_RegisteringDuplicateModuleCreator(address creator) public {
        vm.assume(creator != address(0));

        vm.startPrank(CONTROLLER);
        // First registration
        moduleDirectory.registerModuleCreator(creator);

        // Second registration should fail
        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadModuleDirectory.LilypadModuleDirectory__ModuleCreatorAlreadyExists.selector, creator
            )
        );
        moduleDirectory.registerModuleCreator(creator);
        vm.stopPrank();
    }

    // Fuzz Tests
    function testFuzz_RegisterAndGetModule(address owner, uint8 moduleNameSeed, uint8 moduleUrlSeed) public {
        vm.assume(owner != address(0));

        string memory moduleName = string(abi.encodePacked("module_", uint8(moduleNameSeed % 26 + 65)));
        string memory moduleUrl = string(abi.encodePacked("url_", uint8(moduleUrlSeed % 26 + 65)));

        vm.startPrank(CONTROLLER);

        vm.expectEmit(true, true, true, true);
        emit LilypadModuleDirectory__ModuleRegistered(owner, moduleName, moduleUrl);

        bool success = moduleDirectory.registerModuleForCreator(owner, moduleName, moduleUrl);
        assertTrue(success);
        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(owner);

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleOwner, owner);
        assertEq(modules[0].moduleName, moduleName);
        assertEq(modules[0].moduleUrl, moduleUrl);
    }

    function testFuzz_UpdateModuleUrl(address owner, uint8 moduleNameSeed, uint8 oldUrlSeed, uint8 newUrlSeed) public {
        vm.assume(owner != address(0));

        string memory moduleName = string(abi.encodePacked("module_", uint8(moduleNameSeed % 26 + 65)));
        string memory oldUrl = string(abi.encodePacked("url_", uint8(oldUrlSeed % 26 + 65)));
        string memory newUrl = string(abi.encodePacked("url_", uint8(newUrlSeed % 26 + 65)));

        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(owner, moduleName, oldUrl);

        vm.startPrank(owner);
        bool success = moduleDirectory.updateModuleUrl(owner, moduleName, newUrl);
        assertTrue(success);

        SharedStructs.Module[] memory modules = moduleDirectory.getOwnedModules(owner);
        assertEq(modules[0].moduleUrl, newUrl);
    }

    function testFuzz_TransferModule(address originalOwner, address newOwner, uint8 moduleNameSeed, uint8 moduleUrlSeed)
        public
    {
        vm.assume(originalOwner != address(0));
        vm.assume(newOwner != address(0));
        vm.assume(originalOwner != newOwner);

        string memory moduleName = string(abi.encodePacked("module_", uint8(moduleNameSeed % 26 + 65)));
        string memory moduleUrl = string(abi.encodePacked("url_", uint8(moduleUrlSeed % 26 + 65)));

        vm.startPrank(CONTROLLER);
        moduleDirectory.registerModuleForCreator(originalOwner, moduleName, moduleUrl);

        vm.startPrank(originalOwner);
        moduleDirectory.approveTransfer(originalOwner, newOwner, moduleName, moduleUrl);

        bool success = moduleDirectory.transferModuleOwnership(originalOwner, newOwner, moduleName, moduleUrl);
        assertTrue(success);

        SharedStructs.Module[] memory newOwnerModules = moduleDirectory.getOwnedModules(newOwner);
        assertEq(newOwnerModules[0].moduleOwner, newOwner);
        assertEq(newOwnerModules[0].moduleName, moduleName);
        assertEq(newOwnerModules[0].moduleUrl, moduleUrl);
    }

    function test_RevertWhen_RegisteringWithEmptyModuleUrl() public {
        vm.startPrank(CONTROLLER);
        vm.expectRevert(LilypadModuleDirectory.LilypadModuleDirectory__EmptyModuleUrl.selector);
        moduleDirectory.registerModuleForCreator(ALICE, "module1", "");
    }
}
