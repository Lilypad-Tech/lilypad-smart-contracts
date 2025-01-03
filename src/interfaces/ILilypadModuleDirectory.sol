// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../SharedStructs.sol";

interface ILilypadModuleDirectory {
    /**
     * @dev Registers a module for a specific creator (module owner)
     * @param moduleOwner The address of the module owner
     * @param moduleName The name of the module to be registered
     * @param moduleUrl The URL associated with the module
     * @return User The User struct containing details of the module owner after registration
     * @notice This function is restricted to the controller role
     */
    function RegisterModuleForCreator(address moduleOwner, string memory moduleName, string memory moduleUrl)
        external
        returns (SharedStructs.User memory);

    /**
     * @dev Updates a module name for an existing module
     * @param moduleOwner The address of the module owner
     * @param moduleName The existing name of the module
     * @param newModuleName The new name to associate with the module
     * @return bool Indicates whether the update was successful
     */
    function UpdateModuleName(address moduleOwner, string memory moduleName, string memory newModuleName)
        external
        returns (bool);

    /**
     * @dev Updates a module url for an existing module
     * @param moduleOwner The address of the module owner
     * @param moduleName The name of the module
     * @param newModuleUrl The new url to associate with the module
     * @return bool Indicates whether the update was successful
     */
    function UpdateModuleUrl(address moduleOwner, string memory moduleName, string memory newModuleUrl)
        external
        returns (bool);

    /**
     * @dev Retrieves all modules owned by a specific module owner
     * @param moduleOwner The address of the module owner
     * @return Module[] An array of Module structs representing the modules owned by the specified address
     */
    function GetOwnedModules(address moduleOwner) external view returns (SharedStructs.Module[] memory);

    /**
     * @dev This method will be used as a means for a module creator to authorize transfer of ownership of a module to a given address
     * @param moduleOwner The current owner of the module
     * @param newOwner The address of the new owner
     * @param moduleName The name of the module to be transferred
     * @param moduleUrl The URL associated with the module
     * @return bool Indicates whether the transfer approval was successful
     */
    function ApproveTransfer(address moduleOwner, address newOwner, string memory moduleName, string memory moduleUrl)
        external
        returns (bool);

    /**
     * @dev Transfers the ownership of a module from one user to another while transferring payment to the original owner
     * @param moduleOwner The current owner of the module
     * @param newOwner The address of the new owner
     * @param moduleName The name of the module to be transferred
     * @param moduleUrl The URL associated with the module
     * @return bool Indicates whether the transfer was successful
     */
    function TransferModuleOwnership(
        address moduleOwner,
        address newOwner,
        string memory moduleName,
        string memory moduleUrl
    ) external returns (bool);
}
