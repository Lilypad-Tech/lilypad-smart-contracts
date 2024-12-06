// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import { SharedStructs } from "../SharedStructs.sol";

interface ILilypadUser {
    /**
     * @dev Sets the role type for a specific user.
     * @param walletAddress The address of the user whose role is being set.
     * @param role The role type to assign to the user (enum).
     * @return Returns true if the role is successfully assigned.
     * @notice This function is restricted to the controller role.
     */
    function SetUser(address walletAddress, SharedStructs.UserType role) external returns (bool);

    /**
     * @dev Retrieves the user details for a given wallet address.
     * @param walletAddress The address of the user to retrieve details for.
     * @return Returns the user's role type.
     */
    function GetUser(address walletAddress) external view returns (SharedStructs.UserType);

    /**
     * @dev Adds a user to the internal user list.
     * @param walletAddress The address of the user to add to the list.
     * @return Returns true if the user is successfully added.
     * @notice This function is restricted to the controller role.
     */
    function AddUserToList(address walletAddress) external returns (bool);

    /**
     * @dev Removes a user from the internal user list.
     * @param walletAddress The address of the user to remove from the list.
     * @return Returns true if the user is successfully removed.
     * @notice This function is restricted to the controller role.
     */
    function RemoveUserFromList(address walletAddress) external returns (bool);

    /**
     * @dev Checks if a user has a specific role.
     * @param walletAddress The address of the user to check.
     * @param role The role type to check for the user.
     * @return Returns true if the user has the specified role.
     */
    function HasRole(address walletAddress, SharedStructs.UserType role) external view returns (bool);
}