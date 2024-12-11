// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {SharedStructs} from "../SharedStructs.sol";

interface ILilypadUser {
    /**
     * @dev inserts a user
     * @param walletAddress The address of the user whose role is being set.
     * @param metadataID The decentralized identifier for the user's metadata.
     * @param url The url of the user's metadata.
     * @param role The role of the user.
     * @return Returns true if the user is successfully inserted.
     * @notice This function is restricted to the controller role.
     */
    function insertUser(
        address walletAddress,
        string memory metadataID,
        string memory url,
        SharedStructs.UserType role
    ) external returns (bool);

    /**
     * @dev updates a user's metadata
     * @param walletAddress The address of the user whose role is being set.
     * @param metadataID The decentralized identifier for the user's metadata.
     * @param url The url of the user's metadata.
     * @return Returns true if the user is successfully updated.
     * @notice This function is restricted to the controller role.
     */
    function updateUserMetadata(
        address walletAddress,
        string memory metadataID,
        string memory url
    ) external returns (bool);

    /**
     * @dev Adds a role to a user.
     * @param walletAddress The address of the user to add the role to.
     * @param role The role to add to the user.
     * @return Returns true if the role is successfully added.
     */
    function addRole(
        address walletAddress,
        SharedStructs.UserType role
    ) external returns (bool);

    /**
     * @dev Removes a role from a user.
     * @param walletAddress The address of the user to remove the role from.
     * @param role The role to remove from the user.
     * @return Returns true if the role is successfully removed.
     */
    function removeRole(
        address walletAddress,
        SharedStructs.UserType role
    ) external returns (bool);
    
    /**
     * @dev Retrieves the user details for a given wallet address.
     * @param walletAddress The address of the user to retrieve details for.
     * @return Returns the user's role type.
     */
    function getUser(
        address walletAddress
    ) external view returns (SharedStructs.User memory);

    /**
     * @dev Checks if a user has a specific role.
     * @param walletAddress The address of the user to check.
     * @param role The role type to check for the user.
     * @return Returns true if the user has the specified role.
     */
    function hasRole(
        address walletAddress,
        SharedStructs.UserType role
    ) external view returns (bool);
}
