// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILilypadStorage} from "./interfaces/ILilypadStorage.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadStorage
 * @dev Implementation of storage contract for Lilypad platform
 */
contract LilypadStorage is Initializable, ILilypadStorage, AccessControlUpgradeable {
    using SharedStructs for *;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Mappings to store deal, validationResult, and result data
    mapping(string => SharedStructs.Deal) private deals;
    mapping(string => SharedStructs.ValidationResult) private validationResults;
    mapping(string => SharedStructs.Result) private results;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial admin
     */
    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Changes the status of a deal object
     * @param dealId The unique identifier of the deal to update
     * @param status The new status to assign to the deal
     * @return success Returns true if the status change is successful
     */
    function ChangeDealStatus(string memory dealId, SharedStructs.DealStatusEnum status)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        SharedStructs.Deal storage deal = deals[dealId];
        deal.status = status;
        return true;
    }

    /**
     * @dev Changes the status of a validation result
     * @param validationResultId The unique identifier of the validation result to update
     * @param status The new status to assign to the validation result
     * @return success Returns true if the status change is successful
     */
    function ChangeValidationStatus(string memory validationResultId, SharedStructs.ValidationResultStatusEnum status)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        validationResult.status = status;
        return true;
    }

    /**
     * @dev Changes the status of a result object
     * @param resultId The unique identifier of the result to update
     * @param status The new status to assign to the result
     * @return success Returns true if the status change is successful
     */
    function ChangeResultStatus(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        SharedStructs.Result storage result = results[resultId];
        result.status = status;
        return true;
    }

    /**
     * @dev Returns the CID of the result of a deal
     * @param resultId The unique identifier of the result
     * @return result The Result object associated with the resultId
     */
    function GetResult(string memory resultId) external view returns (SharedStructs.Result memory) {
        return results[resultId];
    }

    /**
     * @dev Saves a Result Object
     * @param resultId The unique identifier of the result
     * @param result The Result object to save
     * @return success Returns true if the save is successful
     */
    function SaveResult(string memory resultId, SharedStructs.Result memory result)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        results[resultId] = result;
        return true;
    }

    /**
     * @dev Returns the CID of the Deal object containing both the Job Offer and Resource Offer
     * @param dealId The unique identifier of the deal
     * @return deal The Deal object associated with the dealId
     */
    function GetDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        return deals[dealId];
    }

    /**
     * @dev Saves a Deal Object with a status
     * @param dealId The unique identifier of the deal
     * @param deal The Deal object to save
     * @return success Returns true if the save is successful
     */
    function SaveDeal(string memory dealId, SharedStructs.Deal memory deal)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        deals[dealId] = deal;
        return true;
    }

    /**
     * @dev Gets a validation result object
     * @param validationResultId The unique identifier of the validation result
     * @return validationResult The validation result object associated with the validationResultId
     */
    function GetValidationResult(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResult memory)
    {
        return validationResults[validationResultId];
    }

    /**
     * @dev Saves a validation result object with a status
     * @param validationResultId The unique identifier of the validation result
     * @param validationResult The validation result object to save
     * @return success Returns true if the save is successful
     */
    function SaveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external onlyRole(ADMIN_ROLE) returns (bool) {
        validationResults[validationResultId] = validationResult;
        return true;
    }

    /**
     * @dev Check the status of a deal
     * @param dealId The unique identifier of the deal
     * @return status The current status of the deal
     */
    function CheckDealStatus(string memory dealId) external view returns (SharedStructs.DealStatusEnum) {
        return deals[dealId].status;
    }

    /**
     * @dev Check the status of a validation result
     * @param validationResultId The unique identifier of the validation result
     * @return status The current status of the validation result
     */
    function CheckValidationStatus(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResultStatusEnum)
    {
        return validationResults[validationResultId].status;
    }

    /**
     * @dev Check the status of a result
     * @param resultId The unique identifier of the result
     * @return status The current status of the result
     */
    function CheckResultStatus(string memory resultId) external view returns (SharedStructs.ResultStatusEnum) {
        return results[resultId].status;
    }
}
