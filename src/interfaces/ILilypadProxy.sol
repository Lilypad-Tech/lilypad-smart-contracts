// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../SharedStructs.sol";

interface ILilypadProxy {
    /**
     * @dev Accepts payment for a job associated with a specific module.
     * @param _amount The amount of payment to be accepted.
     * @return Returns true if the payment is successfully accepted.
     */
    function acceptJobPayment(uint256 _amount) external returns (bool);

    /**
     * @dev The function Resource Providers will use to pay collateral to be able to run jobs on the network.  This method can be used to pay an initial collateral amount or to top up an existing amount
     * @param _amount The amount of collateral to be accepted.
     * @return Returns true if the collateral is successfully accepted.
     */
    function acceptResourceProviderCollateral(uint256 _amount) external returns (bool);

    /**
     * @dev The function validators will use to pay collateral to run a validation on the network
     * @param _amount The amount of collateral to be accepted.
     * @return Returns true if the collateral is successfully accepted.
     */
    function acceptValidationCollateral(uint256 _amount) external returns (bool);

    /**
     * @dev The function to get the escrow amount for a specific address
     * @param _address The address of the account to get the escrow amount for.
     * @return Returns the escrow amount for the address.
     */
    function getEscrowBalance(address _address) external view returns (uint256);

    /**
     * @dev The function Job Creators will use to request and pay for verification
     * @param requestorAddress The address requesting the verification.
     * @param moduleName The name of the module to be verified.
     * @param amount The payment or collateral amount for the validation.
     * @return Returns true if the validation is successfully requested.
     */
    function requestValidation(address requestorAddress, string memory moduleName, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Retrieves the result for a specific deal.
     * @param dealId The unique identifier of the deal.
     * @return Returns a `Result` struct or a string CID representing the result.
     */
    function getResult(string memory dealId) external view returns (SharedStructs.Result memory);

    /**
     * @dev Sets the result for a specific deal.
     * @param result The `Result` struct containing the details of the result.
     * @return Returns true if the result is successfully saved.
     * @notice This function is restricted to the owner role.
     */
    function setResult(SharedStructs.Result memory result) external returns (bool);

    /**
     * @dev Retrieves the deal data for a specific deal ID.
     * @param dealId The unique identifier of the deal.
     * @return Returns a `Deal` struct containing the deal details.
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory);

    /**
     * @dev Sets the deal data for a specific deal ID.
     * @param deal The `Deal` struct containing the details to be saved.
     * @return Returns true if the deal is successfully saved.
     * @notice This function is restricted to the owner role.
     */
    function setDeal(SharedStructs.Deal memory deal) external returns (bool);

    /**
     * @dev Updates the state of a specific deal.
     * @param dealId The unique identifier of the deal to update.
     * @param state The new state to assign to the deal (enum).
     * @return Returns true if the state is successfully updated.
     * @notice This function is restricted to the owner role.
     */
    function updateDealState(string memory dealId, SharedStructs.DealStatusEnum state) external returns (bool);

    /**
     * @dev Updates the state of a specific Result.
     * @param resultId The unique identifier of the deal to update.
     * @param state The new state to assign to the deal (enum).
     * @return Returns true if the state is successfully updated.
     * @notice This function is restricted to the owner role.
     */
    function updateResultState(string memory resultId, SharedStructs.ResultStatusEnum state) external returns (bool);

    /**
     * @dev Updates the state of a specific validation.
     * @param validationId The unique identifier of the deal to update.
     * @param state The new state to assign to the deal (enum).
     * @return Returns true if the state is successfully updated.
     * @notice This function is restricted to the owner role.
     */
    function updateValidationState(string memory validationId, SharedStructs.ValidationResultStatusEnum state)
        external
        returns (bool);

    /**
     * @dev Retrieves the validation result for a specific validation ID.
     * @param validationId The unique identifier of the verification.
     * @return Returns a `ValidationResult` struct containing the validation result.
     */
    function getValidationResult(string memory validationId)
        external
        view
        returns (SharedStructs.ValidationResult memory);

    /**
     * @dev Sets the validation result for a specific validation.
     * @param validationId The unique identifier of the validation.
     * @param validation The `Validation` struct containing the result details.
     * @return Returns true if the validation result is successfully saved.
     * @notice This function is restricted to the owner role.
     */
    function setValidationResult(string memory validationId, SharedStructs.ValidationResult memory validation)
        external
        returns (bool);
}
