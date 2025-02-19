// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {SharedStructs} from "../SharedStructs.sol";

interface ILilypadPaymentEngine {
    /**
     * @dev This method will encompass the business logic related to handling a job completion and sending/releasing funds to the appropriate actors
     * @param _result The result struct of the job that is passed from the Solver
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function handleJobCompletion(SharedStructs.Result memory _result) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to handling a job completion and sending/releasing funds to the appropriate actors
     * @param _result The result struct of the job that is passed from the Solver
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function handleJobFailure(SharedStructs.Result memory _result) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to handling a successful validation (i.e. a resource provider acted honestly) completion and sending/releasing funds to the appropriate actors (i.e. the validation run successfully completed)
     * @param _validationResult The validation result struct of the job that is passed from the Solver
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function handleValidationPassed(SharedStructs.ValidationResult memory _validationResult) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to handling a failed validation (i.e. a resource provider acted dishonestly) and sending/releasing funds to the appropriate actors (i.e. the validation run failed to complete)
     * @param _validationResult The validation result struct of the job that is passed from the Sovler
     * @param _originalJobDeal The original job deal struct of the job that ran under validation
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function handleValidationFailed(
        SharedStructs.ValidationResult memory _validationResult,
        SharedStructs.Deal memory _originalJobDeal
    ) external returns (bool);

    /**
     * @dev Returns whether the escrow is active for a specific address.
     * @param _address The address whose escrow status is being queried.
     * @return True if the escrow is active, false otherwise.
     */
    function checkActiveEscrow(address _address) external view returns (bool);

    /**
     * @dev Returns whether the escrow can be withdrawn by a specific address.
     * @param _address The address whose escrow withdrawal status is being queried.
     * @return True if the escrow can be withdrawn, false otherwise.
     */
    function canWithdrawEscrow(address _address) external view returns (bool);

    /**
     * @dev This will allow a user to deposit escrow into the contract
     * @param _payee The address to deposit escrow for.
     * @param _paymentReason The reason for the payment.
     * @param _amount The amount to be added to escrow.
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function payEscrow(address _payee, SharedStructs.PaymentReason _paymentReason, uint256 _amount)
        external
        returns (bool);

    /**
     * @dev Refunds a specified amount from the escrow to a given address.  This function is limited to the Resource Provider and Validator roles.
     * @param _withdrawer The address that will receive the refund.
     * @param _amount The amount to refund to the given address.
     * @return Returns true if the refund operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function withdrawEscrow(address _withdrawer, uint256 _amount) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to initiating the lockup of escrow for a job
     * @param _jobCreator The address of the job creator.
     * @param _resourceProvider The address of the resource provider.
     * @param _dealId The unique identifier of the deal.
     * @param _cost The cost of the job.
     * @param _resourceProviderCollateralLockupAmount The amount of collateral lockup for the resource provider.
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function initiateLockupOfEscrowForJob(
        address _jobCreator,
        address _resourceProvider,
        string memory _dealId,
        uint256 _cost,
        uint256 _resourceProviderCollateralLockupAmount
    ) external returns (bool);

    /**
     * @dev This method will update the active burn tokens.  This function is meant to called by an external process who will be responsible for initiate the burning of the tokens on the l1 token contract following the below flow:
     *     - The external process call the activeBurnTokens() function to get the amount of tokens that are up for being burned at the time of the call (i.e. according to the epoch for burning tokens laid out in the tokenomics paper)
     *     - The external process then burns the tokens on the l1 token contract
     *     - The external process then calls the updateActiveBurnTokens() function to update the amount of active burn tokens passing in the amount that was burned so that the contract knows how much to subtract from the activeBurnTokens variable (as the amount can still be accumlating as the protocol is running)
     *     - updateActiveBurnTokens will then emit an event to notify the outside world of the amount of tokens that were burned including block number, block time, and the amount burnt
     * @param _amountBurnt The amount of token that was burned
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function updateActiveBurnTokens(uint256 _amountBurnt) external returns (bool);
}
