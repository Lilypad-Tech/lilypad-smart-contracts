// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../SharedStructs.sol";

// Smart contract address Getter and Setters omitted but add for impl

interface ILilypadProxy {
    /**
     * @dev Accepts payment for a job associated with a specific module.
     * @param moduleName The name of the module for which the payment is being made.
     * @param amount The amount of payment to be accepted.
     * @param payee The address of the payee receiving the payment.
     * @return bool Indicates if the payment is successfully accepted.
     */
    function acceptJobPayment(string memory moduleName, uint256 amount, address payee) external returns (bool);

    /**
     * @dev The function validators will use to pay collateral to run a validation on the network
     * @param amount The amount of collateral to be accepted.
     * @param validatorAddress The address of the validator providing the collateral.
     * @return bool Indicates if the collateral is successfully accepted.
     */
    function acceptValidationCollateral(uint256 amount, address validatorAddress) external returns (bool);

    /**
     * @dev The function Resource Providers will use to pay collateral to be able to run jobs on the network.  This method can be used to pay an initial collateral amount or to top up an existing amount
     * @param amount The amount of collateral to be accepted.
     * @param resourceProviderAddress The address of the resource provider providing the collateral.
     * @return bool Indicates if the collateral is successfully accepted.
     */
    function acceptResourceProviderCollateral(uint256 amount, address resourceProviderAddress)
        external
        returns (bool);

    /**
     * @dev The function Job Creators will use to request and pay for verification
     * @param requestorAddress The address requesting the verification.
     * @param moduleName The name of the module to be verified.
     * @param amount The payment or collateral amount for the validation.
     * @return ValidationResult Indicates the validation details and status.
     */
    function requestValidation(address requestorAddress, string memory moduleName, uint256 amount)
        external
        returns (SharedStructs.ValidationResult memory);

    /**
     * @dev Retrieves the result for a specific deal.
     * @param dealId The unique identifier of the deal.
     * @return Result Indicates the result details and status.
     */
    function getResult(string memory dealId) external view returns (SharedStructs.Result memory);

    /**
     * @dev Sets the result for a specific deal.
     * @param result The `Result` struct containing the details of the result.
     * @return bool Indicates if the result is successfully saved.
     * @notice This function is restricted to the owner role.
     */
    function setResult(SharedStructs.Result memory result) external returns (bool);

    /**
     * @dev Retrieves the deal data for a specific deal ID.
     * @param dealId The unique identifier of the deal.
     * @return Deal Indicates the deal details and status.
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory);

    /**
     * @dev Sets the deal data for a specific deal ID.
     * @param deal The `Deal` struct containing the details to be saved.
     * @return bool Indicates if the deal is successfully saved.
     * @notice This function is restricted to the owner role.
     */
    function setDeal(SharedStructs.Deal memory deal) external returns (bool);

    /**
     * @dev Updates the state of a specific deal.
     * @param dealId The unique identifier of the deal to update.
     * @param state The new state to assign to the deal (enum).
     * @return bool Indicates if the state is successfully updated.
     * @notice This function is restricted to the owner role.
     */
    function updateDealState(string memory dealId, SharedStructs.DealStatusEnum state) external returns (bool);

    /**
     * @dev Updates the state of a specific Result.
     * @param resultId The unique identifier of the deal to update.
     * @param state The new state to assign to the deal (enum).
     * @return bool Indicates if the state is successfully updated.
     * @notice This function is restricted to the owner role.
     */
    function updateResultState(string memory resultId, SharedStructs.ResultStatusEnum state) external returns (bool);

    /**
     * @dev Updates the state of a specific validation.
     * @param validationId The unique identifier of the deal to update.
     * @param state The new state to assign to the deal (enum).
     * @return bool Indicates if the state is successfully updated.
     * @notice This function is restricted to the owner role.
     */
    function updateValidationState(string memory validationId, SharedStructs.ValidationResultStatusEnum state)
        external
        returns (bool);

    /**
     * @dev Retrieves the validation result for a specific validation ID.
     * @param validationId The unique identifier of the verification.
     * @return ValidationResult Indicates the validation details and status.
     */
    function getValidationResult(string memory validationId)
        external
        view
        returns (SharedStructs.ValidationResult memory);

    /**
     * @dev Sets the validation result for a specific validation.
     * @param validationId The unique identifier of the validation.
     * @param verification The `ValidationResult` struct containing the result details.
     * @return bool Indicates if the validation result is successfully saved.
     * @notice This function is restricted to the owner role.
     */
    function setValidationResult(string memory validationId, SharedStructs.ValidationResult memory verification)
        external
        returns (bool);
}
