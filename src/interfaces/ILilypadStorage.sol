// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../SharedStructs.sol";

interface ILilypadStorage {
    /**
     * @dev Changes the status of a deal to the specified status.
     * @param dealId The unique identifier of the deal to update.
     * @param status The new status to assign to the deal (enum).
     * @return Returns true if the status change is successful.
     * @notice This function is restricted to the controller role.
     */
    function ChangeDealStatus(string memory dealId, SharedStructs.DealStatusEnum status) external returns (bool);

    /**
     * @dev Changes the validation result status to the specified status.
     * @param validationResultId The unique identifier of the validation result to update.
     * @param status The new validation result status to assign (enum).
     * @return Returns true if the status change is successful.
     * @notice This function is restricted to the controller role.
     */
    function ChangeValidationStatus(string memory validationResultId, SharedStructs.ValidationResultStatusEnum status)
        external
        returns (bool);

    /**
     * @dev Changes the Result status of a result to the specified status.
     * @param resultId The unique identifier of the result to update.
     * @param status The new result status to assign (enum).
     * @return Returns true if the status change is successful.
     * @notice This function is restricted to the controller role.
     */
    function ChangeResultStatus(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        returns (bool);

    /**
     * @dev Retrieves the result associated with a specific result ID.
     * @param resultId The unique identifier of the result.
     * @return Returns the `Result` struct associated with the result ID.
     */
    function GetResult(string memory resultId) external view returns (SharedStructs.Result memory);

    /**
     * @dev Saves the result data associated with a specific result ID.
     * @param resultId The unique identifier of the result.
     * @param result The `Result` struct to be saved.
     * @return Returns true if the result is successfully saved.
     * @notice This function is restricted to the controller role.
     */
    function SaveResult(string memory resultId, SharedStructs.Result memory result) external returns (bool);

    /**
     * @dev Retrieves the deal data associated with a specific deal ID.
     * @param dealId The unique identifier of the deal.
     * @return Returns the `Deal` struct associated with the deal ID.
     */
    function GetDeal(string memory dealId) external view returns (SharedStructs.Deal memory);

    /**
     * @dev Saves the deal data associated with a specific deal ID.
     * @param dealId The unique identifier of the deal.
     * @param deal The `Deal` struct to be saved.
     * @return Returns true if the deal is successfully saved.
     * @notice This function is restricted to the controller role.
     */
    function SaveDeal(string memory dealId, SharedStructs.Deal memory deal) external returns (bool);

    /**
     * @dev Retrieves the validation result associated with a specific validation result ID.
     * @param validationResultId The unique identifier of the validation result.
     * @return Returns the `ValidationResult` struct associated with the validation result ID.
     */
    function GetValidationResult(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResult memory);

    /**
     * @dev Saves the validation result data associated with a specific validation result ID.
     * @param validationResultId The unique identifier of the validation result.
     * @param validationResult The `ValidationResult` struct to be saved.
     * @return Returns true if the validation result is successfully saved.
     * @notice This function is restricted to the controller role.
     */
    function SaveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external returns (bool);

    /**
     * @dev Check the status of a deal.
     * @param dealId The unique identifier of the deal.
     * @return Returns the Deal Enum type according to the deals current status.
     */
    function CheckDealStatus(string memory dealId) external view returns (SharedStructs.DealStatusEnum);

    /**
     * @dev Check the status of a validation result.
     * @param validationResultId The unique identifier of the validation result.
     * @return Returns the ValidationResultStatus Enum type according to the validation result's current status.
     */
    function CheckValidationStatus(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResultStatusEnum);

    /**
     * @dev Check the status of a result.
     * @param resultId The unique identifier of the result assigned to the result.
     * @return Returns the Result Enum type according to the result's current status.
     */
    function CheckResultStatus(string memory resultId) external view returns (SharedStructs.ResultStatusEnum);
}
