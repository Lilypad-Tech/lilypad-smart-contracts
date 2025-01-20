// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SharedStructs} from "../SharedStructs.sol";

interface ILilypadPaymentEngine {

    /**
     * @dev This method will encompass the business logic related to handling a job completion and sending/releasing funds to the appropriate actors
     * @param _dealId The ID of the deal containg all the information about the job
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function HandleJobCompletion(
        string memory _dealId
    ) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to handling a job completion and sending/releasing funds to the appropriate actors
     * @param _result The result struct of the job
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function HandleJobFailure(
        SharedStructs.Result memory _result
    ) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to handling a successful validation completion and sending/releasing funds to the appropriate actors (i.e. the validation run successfully completed)
     * @param jobCreator The address of the Job Creator
     * @param resourceProvider The address of the resource provider.
     * @param moduleCreator The address of the module creator.
     * @param validatorAddress The address of the validator.
     * @param state The enum indicating the staus of the validation
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function HandleValidationPassed(
        address jobCreator,
        address resourceProvider,
        address moduleCreator,
        address validatorAddress,
        SharedStructs.ValidationResultStatusEnum state
    ) external returns (bool);

    /**
     * @dev This method will encompass the business logic related to handling a failed validation and sending/releasing funds to the appropriate actors (i.e. the validation run failed to complete)
     * @param jobCreator The address of the Job Creator
     * @param resourceProvider The address of the resource provider.
     * @param moduleCreator The address of the module creator.
     * @param validatorAddress The address of the validator.
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the controller role.
     */
    function HandleValidationFailed(
        address jobCreator,
        address resourceProvider,
        address moduleCreator,
        address validatorAddress
    ) external returns (bool);

    /**
     * @dev Returns the escrow balance of a specific address.
     * @param _address The address whose escrow balance is being queried.
     * @return The current escrow balance of the given address.
     */
    function escrowBalanceOf(address _address) external view returns (uint256);

    /**
     * @dev Returns whether the escrow is active for a specific address.
     * @param _address The address whose escrow status is being queried.
     * @return True if the escrow is active, false otherwise.
     */ 
    function checkActiveEscrow(address _address) external view returns (bool);  

    /**
     * @dev Returns the active escrow balance of a specific address.
     * @param _address The address whose active escrow balance is being queried.
     * @return The current active escrow balance of the given address.
     */
    function activeEscrowBalanceOf(address _address) external view returns (uint256);

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
    function payEscrow(
        address _payee,
        SharedStructs.PaymentReason _paymentReason,
        uint256 _amount
    ) external returns (bool);

    /**
     * @dev Refunds a specified amount from the escrow to a given address.
     * @param _withdrawer The address that will receive the refund.
     * @param _amount The amount to refund to the given address.
     * @return Returns true if the refund operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function withdrawEscrow(
        address _withdrawer,
        uint256 _amount
    ) external returns (bool);
}
