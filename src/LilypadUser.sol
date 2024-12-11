// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILilypadUser} from "./interfaces/ILilyipadUser.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract LilypadUser is ILilypadUser, Initializable {
    // Mapping to store user information
    mapping(address => SharedStructs.User) users;

    // mapping of addresses to roles
    mapping(address => mapping(SharedStructs.UserType => bool)) usersRoles;

    event UserManagementEvent(
        address walletAddress,
        string metadataID,
        string url,
        SharedStructs.UserType role
    );

    error UserAlreadyExists();
    error UserNotFound();
    error RoleAlreadyAssigned();
    error RoleNotAllowed();

    function initialize() external initializer {}

    function insertUser(
        address walletAddress,
        string memory metadataID,
        string memory url,
        SharedStructs.UserType role
    ) external returns (bool) {
        if (users[walletAddress].userAddress != address(0)) {
            revert UserAlreadyExists();
        }

        users[walletAddress] = SharedStructs.User({
            userAddress: walletAddress,
            metadataID: metadataID,
            url: url
        });

        usersRoles[walletAddress][role] = true;

        emit UserManagementEvent(walletAddress, metadataID, url, role);

        return true;
    }

    function updateUser(
        address walletAddress,
        string memory metadataID,
        string memory url,
        SharedStructs.UserType role
    ) external returns (bool) {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        // A resource provider cannot be a job creator and a job creator cannot be a resource provider
        if (
            (usersRoles[walletAddress][
                SharedStructs.UserType.ResourceProvider
            ] ==
                true &&
                role == SharedStructs.UserType.JobCreator) ||
            (usersRoles[walletAddress][SharedStructs.UserType.JobCreator] ==
                true &&
                role == SharedStructs.UserType.ResourceProvider)
        ) {
            revert RoleNotAllowed();
        }

        users[walletAddress].metadataID = metadataID;
        users[walletAddress].url = url;

        emit UserManagementEvent(walletAddress, metadataID, url, role);

        return true;
    }

    function getUser(
        address walletAddress
    ) external view returns (SharedStructs.User memory) {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        return users[walletAddress];
    }

    function hasRole(
        address walletAddress,
        SharedStructs.UserType role
    ) external view returns (bool) {
        if (users[walletAddress].userAddress == address(0)) {
            revert UserNotFound();
        }

        return usersRoles[walletAddress][role];
    }
}
