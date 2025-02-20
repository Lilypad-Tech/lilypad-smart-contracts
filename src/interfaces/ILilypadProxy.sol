// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {SharedStructs} from "../SharedStructs.sol";

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
     * @dev The function to get the escrow amount for a specific address
     * @param _address The address of the account to get the escrow amount for.
     * @return Returns the escrow amount for the address.
     */
    function getEscrowBalance(address _address) external view returns (uint256);

    /**
     * @dev Retrieves the result for a specific deal.
     * @param _resultId The unique identifier of the result.
     * @return Returns a `Result` struct or a string CID representing the result.
     */
    function getResult(string memory _resultId) external view returns (SharedStructs.Result memory);

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
}
