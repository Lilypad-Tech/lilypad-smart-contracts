// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILilypadUser} from "./interfaces/ILilypadUser.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract LilypadUser is ILilypadUser, Initializable {
    // Mapping to store user information
    mapping(address => SharedStructs.User) users;

    // mapping of addresses to roles using bitwise operations to store multiple roles
    mapping(address => uint256) usersRoles;

    event UserManagementEvent(address walletAddress, string metadataID, string url, SharedStructs.UserType role);

    error UserAlreadyExists();
    error UserNotFound();
    error RoleAlreadyAssigned();
    error RoleNotAllowed();
    error RoleNotFound();

    function initialize() external initializer {}

    function insertUser(address walletAddress, string memory metadataID, string memory url, SharedStructs.UserType role)
        external
        returns (bool)
    {
        if (users[walletAddress].userAddress != address(0)) {
            revert UserAlreadyExists();
        }

        users[walletAddress] = SharedStructs.User({userAddress: walletAddress, metadataID: metadataID, url: url});

        usersRoles[walletAddress] = 1 << uint256(role);

        emit UserManagementEvent(walletAddress, metadataID, url, role);

        return true;
    }

    function updateUserMetadata(address walletAddress, string memory metadataID, string memory url)
        external
        returns (bool)
    {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        users[walletAddress].metadataID = metadataID;
        users[walletAddress].url = url;

        emit UserManagementEvent(walletAddress, metadataID, url, SharedStructs.UserType.JobCreator);

        return true;
    }

    function addRole(address walletAddress, SharedStructs.UserType role) external returns (bool) {
        SharedStructs.User memory user = users[walletAddress];
        if (user.userAddress == address(0)) {
            revert UserNotFound();
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
            revert RoleNotAllowed();
        }

        // add the role to the user using bitwise operations to avoid overwriting existing roles
        // Existing roles: 0001
        // New role:      0100
        // Result:        0101  (both roles are now set)
        usersRoles[walletAddress] = usersRoles[walletAddress] | 1 << uint256(role);

        emit UserManagementEvent(walletAddress, user.metadataID, user.url, role);

        return true;
    }

    function removeRole(address walletAddress, SharedStructs.UserType role) external returns (bool) {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        if (usersRoles[walletAddress] & 1 << uint256(role) == 0) {
            revert RoleNotFound();
        }

        // remove the role from the user using bitwise operations to avoid overwriting existing roles
        // Existing roles: 0101
        // Role to remove: 0100
        // Result:        0001  (only the new role is removed)
        usersRoles[walletAddress] = usersRoles[walletAddress] & ~(1 << uint256(role));

        emit UserManagementEvent(walletAddress, users[walletAddress].metadataID, users[walletAddress].url, role);

        return true;
    }

    function getUser(address walletAddress) external view returns (SharedStructs.User memory) {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        return users[walletAddress];
    }

    function hasRole(address walletAddress, SharedStructs.UserType role) external view returns (bool) {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        // check if the role is set using bitwise operations
        // Existing roles: 0101
        // Role to check: 0100
        // Result:        0101 & 0100 = 0100  (non-zero, so the role is set)
        return usersRoles[walletAddress] & 1 << uint256(role) != 0;
    }
}
