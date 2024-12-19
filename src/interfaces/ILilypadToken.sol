// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILilypadToken {
  
   /**
     * @dev Returns the escrow balance of a specific address.
     * @param _address The address whose escrow balance is being queried.
     * @return The current escrow balance of the given address.
     */
    function escrowBalanceOf(address _address) external view returns (uint256);

    /**
     * @dev This will allow a user to deposit escrow into the contract
     * @param toAddress The address to deposit escrow for.
     * @param amount The amount to be added to escrow.
     * @return Returns true if the operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function payEscrow(address toAddress, uint256 amount) external returns (bool);

    /**
     * @dev Refunds a specified amount from the escrow to a given address.
     * @param toAddress The address that will receive the refund.
     * @param amount The amount to refund to the given address.
     * @return Returns true if the refund operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function refundEscrow(address toAddress, uint256 amount) external returns (bool);

    /**
     * @dev Processes a payout for a job, transferring a specified amount from one address's escrow
     * to another.
     * @param toAddress The address receiving the payout.
     * @param fromAddress The address sending the payout.
     * @param amount The amount to transfer as a payout.
     * @return Returns true if the payout operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function PayOutJob(address toAddress, address fromAddress, uint256 amount) external returns (bool);

    /**
     * @dev Deducts (slashes) a specified amount from an escrow balance as a penalty.
     * @param addressToSlash The address whose escrow balance will be deducted.
     * @param amount The amount to deduct as a penalty.
     * @return Returns true if the slash operation is successful.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function slashEscrow(address addressToSlash, uint256 amount) external returns (bool);
} 