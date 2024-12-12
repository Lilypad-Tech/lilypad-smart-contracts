// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";

contract LilypadUserTest is Test {
    LilypadUser public lilypadUser;
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);

    event UserManagementEvent(address walletAddress, string metadataID, string url, SharedStructs.UserType role);

    function setUp() public {
        lilypadUser = new LilypadUser();
        lilypadUser.initialize();
    }

    // Unit Tests
    function test_InsertUser() public {
        vm.expectEmit(true, true, true, true);
        emit UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        bool success =
            lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(ALICE);
        assertEq(user.userAddress, ALICE);
        assertEq(user.metadataID, "metadata1");
        assertEq(user.url, "http://example.com");
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
    }

    function test_RevertWhen_InsertingExistingUser() public {
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectRevert(LilypadUser.UserAlreadyExists.selector);
        lilypadUser.insertUser(ALICE, "metadata2", "http://example2.com", SharedStructs.UserType.JobCreator);
    }

    function test_updateUserMetadata() public {
        vm.expectEmit(true, true, true, true);
        emit UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        bool success = lilypadUser.updateUserMetadata(ALICE, "metadata2", "http://updated.com");
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(ALICE);
        assertEq(user.metadataID, "metadata2");
        assertEq(user.url, "http://updated.com");
    }

    function test_RevertWhen_UpdatingNonexistentUser() public {
        vm.expectRevert(LilypadUser.UserNotFound.selector);
        lilypadUser.updateUserMetadata(ALICE, "metadata1", "http://example.com");
    }

    function test_AddRole() public {
        // First insert a user
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectEmit(true, true, true, true);
        emit UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ModuleCreator);

        bool success = lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);
        assertTrue(success);
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ModuleCreator));
        // Verify original role is still there
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
    }

    function test_RevertWhen_AddingRoleToNonexistentUser() public {
        vm.expectRevert(LilypadUser.UserNotFound.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Admin);
    }

    function test_RevertWhen_AddingIncompatibleRole() public {
        // First insert user as JobCreator
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        // Try to add ResourceProvider role - should fail
        vm.expectRevert(LilypadUser.RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ResourceProvider);
    }

    function test_RevertWhen_JobCreatorAddsResourceProviderRole() public {
        // First insert user as JobCreator
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectRevert(LilypadUser.RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ResourceProvider);
    }

    function test_RevertWhen_ResourceProviderAddsJobCreatorRole() public {
        // First insert user as ResourceProvider
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ResourceProvider);

        vm.expectRevert(LilypadUser.RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.JobCreator);
    }

    function test_RemoveRole() public {
        // First insert a user with multiple roles
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);

        vm.expectEmit(true, true, true, true);
        emit UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ModuleCreator);

        bool success = lilypadUser.removeRole(ALICE, SharedStructs.UserType.ModuleCreator);
        assertTrue(success);
        assertFalse(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ModuleCreator));
        // Verify original role is still there
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
    }

    function test_RemoveLastRole() public {
        // Insert user with single role
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectEmit(true, true, true, true);
        emit UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        bool success = lilypadUser.removeRole(ALICE, SharedStructs.UserType.JobCreator);
        assertTrue(success);
        assertFalse(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
    }

    function test_RevertWhen_RemovingRoleFromNonexistentUser() public {
        vm.expectRevert(LilypadUser.UserNotFound.selector);
        lilypadUser.removeRole(ALICE, SharedStructs.UserType.Admin);
    }

    function test_RevertWhen_RemovingNonexistentRole() public {
        // First insert user with JobCreator role
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectRevert(LilypadUser.RoleNotFound.selector);
        lilypadUser.removeRole(ALICE, SharedStructs.UserType.Admin);
    }

    // Fuzz Tests
    function testFuzz_InsertUser(address walletAddress, string memory metadataID, string memory url) public {
        vm.assume(walletAddress != address(0));

        bool success = lilypadUser.insertUser(walletAddress, metadataID, url, SharedStructs.UserType.JobCreator);
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(walletAddress);
        assertEq(user.userAddress, walletAddress);
        assertEq(user.metadataID, metadataID);
        assertEq(user.url, url);
    }

    function testFuzz_updateUserMetadata(
        address walletAddress,
        string memory initialMetadata,
        string memory initialUrl,
        string memory newMetadata,
        string memory newUrl
    ) public {
        vm.assume(walletAddress != address(0));

        // First insert
        lilypadUser.insertUser(walletAddress, initialMetadata, initialUrl, SharedStructs.UserType.JobCreator);

        // Then update
        bool success = lilypadUser.updateUserMetadata(walletAddress, newMetadata, newUrl);
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(walletAddress);
        assertEq(user.metadataID, newMetadata);
        assertEq(user.url, newUrl);
    }

    function testFuzz_AddRole(
        address walletAddress,
        string memory metadataID,
        string memory url,
        uint8 _initialRole,
        uint8 _newRole
    ) public {
        vm.assume(walletAddress != address(0));

        // Bound the enum values to valid ranges (assuming 6 roles: JobCreator, ResourceProvider, ModuleCreator, Admin, Solver, Validator)
        SharedStructs.UserType initialRole = SharedStructs.UserType(_initialRole % 6);
        SharedStructs.UserType newRole = SharedStructs.UserType(_newRole % 6);

        // Skip test if trying to add incompatible roles
        if (
            (initialRole == SharedStructs.UserType.JobCreator && newRole == SharedStructs.UserType.ResourceProvider)
                || (initialRole == SharedStructs.UserType.ResourceProvider && newRole == SharedStructs.UserType.JobCreator)
        ) {
            return;
        }

        // First insert user
        lilypadUser.insertUser(walletAddress, metadataID, url, initialRole);

        // Try to add new role
        bool success = lilypadUser.addRole(walletAddress, newRole);
        assertTrue(success);

        // Verify both roles
        assertTrue(lilypadUser.hasRole(walletAddress, initialRole));
        assertTrue(lilypadUser.hasRole(walletAddress, newRole));
    }

    function testFuzz_AddRoleReverts(address walletAddress, string memory metadataID, string memory url) public {
        vm.assume(walletAddress != address(0));

        // Insert as JobCreator
        lilypadUser.insertUser(walletAddress, metadataID, url, SharedStructs.UserType.JobCreator);

        // Should revert when trying to add ResourceProvider
        vm.expectRevert(LilypadUser.RoleNotAllowed.selector);
        lilypadUser.addRole(walletAddress, SharedStructs.UserType.ResourceProvider);
    }

    function testFuzz_RemoveRole(
        address walletAddress,
        string memory metadataID,
        string memory url,
        uint8 _initialRole,
        uint8 _additionalRole
    ) public {
        vm.assume(walletAddress != address(0));

        // Bound the enum values to valid ranges (assuming 6 roles: JobCreator, ResourceProvider, ModuleCreator, Admin, Solver, Validator)
        SharedStructs.UserType initialRole = SharedStructs.UserType(_initialRole % 6);
        SharedStructs.UserType additionalRole = SharedStructs.UserType(_additionalRole % 6);

        // Skip test if roles would be incompatible
        if (
            (
                initialRole == SharedStructs.UserType.JobCreator
                    && additionalRole == SharedStructs.UserType.ResourceProvider
            )
                || (
                    initialRole == SharedStructs.UserType.ResourceProvider
                        && additionalRole == SharedStructs.UserType.JobCreator
                )
        ) {
            return;
        }

        // Insert user with initial role
        lilypadUser.insertUser(walletAddress, metadataID, url, initialRole);

        // Only proceed with removal if we successfully added the role
        if (initialRole != additionalRole) {
            try lilypadUser.addRole(walletAddress, additionalRole) {
                bool success = lilypadUser.removeRole(walletAddress, additionalRole);
                assertTrue(success);
                assertFalse(lilypadUser.hasRole(walletAddress, additionalRole));
                assertTrue(lilypadUser.hasRole(walletAddress, initialRole));
            } catch {
                // If adding role failed, test removing the initial role instead
                bool success = lilypadUser.removeRole(walletAddress, initialRole);
                assertTrue(success);
                assertFalse(lilypadUser.hasRole(walletAddress, initialRole));
            }
        } else {
            // If roles are the same, just remove the initial role
            bool success = lilypadUser.removeRole(walletAddress, initialRole);
            assertTrue(success);
            assertFalse(lilypadUser.hasRole(walletAddress, initialRole));
        }
    }

    function testFuzz_RemoveRoleReverts(address walletAddress, uint8 _role) public {
        vm.assume(walletAddress != address(0));

        // Bound the enum value to valid range
        SharedStructs.UserType role = SharedStructs.UserType(_role % 6);

        // Should revert when user doesn't exist
        vm.expectRevert(LilypadUser.UserNotFound.selector);
        lilypadUser.removeRole(walletAddress, role);
    }
}
