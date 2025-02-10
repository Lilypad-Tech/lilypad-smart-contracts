// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract LilypadUserTest is Test {
    LilypadUser public lilypadUser;
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant CONTROLLER = address(0x3);

    event LilypadUser__UserManagementEvent(address indexed walletAddress, string metadataID, string url, SharedStructs.UserType role, SharedStructs.UserOperation operation);

    function setUp() public {
        lilypadUser = new LilypadUser();
        lilypadUser.initialize();

        // Grant operator role to OPERATOR address
        lilypadUser.grantRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER);
    }

    function test_RevertWhen_NonAdminInsertsUser() public {
        vm.startPrank(ALICE);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, ALICE, SharedStructs.CONTROLLER_ROLE
            )
        );
        lilypadUser.insertUser(BOB, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
    }

    function test_ControllerCanUpdateMetadata() public {
        // First insert user as admin
        vm.startPrank(address(this)); // test contract is admin
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        vm.stopPrank();

        // Update as operator
        vm.startPrank(CONTROLLER);
        bool success = lilypadUser.updateUserMetadata(ALICE, "metadata2", "http://updated.com");
        assertTrue(success);
        vm.stopPrank();

        SharedStructs.User memory user = lilypadUser.getUser(ALICE);
        assertEq(user.metadataID, "metadata2");
        assertEq(user.url, "http://updated.com");
    }

    function test_UserCannotUpdateOwnMetadata() public {
        // First insert user as admin
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        // Update as user
        vm.startPrank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, ALICE, SharedStructs.CONTROLLER_ROLE
            )
        );
        lilypadUser.updateUserMetadata(ALICE, "metadata2", "http://updated.com");
        vm.stopPrank();

        SharedStructs.User memory user = lilypadUser.getUser(ALICE);
        assertEq(user.metadataID, "metadata1");
        assertEq(user.url, "http://example.com");
    }

    // Unit Tests
    function test_InsertUser() public {
        vm.expectEmit(true, true, true, true);
        emit LilypadUser__UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator, SharedStructs.UserOperation.NewUser);

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

        vm.expectRevert(LilypadUser.LilypadUser__UserAlreadyExists.selector);
        lilypadUser.insertUser(ALICE, "metadata2", "http://example2.com", SharedStructs.UserType.JobCreator);
    }

    function test_updateUserMetadata() public {
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectEmit(true, true, true, true);
        emit LilypadUser__UserManagementEvent(ALICE, "metadata2", "http://updated.com", SharedStructs.UserType.JobCreator, SharedStructs.UserOperation.UpdateUser);

        bool success = lilypadUser.updateUserMetadata(ALICE, "metadata2", "http://updated.com");
        assertTrue(success);

        SharedStructs.User memory user = lilypadUser.getUser(ALICE);
        assertEq(user.metadataID, "metadata2");
        assertEq(user.url, "http://updated.com");
    }

    function test_RevertWhen_UpdatingNonexistentUser() public {
        vm.expectRevert(LilypadUser.LilypadUser__UserNotFound.selector);
        lilypadUser.updateUserMetadata(ALICE, "metadata1", "http://example.com");
    }

    function test_AddRole() public {
        // First insert a user
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectEmit(true, true, true, true);
        emit LilypadUser__UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ModuleCreator, SharedStructs.UserOperation.RoleAdded);

        bool success = lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);
        assertTrue(success);
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ModuleCreator));
        // Verify original role is still there
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
    }

    function test_RevertWhen_AddingRoleToNonexistentUser() public {
        vm.expectRevert(LilypadUser.LilypadUser__UserNotFound.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Admin);
    }

    function test_RevertWhen_AddingIncompatibleRole() public {
        // First insert user as JobCreator
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        // Try to add ResourceProvider role - should fail
        vm.expectRevert(LilypadUser.LilypadUser__RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ResourceProvider);
    }

    function test_RevertWhen_JobCreatorAddsResourceProviderRole() public {
        // First insert user as JobCreator
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectRevert(LilypadUser.LilypadUser__RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ResourceProvider);
    }

    function test_RevertWhen_ResourceProviderAddsJobCreatorRole() public {
        // First insert user as ResourceProvider
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ResourceProvider);

        vm.expectRevert(LilypadUser.LilypadUser__RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.JobCreator);
    }

    function test_RemoveRole() public {
        // First insert a user with multiple roles
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);

        vm.expectEmit(true, true, true, true);
        emit LilypadUser__UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ModuleCreator, SharedStructs.UserOperation.RoleRemoved);

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
        emit LilypadUser__UserManagementEvent(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator, SharedStructs.UserOperation.RoleRemoved);

        bool success = lilypadUser.removeRole(ALICE, SharedStructs.UserType.JobCreator);
        assertTrue(success);
        assertFalse(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
    }

    function test_RevertWhen_RemovingRoleFromNonexistentUser() public {
        vm.expectRevert(LilypadUser.LilypadUser__UserNotFound.selector);
        lilypadUser.removeRole(ALICE, SharedStructs.UserType.Admin);
    }

    function test_RevertWhen_RemovingNonexistentRole() public {
        // First insert user with JobCreator role
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        vm.expectRevert(LilypadUser.LilypadUser__RoleNotFound.selector);
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

        // Skip test if trying to add incompatible roles or if roles are the same
        if (
            (initialRole == SharedStructs.UserType.JobCreator && newRole == SharedStructs.UserType.ResourceProvider)
                || (initialRole == SharedStructs.UserType.ResourceProvider && newRole == SharedStructs.UserType.JobCreator)
                || initialRole == newRole
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
        vm.expectRevert(LilypadUser.LilypadUser__RoleNotAllowed.selector);
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
        vm.expectRevert(LilypadUser.LilypadUser__UserNotFound.selector);
        lilypadUser.removeRole(walletAddress, role);
    }

    function test_MultipleCompatibleRoles() public {
        // Test adding all compatible roles to a single user
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Admin);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Solver);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Validator);

        // Verify all roles are present
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ModuleCreator));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.Admin));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.Solver));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.Validator));
    }

    function test_RemoveMiddleRole() public {
        // Test removing a role that's "sandwiched" between other roles
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Admin);

        // Remove middle role
        lilypadUser.removeRole(ALICE, SharedStructs.UserType.ModuleCreator);

        // Verify correct roles remain
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.JobCreator));
        assertFalse(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ModuleCreator));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.Admin));
    }

    function test_ResourceProviderMultipleRoles() public {
        // Test ResourceProvider can have multiple compatible roles
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.ResourceProvider);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.ModuleCreator);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Admin);

        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ResourceProvider));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.ModuleCreator));
        assertTrue(lilypadUser.hasRole(ALICE, SharedStructs.UserType.Admin));

        // Verify JobCreator role still can't be added
        vm.expectRevert(LilypadUser.LilypadUser__RoleNotAllowed.selector);
        lilypadUser.addRole(ALICE, SharedStructs.UserType.JobCreator);
    }

    // Validator List Tests
    function test_GetValidatorsEmpty() public {
        address[] memory validators = lilypadUser.getValidators();
        assertEq(validators.length, 0);
    }

    function test_GetValidatorsSingle() public {
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.Validator);

        address[] memory validators = lilypadUser.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], ALICE);
    }

    function test_GetValidatorsMultiple() public {
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.Validator);
        lilypadUser.insertUser(BOB, "metadata2", "http://example.com", SharedStructs.UserType.Validator);

        address[] memory validators = lilypadUser.getValidators();
        assertEq(validators.length, 2);
        assertTrue(validators[0] == ALICE || validators[1] == ALICE);
        assertTrue(validators[0] == BOB || validators[1] == BOB);
    }

    function test_ValidatorListAfterRoleRemoval() public {
        // Add two validators
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.Validator);
        lilypadUser.insertUser(BOB, "metadata2", "http://example.com", SharedStructs.UserType.Validator);

        // Remove validator role from ALICE
        lilypadUser.removeRole(ALICE, SharedStructs.UserType.Validator);

        // Check validators list
        address[] memory validators = lilypadUser.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], BOB);
    }

    function test_ValidatorListAfterRoleAdd() public {
        // Add user with non-validator role
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);

        // Add validator role
        lilypadUser.addRole(ALICE, SharedStructs.UserType.Validator);

        // Check validators list
        address[] memory validators = lilypadUser.getValidators();
        assertEq(validators.length, 1);
        assertEq(validators[0], ALICE);
    }

    function testFuzz_ValidatorManagement(address[] memory potentialValidators, bool[] memory shouldBeValidator)
        public
    {
        // Bound array size to a reasonable range
        uint256 size = bound(potentialValidators.length, 1, 5);

        // Create new arrays with bounded size
        address[] memory boundedValidators = new address[](size);
        bool[] memory boundedShouldBeValidator = new bool[](size);

        uint256 expectedValidatorCount = 0;

        // Process only up to our bounded size
        for (uint256 i = 0; i < size; i++) {
            // Generate a unique non-zero address
            address user = address(uint160(i + 1));

            // Use input boolean if available, otherwise alternate
            bool shouldBeValid = shouldBeValidator.length > i ? shouldBeValidator[i] : (i % 2 == 0);

            boundedValidators[i] = user;
            boundedShouldBeValidator[i] = shouldBeValid;

            // Insert user
            if (shouldBeValid) {
                lilypadUser.insertUser(user, "metadata", "http://example.com", SharedStructs.UserType.Validator);
                expectedValidatorCount++;
            } else {
                lilypadUser.insertUser(user, "metadata", "http://example.com", SharedStructs.UserType.JobCreator);
            }
        }

        // Verify validator count
        address[] memory validators = lilypadUser.getValidators();
        assertEq(validators.length, expectedValidatorCount);

        // Verify each validator is in the list
        for (uint256 i = 0; i < size; i++) {
            if (boundedShouldBeValidator[i]) {
                bool found = false;
                for (uint256 j = 0; j < validators.length; j++) {
                    if (validators[j] == boundedValidators[i]) {
                        found = true;
                        break;
                    }
                }
                assertTrue(found);
            }
        }
    }
}
