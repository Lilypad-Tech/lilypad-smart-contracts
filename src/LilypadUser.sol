// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ILilypadUser} from "./interfaces/ILilypadUser.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadUser
 * @dev Implementation of the LilypadUser contract
 */
contract LilypadUser is ILilypadUser, Initializable, AccessControlUpgradeable {
    // Mapping to store user information
    mapping(address => SharedStructs.User) users;

    // mapping of addresses to roles using bitwise operations to store multiple roles
    mapping(address => uint256) usersRoles;

    // Array to track validator addresses
    address[] private validatorAddresses;

    // Version
    string public version;

    event LilypadUser__UserManagementEvent(
        address indexed walletAddress,
        string metadataID,
        string url,
        SharedStructs.UserType role,
        SharedStructs.UserOperation operation
    );

    error LilypadUser__UserAlreadyExists();
    error LilypadUser__UserNotFound();
    error LilypadUser__RoleAlreadyAssigned();
    error LilypadUser__RoleNotAllowed();
    error LilypadUser__RoleNotFound();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __AccessControl_init();

        // Grant admin role to deployer (DEFAULT_ADMIN_ROLE is from AccessControlUpgradeable)
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
        version = "1.0.0";
    }

    /**
     * @dev Returns the current version of the contract
     * @notice
     * - Returns the semantic version string of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    /**
     * @dev inserts a user
     * @notice
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if the `walletAddress` already exists
     * - Emits a `UserManagementEvent` event upon successful insertion
     */
    function insertUser(address walletAddress, string memory metadataID, string memory url, SharedStructs.UserType role)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (users[walletAddress].userAddress != address(0)) {
            revert LilypadUser__UserAlreadyExists();
        }

        users[walletAddress] = SharedStructs.User({userAddress: walletAddress, metadataID: metadataID, url: url});
        usersRoles[walletAddress] = 1 << uint256(role);

        // Add to validator list if role is Validator
        if (role == SharedStructs.UserType.Validator) {
            validatorAddresses.push(walletAddress);
        }

        emit LilypadUser__UserManagementEvent(walletAddress, metadataID, url, role, SharedStructs.UserOperation.NewUser);

        return true;
    }

    /**
     * @dev updates a user's metadata
     * @notice
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if the `walletAddress` does not exist
     * - Emits a `UserManagementEvent` event upon successful update
     */
    function updateUserMetadata(address walletAddress, string memory metadataID, string memory url)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (users[walletAddress].userAddress == address(0)) {
            revert LilypadUser__UserNotFound();
        }

        users[walletAddress].metadataID = metadataID;
        users[walletAddress].url = url;

        emit LilypadUser__UserManagementEvent(
            walletAddress, metadataID, url, SharedStructs.UserType.JobCreator, SharedStructs.UserOperation.UpdateUser
        );

        return true;
    }

    /**
     * @dev adds a role to a user
     * @notice
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if the `walletAddress` does not exist
     * - Reverts if the `role` is not allowed
     * - A Job Creator cannot be a Resource Provider and a Resource Provider cannot be a Job Creator
     * - Emits a `UserManagementEvent` event upon successful addition
     */
    function addRole(address walletAddress, SharedStructs.UserType role)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        SharedStructs.User memory user = users[walletAddress];
        if (user.userAddress == address(0)) {
            revert LilypadUser__UserNotFound();
        }

        // A resource provider cannot be a job creator and a job creator cannot be a resource provider
        if (
            (
                usersRoles[walletAddress] & 1 << uint256(SharedStructs.UserType.ResourceProvider) != 0
                    && role == SharedStructs.UserType.JobCreator
            )
                || (
                    usersRoles[walletAddress] & 1 << uint256(SharedStructs.UserType.JobCreator) != 0
                        && role == SharedStructs.UserType.ResourceProvider
                )
        ) {
            revert LilypadUser__RoleNotAllowed();
        }

        // Check if role already exists
        if (usersRoles[walletAddress] & 1 << uint256(role) != 0) {
            revert LilypadUser__RoleAlreadyAssigned();
        }

        // add the role to the user using bitwise operations to avoid overwriting existing roles
        // Existing roles: 0001
        // New role:      0100
        // Result:        0101  (both roles are now set)
        usersRoles[walletAddress] = usersRoles[walletAddress] | 1 << uint256(role);

        // Add to validator list if role is Validator
        if (role == SharedStructs.UserType.Validator) {
            validatorAddresses.push(walletAddress);
        }

        emit LilypadUser__UserManagementEvent(
            walletAddress, user.metadataID, user.url, role, SharedStructs.UserOperation.RoleAdded
        );

        return true;
    }

    /**
     * @dev removes a role from a user
     * @notice
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if the `walletAddress` does not exist
     * - Reverts if the `role` is not set
     * - Emits a `UserManagementEvent` event upon successful removal
     */
    function removeRole(address walletAddress, SharedStructs.UserType role)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (users[walletAddress].userAddress == address(0)) {
            revert LilypadUser__UserNotFound();
        }

        if (usersRoles[walletAddress] & 1 << uint256(role) == 0) {
            revert LilypadUser__RoleNotFound();
        }

        // Remove the role from the user using bitwise operations to avoid overwriting existing roles
        // Existing roles: 0101
        // Role to remove: 0100
        // Result:        0001  (only the new role is removed)
        usersRoles[walletAddress] = usersRoles[walletAddress] & ~(1 << uint256(role));

        // Remove from validator list if role is Validator
        if (role == SharedStructs.UserType.Validator) {
            uint256 validatorArrayLength = validatorAddresses.length;
            for (uint256 i = 0; i < validatorArrayLength; i++) {
                if (validatorAddresses[i] == walletAddress) {
                    validatorAddresses[i] = validatorAddresses[validatorArrayLength - 1];
                    validatorAddresses.pop();
                    break;
                }
            }
        }

        emit LilypadUser__UserManagementEvent(
            walletAddress,
            users[walletAddress].metadataID,
            users[walletAddress].url,
            role,
            SharedStructs.UserOperation.RoleRemoved
        );

        return true;
    }

    /**
     * @dev returns a user
     * @notice
     * - Reverts if the `walletAddress` does not exist
     */
    function getUser(address walletAddress) external view returns (SharedStructs.User memory) {
        if (users[walletAddress].userAddress == address(0)) {
            revert LilypadUser__UserNotFound();
        }

        return users[walletAddress];
    }

    /**
     * @dev checks if a user has a role
     * @notice
     * - Reverts if the `walletAddress` does not exist
     */
    function hasRole(address walletAddress, SharedStructs.UserType role) external view returns (bool) {
        if (users[walletAddress].userAddress == address(0)) {
            revert LilypadUser__UserNotFound();
        }

        // Check if the role is set using bitwise operations
        // Existing roles: 0101
        // Role to check: 0100
        // Result:        0101 & 0100 = 0100  (non-zero, so the role is set)
        return usersRoles[walletAddress] & 1 << uint256(role) != 0;
    }

    /**
     * @dev Retrieves all validator addresses.
     * @return Returns an array of all validator addresses in the system.
     */
    function getValidators() external view returns (address[] memory) {
        return validatorAddresses;
    }

    /**
     * @dev Retrieves the controller role bytes32 value
     * @return Returns the controller role bytes32 value
     * @notice
     * - This function is used to get the Controller role bytes32 value meant to be used for access control
     */
    function getControllerAccessControlRole() external pure returns (bytes32) {
        return SharedStructs.CONTROLLER_ROLE;
    }

    /**
     * @dev Retrieves the minter role bytes32 value
     * @return Returns the minter role bytes32 value
     * @notice
     * - This function is used to get the Minter role bytes32 value meant to be used for access control
     */
    function getMinterAccessControlRole() external pure returns (bytes32) {
        return SharedStructs.MINTER_ROLE;
    }

    /**
     * @dev Retrieves the pauser role bytes32 value
     * @return Returns the pauser role bytes32 value
     * @notice
     * - This function is used to get the Pauser role bytes32 value meant to be used for access control
     */
    function getPauserAccessControlRole() external pure returns (bytes32) {
        return SharedStructs.PAUSER_ROLE;
    }

    /**
     * @dev Retrieves the vesting role bytes32 value
     * @return Returns the vesting role bytes32 value
     * @notice
     * - This function is used to get the vesting role bytes32 value meant to be used for access control
     */
    function getVestingAccessControlRole() external pure returns (bytes32) {
        return SharedStructs.VESTING_ROLE;
    }
}
