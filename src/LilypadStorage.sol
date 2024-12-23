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
    error LilypadStorage__ZeroAddressNotAllowed();
    error LilypadStorage__RoleAlreadyAssigned();
    error LilypadStorage__RoleNotFound();
    error LilypadStorage__CannotRevokeOwnRole();

    error LilypadStorage__DealNotFound();
    error LilypadStorage__ValidationResultNotFound();
    error LilypadStorage__ResultNotFound();

    error LilypadStorage__EmptyCID(); // For empty CID checks

    error LilypadStorage__InvalidAddress(); // For all invalid address checks
    error LilypadStorage__SameAddressNotAllowed(); // For job creator/provider check

    error LilypadStorage__EmptyResultId();
    error LilypadStorage__EmptyDealId();
    error LilypadStorage__EmptyValidationResultId();
    error LilypadStorage__InvalidJobCreatorAddress();
    error LilypadStorage__InvalidResourceProviderAddress();
    error LilypadStorage__InvalidValidatorAddress();

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
     * @return version string of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    /**
     * @dev Grants the controller role to an account
     * @param account address to grant the controller role to
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function grantControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert LilypadStorage__ZeroAddressNotAllowed();
        if (hasRole(SharedStructs.CONTROLLER_ROLE, account)) revert LilypadStorage__RoleAlreadyAssigned();
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revokes the controller role from an account
     * @param account address to revoke the controller role from
     * @notice Only accounts with DEFAULT_ADMIN_ROLE can call this function
     */
    function revokeControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) revert LilypadStorage__ZeroAddressNotAllowed();
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, account)) revert LilypadStorage__RoleNotFound();
        if (account == msg.sender) revert LilypadStorage__CannotRevokeOwnRole();

        _revokeRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Checks if an account has the controller role
     * @param account address to check
     * @return bool Indicates whether the account has the controller role
     */
    function hasControllerRole(address account) external view returns (bool) {
        return hasRole(SharedStructs.CONTROLLER_ROLE, account);
    }

    /**
     * @dev Changes the status of a deal object
     * @param dealId unique identifier of the deal to update
     * @param status new status to assign to the deal (enum)
     * @return bool Indicates whether the status change was successful
     * @notice This function is restricted to the controller role
     */
    function changeDealStatus(string memory dealId, SharedStructs.DealStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        SharedStructs.Deal storage deal = deals[dealId];
        if (deal.timestamp == 0) revert LilypadStorage__DealNotFound();
        deal.status = status;
        emit DealStatusChanged(dealId, status);
        return true;
    }

    /**
     * @dev Changes the status of a validation result
     * @param validationResultId unique identifier of the validation result to update
     * @param status new validation result status to assign (enum)
     * @return bool Indicates whether the status change was successful
     * @notice This function is restricted to the controller role
     */
    function changeValidationResultStatus(
        string memory validationResultId,
        SharedStructs.ValidationResultStatusEnum status
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (bytes(validationResultId).length == 0) revert LilypadStorage__EmptyValidationResultId();
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert LilypadStorage__ValidationResultNotFound();
        validationResult.status = status;
        emit ValidationResultStatusChanged(validationResultId, status);
        return true;
    }

    /**
     * @dev Changes the status of a result object
     * @param resultId unique identifier of the result to update
     * @param status new result status to assign (enum)
     * @return bool Indicates whether the status change was successful
     * @notice This function is restricted to the controller role
     */
    function changeResultStatus(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        SharedStructs.Result storage result = results[resultId];
        if (result.timestamp == 0) revert LilypadStorage__ResultNotFound();
        result.status = status;
        emit ResultStatusChanged(resultId, status);
        return true;
    }

    /**
     * @dev Returns the Result object associated with the resultId
     * @param resultId unique identifier of the result
     * @return Result struct associated with the result ID
     */
    function getResult(string memory resultId) external view returns (SharedStructs.Result memory) {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        SharedStructs.Result memory result = results[resultId];
        if (result.timestamp == 0) revert LilypadStorage__ResultNotFound();
        return result;
    }

    /**
     * @dev Saves a Result Object
     * @param resultId unique identifier of the result
     * @param result Result struct to be saved
     * @return bool Indicates whether the result was successfully saved
     * @notice This function is restricted to the controller role
     */
    function saveResult(string memory resultId, SharedStructs.Result memory result)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        if (bytes(result.dealId).length == 0) revert LilypadStorage__EmptyDealId();
        if (bytes(result.resultCID).length == 0) revert LilypadStorage__EmptyCID();
        result.timestamp = block.timestamp;
        results[resultId] = result;
        emit ResultSaved(resultId, result.dealId);
        return true;
    }

    /**
     * @dev Returns the Deal object associated with the dealId
     * @param dealId unique identifier of the deal
     * @return Deal struct associated with the deal ID
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        SharedStructs.Deal memory deal = deals[dealId];
        if (deal.timestamp == 0) revert LilypadStorage__DealNotFound();
        return deal;
    }

    /**
     * @dev Saves a Deal Object with a status
     * @param dealId unique identifier of the deal
     * @param deal Deal struct to be saved
     * @return bool Indicates whether the deal was successfully saved
     * @notice This function is restricted to the controller role
     */
    function saveDeal(string memory dealId, SharedStructs.Deal memory deal)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        if (deal.jobCreator == address(0)) revert LilypadStorage__InvalidJobCreatorAddress();
        if (deal.resourceProvider == address(0)) revert LilypadStorage__InvalidResourceProviderAddress();
        if (deal.jobCreator == deal.resourceProvider) revert LilypadStorage__SameAddressNotAllowed();
        deal.timestamp = block.timestamp;
        deals[dealId] = deal;
        emit DealSaved(dealId, deal.jobCreator, deal.resourceProvider);
        return true;
    }

    /**
     * @dev Gets a validation result object
     * @param validationResultId unique identifier of the validation result
     * @return ValidationResult struct associated with the validation result ID
     */
    function getValidationResult(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResult memory)
    {
        if (bytes(validationResultId).length == 0) revert LilypadStorage__EmptyValidationResultId();
        SharedStructs.ValidationResult memory validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert LilypadStorage__ValidationResultNotFound();
        return validationResult;
    }

    /**
     * @dev Saves a validation result object with a status
     * @param validationResultId unique identifier of the validation result
     * @param validationResult ValidationResult struct to be saved
     * @return bool Indicates whether the validation result was successfully saved
     * @notice This function is restricted to the controller role
     */
    function saveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (bytes(validationResultId).length == 0) revert LilypadStorage__EmptyValidationResultId();
        if (bytes(validationResult.resultId).length == 0) revert LilypadStorage__EmptyResultId();
        if (bytes(validationResult.validationCID).length == 0) revert LilypadStorage__EmptyCID();
        if (validationResult.validator == address(0)) revert LilypadStorage__InvalidValidatorAddress();
        validationResult.timestamp = block.timestamp;
        validationResults[validationResultId] = validationResult;
        emit ValidationResultSaved(validationResultId, validationResult.resultId, validationResult.validator);
        return true;
    }

    /**
     * @dev Check the status of a deal
     * @param dealId unique identifier of the deal
     * @return DealStatusEnum type according to the deals current status
     */
    function checkDealStatus(string memory dealId) external view returns (SharedStructs.DealStatusEnum) {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        SharedStructs.Deal storage deal = deals[dealId];
        if (deal.timestamp == 0) revert LilypadStorage__DealNotFound();
        return deal.status;
    }

    /**
     * @dev Check the status of a validation result
     * @param validationResultId unique identifier of the validation result
     * @return ValidationResultStatusEnum type according to the validation result's current status
     */
    function checkValidationResultStatus(string memory validationResultId)
        external
        view
        returns (SharedStructs.ValidationResultStatusEnum)
    {
        if (bytes(validationResultId).length == 0) revert LilypadStorage__EmptyValidationResultId();
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert LilypadStorage__ValidationResultNotFound();
        return validationResult.status;
    }

    /**
     * @dev Check the status of a result
     * @param resultId unique identifier of the result
     * @return ResultStatusEnum type according to the result's current status
     */
    function checkResultStatus(string memory resultId) external view returns (SharedStructs.ResultStatusEnum) {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        SharedStructs.Result storage result = results[resultId];
        if (result.timestamp == 0) revert LilypadStorage__ResultNotFound();
        return result.status;
    }
}
