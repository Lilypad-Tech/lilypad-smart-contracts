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
    using SharedStructs for SharedStructs.Deal;
    using SharedStructs for SharedStructs.Result;
    using SharedStructs for SharedStructs.ValidationResult;

    // Events for important state changes
    event DealStatusChanged(string indexed dealId, SharedStructs.DealStatusEnum status);
    event ValidationResultStatusChanged(
        string indexed validationResultId, SharedStructs.ValidationResultStatusEnum status
    );
    event ResultStatusChanged(string indexed resultId, SharedStructs.ResultStatusEnum status);
    event DealSaved(string indexed dealId, address jobCreator, address resourceProvider);
    event ResultSaved(string indexed resultId, string dealId);
    event ValidationResultSaved(string indexed validationResultId, string resultId, address validator);
    event ControllerRoleGranted(address indexed account, address indexed sender);
    event ControllerRoleRevoked(address indexed account, address indexed sender);

    // Mappings to store deal, validationResult, and result data
    // TODO: can we make this bytes32 to make it more gas-efficient?
    mapping(string => SharedStructs.Deal) private deals;
    mapping(string => SharedStructs.ValidationResult) private validationResults;
    mapping(string => SharedStructs.Result) private results;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial controller
     */
    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
    }

    /**
     * @dev Grants the controller role to an account
     * @param account The address to grant the controller role to
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function grantControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Cannot grant role to zero address");
        require(!hasRole(SharedStructs.CONTROLLER_ROLE, account), "Account already has controller role");
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revokes the controller role from an account
     * @param account The address to revoke the controller role from
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function revokeControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Cannot revoke role from zero address");
        require(hasRole(SharedStructs.CONTROLLER_ROLE, account), "Account does not have controller role");
        require(account != msg.sender, "Cannot revoke own controller role");
        _revokeRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Checks if an account has the controller role
     * @param account The address to check
     * @return bool True if the account has the controller role
     */
    function hasControllerRole(address account) external view returns (bool) {
        return hasRole(SharedStructs.CONTROLLER_ROLE, account);
    }

    /**
     * @dev Changes the status of a deal object
     */
    function changeDealStatus(string memory dealId, SharedStructs.DealStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        require(bytes(dealId).length > 0, "Deal ID cannot be empty");
        SharedStructs.Deal storage deal = deals[dealId];
        require(deal.timestamp != 0, "Deal does not exist");
        deal.status = status;
        emit DealStatusChanged(dealId, status);
        return true;
    }

    /**
     * @dev Changes the status of a validation result
     */
    function changeValidationResultStatus(
        string memory validationResultId,
        SharedStructs.ValidationResultStatusEnum status
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        require(bytes(validationResultId).length > 0, "Validation result ID cannot be empty");
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        require(validationResult.timestamp != 0, "Validation result does not exist");
        validationResult.status = status;
        emit ValidationResultStatusChanged(validationResultId, status);
        return true;
    }

    /**
     * @dev Changes the status of a result object
     */
    function changeResultStatus(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        require(bytes(resultId).length > 0, "Result ID cannot be empty");
        SharedStructs.Result storage result = results[resultId];
        require(result.timestamp != 0, "Result does not exist");
        result.status = status;
        emit ResultStatusChanged(resultId, status);
        return true;
    }

    /**
     * @dev Returns the Result object associated with the resultId
     */
    function getResult(string memory resultId) external view returns (SharedStructs.Result memory) {
        require(bytes(resultId).length > 0, "Result ID cannot be empty");
        SharedStructs.Result memory result = results[resultId];
        require(result.timestamp != 0, "Result does not exist");
        return result;
    }

    /**
     * @dev Saves a Result Object
     */
    function saveResult(string memory resultId, SharedStructs.Result memory result)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        require(bytes(resultId).length > 0, "Result ID cannot be empty");
        require(bytes(result.dealId).length > 0, "Deal ID cannot be empty");
        require(bytes(result.resultCID).length > 0, "Result CID cannot be empty");
        result.timestamp = block.timestamp;
        results[resultId] = result;
        emit ResultSaved(resultId, result.dealId);
        return true;
    }

    /**
     * @dev Returns the Deal object associated with the dealId
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        require(bytes(dealId).length > 0, "Deal ID cannot be empty");
        SharedStructs.Deal memory deal = deals[dealId];
        require(deal.timestamp != 0, "Deal does not exist");
        return deal;
    }

    /**
     * @dev Saves a Deal Object with a status
     */
    function saveDeal(string memory dealId, SharedStructs.Deal memory deal)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        require(bytes(dealId).length > 0, "Deal ID cannot be empty");
        require(deal.jobCreator != address(0), "Invalid job creator address");
        require(deal.resourceProvider != address(0), "Invalid resource provider address");
        require(deal.jobCreator != deal.resourceProvider, "Job creator and resource provider cannot be the same");
        deal.timestamp = block.timestamp;
        deals[dealId] = deal;
        emit DealSaved(dealId, deal.jobCreator, deal.resourceProvider);
        return true;
    }

    /**
     * @dev Gets a validation result object
     */
    function getValidationResult(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResult memory)
    {
        require(bytes(validationResultId).length > 0, "Validation result ID cannot be empty");
        SharedStructs.ValidationResult memory validationResult = validationResults[validationResultId];
        require(validationResult.timestamp != 0, "Validation result does not exist");
        return validationResult;
    }

    /**
     * @dev Saves a validation result object with a status
     */
    function saveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        require(bytes(validationResultId).length > 0, "Validation result ID cannot be empty");
        require(bytes(validationResult.resultId).length > 0, "Result ID cannot be empty");
        require(bytes(validationResult.validationCID).length > 0, "Validation CID cannot be empty");
        require(validationResult.validator != address(0), "Invalid validator address");
        validationResult.timestamp = block.timestamp;
        validationResults[validationResultId] = validationResult;
        emit ValidationResultSaved(validationResultId, validationResult.resultId, validationResult.validator);
        return true;
    }

    /**
     * @dev Check the status of a deal
     */
    function checkDealStatus(string memory dealId) external view returns (SharedStructs.DealStatusEnum) {
        require(bytes(dealId).length > 0, "Deal ID cannot be empty");
        SharedStructs.Deal storage deal = deals[dealId];
        require(deal.timestamp != 0, "Deal does not exist");
        return deal.status;
    }

    /**
     * @dev Check the status of a validation result
     */
    function checkValidationResultStatus(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResultStatusEnum)
    {
        require(bytes(validationResultId).length > 0, "Validation result ID cannot be empty");
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        require(validationResult.timestamp != 0, "Validation result does not exist");
        return validationResult.status;
    }

    /**
     * @dev Check the status of a result
     */
    function checkResultStatus(string memory resultId) external view returns (SharedStructs.ResultStatusEnum) {
        require(bytes(resultId).length > 0, "Result ID cannot be empty");
        SharedStructs.Result storage result = results[resultId];
        require(result.timestamp != 0, "Result does not exist");
        return result.status;
    }
}
