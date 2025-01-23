// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILilypadValidation} from "./interfaces/ILilypadValidation.sol";
import {ILilypadStorage} from "./interfaces/ILilypadStorage.sol";
import {ILilypadUser} from "./interfaces/ILilypadUser.sol";
import {SharedStructs} from "./SharedStructs.sol";

// TODO: send the validationPoolAmount to this contract from LilypadPaymentEngine

/**
 * @title LilypadValidation
 * @dev Implementation of validation contract for Lilypad platform
 */
contract LilypadValidation is Initializable, ILilypadValidation, AccessControlUpgradeable {
    // Version
    string public version;

    // Contract references
    ILilypadStorage public lilypadStorage;
    ILilypadUser public lilypadUser;

    // Custom Errors
    error LilypadValidation__ZeroAddressNotAllowed();
    error LilypadValidation__StorageNotSet();
    error LilypadValidation__UserContractNotSet();
    error LilypadValidation__InvalidDeal();
    error LilypadValidation__InvalidResult();
    error LilypadValidation__InvalidValidation();
    error LilypadValidation__NoValidatorsAvailable();
    error LilypadValidation__NotValidator();
    error LilypadValidation__RoleAlreadyAssigned();
    error LilypadValidation__RoleNotFound();
    error LilypadValidation__CannotRevokeOwnRole();

    // Events
    event ValidationRequested(string dealId, string resultId, address jobCreator);
    event ValidationProcessed(string validationResultId, SharedStructs.ValidationResultStatusEnum status);
    event StorageContractSet(address storageContract);
    event UserContractSet(address userContract);
    event ControllerRoleGranted(address indexed account, address indexed sender);
    event ControllerRoleRevoked(address indexed account, address indexed sender);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial controller
     * @notice
     * - Initializes the AccessControl contract
     * - Grants DEFAULT_ADMIN_ROLE to the deployer
     * - Grants CONTROLLER_ROLE to the deployer
     * - Sets initial version to "1.0.0"
     */
    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
        version = "1.0.0";
    }

    /**
     * @dev Returns the current version of the contract
     * @notice
     * - Returns the semantic version string of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    /**
     * @dev Sets the storage contract address
     * @notice
     * - Only accounts with DEFAULT_ADMIN_ROLE can call this function
     * - Reverts if storageAddress is zero address
     * - Emits a StorageContractSet event upon successful setting
     */
    function setStorageContract(address storageAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (storageAddress == address(0)) {
            revert LilypadValidation__ZeroAddressNotAllowed();
        }
        lilypadStorage = ILilypadStorage(storageAddress);
        emit StorageContractSet(storageAddress);
    }

    /**
     * @dev Sets the user contract address
     * @notice
     * - Only accounts with DEFAULT_ADMIN_ROLE can call this function
     * - Reverts if userAddress is zero address
     * - Emits a UserContractSet event upon successful setting
     */
    function setUserContract(address userAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (userAddress == address(0)) {
            revert LilypadValidation__ZeroAddressNotAllowed();
        }
        lilypadUser = ILilypadUser(userAddress);
        emit UserContractSet(userAddress);
    }

    /**
     * @dev Grants the controller role to an account
     * @notice
     * - Only accounts with DEFAULT_ADMIN_ROLE can call this function
     * - Reverts if account is zero address
     * - Reverts if account already has controller role
     * - Emits a ControllerRoleGranted event upon successful grant
     */
    function grantControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) {
            revert LilypadValidation__ZeroAddressNotAllowed();
        }
        if (hasRole(SharedStructs.CONTROLLER_ROLE, account)) {
            revert LilypadValidation__RoleAlreadyAssigned();
        }
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revokes the controller role from an account
     * @notice
     * - Only accounts with DEFAULT_ADMIN_ROLE can call this function
     * - Reverts if account is zero address
     * - Reverts if account doesn't have controller role
     * - Reverts if trying to revoke own role
     * - Emits a ControllerRoleRevoked event upon successful revocation
     */
    function revokeControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) {
            revert LilypadValidation__ZeroAddressNotAllowed();
        }
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, account)) {
            revert LilypadValidation__RoleNotFound();
        }
        if (account == msg.sender) {
            revert LilypadValidation__CannotRevokeOwnRole();
        }
        _revokeRole(SharedStructs.CONTROLLER_ROLE, account);
        emit ControllerRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Checks if an account has the controller role
     * @notice View function that returns true if the account has CONTROLLER_ROLE
     */
    function hasControllerRole(address account) external view returns (bool) {
        return hasRole(SharedStructs.CONTROLLER_ROLE, account);
    }

    /**
     * @dev Requests validation for a deal result
     * @notice
     * - Only accounts with CONTROLLER_ROLE can call this function
     * - Reverts if storage or user contract is not set
     * - Reverts if deal or result is invalid
     * - Reverts if validation struct is invalid (including empty validationResultId)
     * - Reverts if no validators are available
     * - Uses pseudo-random selection to choose a validator
     * - Emits a ValidationRequested event upon successful request
     */
    function requestValidation(
        SharedStructs.Deal memory deal,
        SharedStructs.Result memory result,
        SharedStructs.ValidationResult memory validation
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (address(lilypadStorage) == address(0)) {
            revert LilypadValidation__StorageNotSet();
        }
        if (address(lilypadUser) == address(0)) {
            revert LilypadValidation__UserContractNotSet();
        }

        // Validate deal and result
        if (bytes(deal.dealId).length == 0 || deal.jobCreator == address(0) || deal.resourceProvider == address(0)) {
            revert LilypadValidation__InvalidDeal();
        }
        if (bytes(result.resultId).length == 0 || bytes(result.dealId).length == 0) {
            revert LilypadValidation__InvalidResult();
        }

        // Verify deal exists and matches
        SharedStructs.Deal memory storedDeal = lilypadStorage.getDeal(deal.dealId);
        if (storedDeal.timestamp == 0 || storedDeal.jobCreator != deal.jobCreator) {
            revert LilypadValidation__InvalidDeal();
        }

        // Verify result exists and matches deal
        SharedStructs.Result memory storedResult = lilypadStorage.getResult(result.resultId);
        if (storedResult.timestamp == 0 || keccak256(bytes(storedResult.dealId)) != keccak256(bytes(deal.dealId))) {
            revert LilypadValidation__InvalidResult();
        }

        // Get list of validators from user contract
        address[] memory validators = getValidators();
        if (validators.length == 0) {
            revert LilypadValidation__NoValidatorsAvailable();
        }

        // Select a validator using pseudo-random selection
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, validators.length))
        ) % validators.length;

        // Create validation record using the provided validation as base
        validation.resultId = result.resultId;
        validation.status = SharedStructs.ValidationResultStatusEnum.ValidationPending;
        validation.timestamp = 0; // Will be set by storage contract
        validation.validator = validators[randomIndex];

        // Validate that validationResultId is provided
        if (bytes(validation.validationResultId).length == 0) {
            revert LilypadValidation__InvalidValidation();
        }

        bool success = lilypadStorage.saveValidationResult(validation.validationResultId, validation);
        if (!success) {
            revert LilypadValidation__InvalidValidation();
        }

        emit ValidationRequested(deal.dealId, result.resultId, deal.jobCreator);
        return true;
    }

    /**
     * @dev Processes a validation result
     * @notice
     * - Only accounts with CONTROLLER_ROLE can call this function
     * - Reverts if storage or user contract is not set
     * - Reverts if validation result is invalid
     * - Reverts if validator is not registered
     * - Emits a ValidationProcessed event upon successful processing
     */
    function processValidation(SharedStructs.ValidationResult memory validation)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (address(lilypadStorage) == address(0)) {
            revert LilypadValidation__StorageNotSet();
        }
        if (address(lilypadUser) == address(0)) {
            revert LilypadValidation__UserContractNotSet();
        }

        // Validate validation result
        if (
            bytes(validation.validationResultId).length == 0 || bytes(validation.resultId).length == 0
                || validation.validator == address(0)
        ) {
            revert LilypadValidation__InvalidValidation();
        }

        // Verify validator is registered
        if (!lilypadUser.hasRole(validation.validator, SharedStructs.UserType.Validator)) {
            revert LilypadValidation__NotValidator();
        }

        // Save validation result
        bool success = lilypadStorage.saveValidationResult(validation.validationResultId, validation);
        if (!success) {
            revert LilypadValidation__InvalidValidation();
        }

        emit ValidationProcessed(validation.validationResultId, validation.status);
        return true;
    }

    /**
     * @dev Retrieves the list of validators registered in the system
     * @notice
     * - Reverts if user contract is not set
     * - Uses a single pass through all users with a fixed-size array
     * - Resizes the array at the end to match the actual validator count
     */
    function getValidators() public view returns (address[] memory) {
        if (address(lilypadUser) == address(0)) {
            revert LilypadValidation__UserContractNotSet();
        }

        return lilypadUser.getValidators();
    }
}
