// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import { ILilypadUser } from "./interfaces/ILilyipadUser.sol";
import { SharedStructs } from "./SharedStructs.sol";

contract User is ILilypadUser {
    // Mapping to store user roles
    mapping(address => SharedStructs.UserType) private users;
    
    // mapping of roles to addresses
    mapping(SharedStructs.UserType => address[]) private usersByRole;

    function SetUser(address walletAddress, SharedStructs.UserType role) external returns (bool) {
        //TODO
        return true;
    }

    function GetUser(address walletAddress) external view returns (SharedStructs.UserType) {
        return users[walletAddress];
    }

    function AddUserToList(address walletAddress, SharedStructs.UserType role) external returns (bool) {
        // TODO
        return true;
    }

    function RemoveUserFromList(address walletAddress, SharedStructs.UserType role) external returns (bool) {
        // TODO
        return false;
    }

    function HasRole(address walletAddress, SharedStructs.UserType role) external view returns (bool) {
        return users[walletAddress] == role;
    }

}