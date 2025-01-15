// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../SharedStructs.sol";

interface ILilypadValidation {
    /**
     * @dev Grants the controller role to an account
     * @param account address to grant the controller role to
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function grantControllerRole(address account) external;

    /**
     * @dev Revokes the controller role from an account
     * @param account address to revoke the controller role from
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function revokeControllerRole(address account) external;

    /**
     * @dev Checks if an account has the controller role
     * @param account address to check
     * @return bool Indicates whether the account has the controller role
     */
    function hasControllerRole(address account) external view returns (bool);

	  /**
     * @dev This method will house the business logic related to accepting a verification request.
     * @param deal The `Deal` struct containing the details of the deal to be verified.
     * @param result The `Result` struct containing the details of the result to be verified.
     * @return bool Indicates whether the verification request was successfully created
     * @notice This function is restricted to the controller role.
     */
    function RequestValidation(SharedStructs.Deal memory deal, SharedStructs.Result memory result) external returns (bool);

    /**
     * @dev This method will house the business logic related to processing a validation request
     * @param validation The `Validation` struct containing the details and result of the validation process.
     * @return bool Indicates whether the verification was successfully processed
     * @notice This function is restricted to the controller role.
     */
    function ProcessValidation(SharedStructs.ValidationResult memory validation) external returns (bool);

    /**
     * @dev Retrieves the list of validators registered in the system.
     * @return address[] Array of addresses representing the registered validators
     */
    function GetValidators() external view returns (address[] memory);
}