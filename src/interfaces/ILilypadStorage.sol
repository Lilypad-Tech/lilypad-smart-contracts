// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "../SharedStructs.sol";

interface ILilypadStorage {
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
     * @dev Changes the status of a deal object
     * @param dealId unique identifier of the deal to update
     * @param status new status to assign to the deal (enum)
     * @return bool Indicates whether the status change was successful
     * @notice This function is restricted to the controller role
     */
    function changeDealStatus(string memory dealId, SharedStructs.DealStatusEnum status) external returns (bool);

    /**
     * @dev Changes the status of a validation result
     * @param validationResultId unique identifier of the validation result to update
     * @param status new validation result status to assign (enum)
     * @return bool Indicates whether the status change was successful
     * @notice This function is restricted to the controller role
     */
    function changeValidationResultStatus(
        string memory validationResultId,
        SharedStructs.ValidationResultStatusEnum status
    ) external returns (bool);

    /**
     * @dev Changes the status of a result object
     * @param resultId unique identifier of the result to update
     * @param status new result status to assign (enum)
     * @return bool Indicates whether the status change was successful
     * @notice This function is restricted to the controller role
     */
    function changeResultStatus(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        returns (bool);

    /**
     * @dev Returns the Result object associated with the resultId
     * @param resultId unique identifier of the result
     * @return Result struct associated with the result ID
     */
    function getResult(string memory resultId) external view returns (SharedStructs.Result memory);

    /**
     * @dev Saves a Result Object
     * @param resultId unique identifier of the result
     * @param result Result struct to be saved
     * @return bool Indicates whether the result was successfully saved
     * @notice This function is restricted to the controller role
     */
    function saveResult(string memory resultId, SharedStructs.Result memory result) external returns (bool);

    /**
     * @dev Returns the Deal object associated with the dealId
     * @param dealId unique identifier of the deal
     * @return Deal struct associated with the deal ID
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory);

    /**
     * @dev Saves a Deal Object with a status
     * @param dealId unique identifier of the deal
     * @param deal Deal struct to be saved
     * @return bool Indicates whether the deal was successfully saved
     * @notice This function is restricted to the controller role
     */
    function saveDeal(string memory dealId, SharedStructs.Deal memory deal) external returns (bool);

    /**
     * @dev Gets a validation result object
     * @param validationResultId unique identifier of the validation result
     * @return ValidationResult struct associated with the validation result ID
     */
    function getValidationResult(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResult memory);

    /**
     * @dev Saves a validation result object with a status
     * @param validationResultId unique identifier of the validation result
     * @param validationResult ValidationResult struct to be saved
     * @return bool Indicates whether the validation result was successfully saved
     * @notice This function is restricted to the controller role
     */
    function saveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external returns (bool);

    /**
     * @dev Check the status of a deal
     * @param dealId unique identifier of the deal
     * @return DealStatusEnum type according to the deals current status
     */
    function checkDealStatus(string memory dealId) external view returns (SharedStructs.DealStatusEnum);

    /**
     * @dev Check the status of a validation result
     * @param validationResultId unique identifier of the validation result
     * @return ValidationResultStatusEnum type according to the validation result's current status
     */
    function checkValidationResultStatus(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResultStatusEnum);

    /**
     * @dev Check the status of a result
     * @param resultId unique identifier of the result
     * @return ResultStatusEnum type according to the result's current status
     */
    function checkResultStatus(string memory resultId) external view returns (SharedStructs.ResultStatusEnum);
}
