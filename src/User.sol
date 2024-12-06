// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import { ILilypadUser } from "./interfaces/ILilyipadUser.sol";
import { SharedStructs } from "./SharedStructs.sol";

contract User is ILilypadUser {
    // Mapping to store user roles
    mapping(address => SharedStructs.UserType) private users;
    
    // Array to store list of user addresses
    address[] private userList;

    function SetUser(address walletAddress, SharedStructs.UserType role) external returns (bool) {
        users[walletAddress] = role;
        return true;
    }

    function GetUser(address walletAddress) external view returns (SharedStructs.UserType) {
        return users[walletAddress];
    }

    function AddUserToList(address walletAddress) external returns (bool) {
        userList.push(walletAddress);
        return true;
    }

    function RemoveUserFromList(address walletAddress) external returns (bool) {
        for (uint i = 0; i < userList.length; i++) {
            if (userList[i] == walletAddress) {
                // Move last element to position being removed
                userList[i] = userList[userList.length - 1];
                // Remove last element
                userList.pop();
                return true;
            }
        }
        return false;
    }

    function HasRole(address walletAddress, SharedStructs.UserType role) external view returns (bool) {
        return users[walletAddress] == role;
    }

}