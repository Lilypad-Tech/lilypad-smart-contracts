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

    // Version
    string public version;

    // Custom Errors
    error ZeroAddressNotAllowed();
    error RoleAlreadyAssigned();
    error RoleNotFound();
    error CannotRevokeOwnRole();

    error DealNotFound();
    error ValidationResultNotFound();
    error ResultNotFound();

    error EmptyCID(); // For empty CID checks

    error InvalidAddress(); // For all invalid address checks
    error SameAddressNotAllowed(); // For job creator/provider check

    // Add these new custom errors
    error EmptyResultId();
    error EmptyDealId();
    error EmptyValidationResultId();
    error InvalidJobCreatorAddress();
    error InvalidResourceProviderAddress();
    error InvalidValidatorAddress();

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
        version = "1.0.0";
    }

    /**
     * @dev Returns the current version of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    /**
     * @dev Grants the controller role to an account
     * @param account The address to grant the controller role to
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function grantControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddressNotAllowed();
        if (hasRole(SharedStructs.CONTROLLER_ROLE, account)) revert RoleAlreadyAssigned();
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revokes the controller role from an account
     * @param account The address to revoke the controller role from
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function revokeControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert ZeroAddressNotAllowed();
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, account)) revert RoleNotFound();
        if (account == msg.sender) revert CannotRevokeOwnRole();

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
        if (bytes(dealId).length == 0) revert EmptyDealId();
        SharedStructs.Deal storage deal = deals[dealId];
        if (deal.timestamp == 0) revert DealNotFound();
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
        if (bytes(validationResultId).length == 0) revert EmptyValidationResultId();
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert ValidationResultNotFound();
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
        if (bytes(resultId).length == 0) revert EmptyResultId();
        SharedStructs.Result storage result = results[resultId];
        if (result.timestamp == 0) revert ResultNotFound();
        result.status = status;
        emit ResultStatusChanged(resultId, status);
        return true;
    }

    /**
     * @dev Returns the Result object associated with the resultId
     */
    function getResult(string memory resultId) external view returns (SharedStructs.Result memory) {
        if (bytes(resultId).length == 0) revert EmptyResultId();
        SharedStructs.Result memory result = results[resultId];
        if (result.timestamp == 0) revert ResultNotFound();
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
        if (bytes(resultId).length == 0) revert EmptyResultId();
        if (bytes(result.dealId).length == 0) revert EmptyDealId();
        if (bytes(result.resultCID).length == 0) revert EmptyCID();
        result.timestamp = block.timestamp;
        results[resultId] = result;
        emit ResultSaved(resultId, result.dealId);
        return true;
    }

    /**
     * @dev Returns the Deal object associated with the dealId
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        if (bytes(dealId).length == 0) revert EmptyDealId();
        SharedStructs.Deal memory deal = deals[dealId];
        if (deal.timestamp == 0) revert DealNotFound();
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
        if (bytes(dealId).length == 0) revert EmptyDealId();
        if (deal.jobCreator == address(0)) revert InvalidJobCreatorAddress();
        if (deal.resourceProvider == address(0)) revert InvalidResourceProviderAddress();
        if (deal.jobCreator == deal.resourceProvider) revert SameAddressNotAllowed();
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
        if (bytes(validationResultId).length == 0) revert EmptyValidationResultId();
        SharedStructs.ValidationResult memory validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert ValidationResultNotFound();
        return validationResult;
    }

    /**
     * @dev Saves a validation result object with a status
     */
    function saveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (bytes(validationResultId).length == 0) revert EmptyValidationResultId();
        if (bytes(validationResult.resultId).length == 0) revert EmptyResultId();
        if (bytes(validationResult.validationCID).length == 0) revert EmptyCID();
        if (validationResult.validator == address(0)) revert InvalidValidatorAddress();
        validationResult.timestamp = block.timestamp;
        validationResults[validationResultId] = validationResult;
        emit ValidationResultSaved(validationResultId, validationResult.resultId, validationResult.validator);
        return true;
    }

    /**
     * @dev Check the status of a deal
     */
    function checkDealStatus(string memory dealId) external view returns (SharedStructs.DealStatusEnum) {
        if (bytes(dealId).length == 0) revert EmptyDealId();
        SharedStructs.Deal storage deal = deals[dealId];
        if (deal.timestamp == 0) revert DealNotFound();
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
        if (bytes(validationResultId).length == 0) revert EmptyValidationResultId();
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert ValidationResultNotFound();
        return validationResult.status;
    }

    /**
     * @dev Check the status of a result
     */
    function checkResultStatus(string memory resultId) external view returns (SharedStructs.ResultStatusEnum) {
        if (bytes(resultId).length == 0) revert EmptyResultId();
        SharedStructs.Result storage result = results[resultId];
        if (result.timestamp == 0) revert ResultNotFound();
        return result.status;
    }
}
