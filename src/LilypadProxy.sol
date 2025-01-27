// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ILilypadProxy} from "./interfaces/ILilypadProxy.sol";
import {ILilypadStorage} from "./interfaces/ILilypadStorage.sol";
import {ILilypadUser} from "./interfaces/ILilypadUser.sol";
import {ILilypadValidation} from "./interfaces/ILilypadValidation.sol";
import {ILilypadPaymentEngine} from "./interfaces/ILilypadPaymentEngine.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadProxy
 * @dev Implementation of the main orchestration contract for the Lilypad platform
 */
contract LilypadProxy is ILilypadProxy, Initializable, AccessControlUpgradeable {
    // Version
    string public version;

    // Contract references
    ILilypadStorage public lilypadStorage;
    ILilypadUser public lilypadUser;
    ILilypadValidation public lilypadValidation;
    ILilypadPaymentEngine public lilypadPaymentEngine;

    // Additional contract addresses
    address public paymentAddress;
    address public tokenAddress;
    address public vestingAddress;

    // Custom Errors
    error LilypadProxy__ZeroAddressNotAllowed();
    error LilypadProxy__InvalidDeal();
    error LilypadProxy__InvalidResult();
    error LilypadProxy__InvalidValidation();
    error LilypadProxy__NotController();
    error LilypadProxy__PaymentFailed();
    error LilypadProxy__ValidationRequestFailed();
    error LilypadProxy__EmptyDealId();
    error LilypadProxy__EmptyResultId();
    error LilypadProxy__EmptyValidationId();
    error LilypadProxy__EmptyModuleName();

    // Events for address updates
    event PaymentAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event StorageAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event UserAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event TokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ValidationAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event VestingAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // Events
    event JobPaymentCollateral(address indexed jobCreatorAddress, string module, uint256 amount);

    event ValidationCollateralPayment(address indexed validatorAddress, uint256 amount);

    event ResourceProviderCollateralPayment(address indexed resourceProviderAddress, uint256 amount);

    event ValidationRequested(address indexed jobCreatorAddress, string module, uint256 amount);

    event DealCreated(string dealId, address indexed jobCreatorAddress, address indexed resourceProviderAddress);

    event DealUpdated(
        string dealId,
        address indexed jobCreatorAddress,
        address indexed resourceProviderAddress,
        SharedStructs.DealStatusEnum dealStatus
    );

    event ResultUpdated(
        string resultId,
        address indexed jobCreatorAddress,
        address indexed resourceProviderAddress,
        SharedStructs.ResultStatusEnum resultStatus
    );

    event ValidationUpdated(
        string verificationId,
        address indexed jobCreatorAddress,
        address indexed resourceProviderAddress,
        address indexed validatorAddress,
        SharedStructs.ValidationResultStatusEnum validationStatus
    );

    event JobResultPosted(string dealId, address indexed jobCreatorAddress, address indexed resourceProviderAddress);

    event ValidationResultPosted(
        string dealId,
        address indexed jobCreatorAddress,
        address indexed resourceProviderAddress,
        address indexed validatorAddress
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial controller
     * @param storageAddress The address of the storage contract
     * @param userAddress The address of the user contract
     * @param validationAddress The address of the validation contract
     * @param paymentEngineAddress The address of the payment engine contract
     */
    function initialize(
        address storageAddress,
        address userAddress,
        address validationAddress,
        address paymentEngineAddress
    ) public initializer {
        if (storageAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (userAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (validationAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (paymentEngineAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);

        lilypadStorage = ILilypadStorage(storageAddress);
        lilypadUser = ILilypadUser(userAddress);
        lilypadValidation = ILilypadValidation(validationAddress);
        lilypadPaymentEngine = ILilypadPaymentEngine(paymentEngineAddress);

        version = "1.0.0";
    }

    /**
     * @dev Returns the current version of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Job Creators to pay for jobs
     * - Reverts if `moduleName` is empty
     * - Reverts if `payee` is the zero address
     * - Reverts if payment fails
     * - Emits a `JobPaymentCollateral` event upon successful payment
     */
    function acceptJobPayment(string memory moduleName, uint256 amount, address payee) external returns (bool) {
        if (bytes(moduleName).length == 0) revert LilypadProxy__EmptyModuleName();
        if (payee == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();

        bool success = lilypadPaymentEngine.payEscrow(payee, SharedStructs.PaymentReason.JobPayment, amount);
        if (!success) revert LilypadProxy__PaymentFailed();

        emit JobPaymentCollateral(payee, moduleName, amount);
        return true;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Verifiers to pay collateral for running validations
     * - Reverts if `validatorAddress` is the zero address
     * - Reverts if payment fails
     * - Emits a `ValidationCollateralPayment` event upon successful payment
     */
    function acceptValidationCollateral(uint256 amount, address validatorAddress) external returns (bool) {
        if (validatorAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();

        bool success =
            lilypadPaymentEngine.payEscrow(validatorAddress, SharedStructs.PaymentReason.ValidiationCollateral, amount);
        if (!success) revert LilypadProxy__PaymentFailed();

        emit ValidationCollateralPayment(validatorAddress, amount);
        return true;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Resource Providers to pay or top up their collateral
     * - Reverts if `resourceProviderAddress` is the zero address
     * - Reverts if payment fails
     * - Emits a `ResourceProviderCollateralPayment` event upon successful payment
     */
    function acceptResourceProviderCollateral(uint256 amount, address resourceProviderAddress)
        external
        returns (bool)
    {
        if (resourceProviderAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();

        bool success = lilypadPaymentEngine.payEscrow(
            resourceProviderAddress, SharedStructs.PaymentReason.ResourceProviderCollateral, amount
        );
        if (!success) revert LilypadProxy__PaymentFailed();

        emit ResourceProviderCollateralPayment(resourceProviderAddress, amount);
        return true;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Job Creators to request and pay for validation
     * - Reverts if `requestorAddress` is the zero address
     * - Reverts if `moduleName` is empty
     * - Reverts if payment fails
     * - Emits a `ValidationRequested` event upon successful request
     */
    function requestValidation(address requestorAddress, string memory moduleName, uint256 amount)
        external
        returns (SharedStructs.ValidationResult memory)
    {
        if (requestorAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (bytes(moduleName).length == 0) revert LilypadProxy__EmptyModuleName();

        bool success =
            lilypadPaymentEngine.payEscrow(requestorAddress, SharedStructs.PaymentReason.ValidationFee, amount);
        if (!success) revert LilypadProxy__PaymentFailed();

        emit ValidationRequested(requestorAddress, moduleName, amount);

        // TODO: Implement validation request logic through lilypadValidation
        revert LilypadProxy__ValidationRequestFailed();
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Job Creators to read their job execution results
     * - Reverts if `dealId` is empty
     */
    function getResult(string memory dealId) external view returns (SharedStructs.Result memory) {
        if (bytes(dealId).length == 0) revert LilypadProxy__EmptyDealId();
        return lilypadStorage.getResult(dealId);
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by the Lilypad Admin Account (Solver) to set job results
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if `resultId` is empty
     * - Reverts if `dealId` is empty
     * - Emits a `JobResultPosted` event upon successful save
     */
    function setResult(SharedStructs.Result memory result)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(result.resultId).length == 0) revert LilypadProxy__EmptyResultId();
        if (bytes(result.dealId).length == 0) revert LilypadProxy__EmptyDealId();
        bool success = lilypadStorage.saveResult(result.resultId, result);
        if (success) {
            SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);
            emit JobResultPosted(result.dealId, deal.jobCreator, deal.resourceProvider);
        }
        return success;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Job Creators to read deal information
     * - Reverts if `dealId` is empty
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        if (bytes(dealId).length == 0) revert LilypadProxy__EmptyDealId();
        return lilypadStorage.getDeal(dealId);
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by the Lilypad Admin Account (Solver) to set deals
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if `dealId` is empty
     * - Emits a `DealCreated` event upon successful save
     */
    function setDeal(SharedStructs.Deal memory deal) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (bytes(deal.dealId).length == 0) revert LilypadProxy__EmptyDealId();
        bool success = lilypadStorage.saveDeal(deal.dealId, deal);
        if (success) {
            emit DealCreated(deal.dealId, deal.jobCreator, deal.resourceProvider);
        }
        return success;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by the Lilypad Admin Account (Solver) to update deal states
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if `dealId` is empty
     * - Emits a `DealUpdated` event upon successful update
     */
    function updateDealState(string memory dealId, SharedStructs.DealStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(dealId).length == 0) revert LilypadProxy__EmptyDealId();
        bool success = lilypadStorage.changeDealStatus(dealId, status);
        if (success) {
            SharedStructs.Deal memory deal = lilypadStorage.getDeal(dealId);
            emit DealUpdated(dealId, deal.jobCreator, deal.resourceProvider, status);
        }
        return success;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by the Lilypad Admin Account (Solver) to update result states
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if `resultId` is empty
     * - Emits a `ResultUpdated` event upon successful update
     */
    function updateResultState(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(resultId).length == 0) revert LilypadProxy__EmptyResultId();
        bool success = lilypadStorage.changeResultStatus(resultId, status);
        if (success) {
            SharedStructs.Result memory result = lilypadStorage.getResult(resultId);
            SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);
            emit ResultUpdated(resultId, deal.jobCreator, deal.resourceProvider, status);
        }
        return success;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by the Lilypad Admin Account (Solver) to update validation states
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if `validationId` is empty
     * - Emits a `ValidationUpdated` event upon successful update
     */
    function updateValidationState(string memory validationId, SharedStructs.ValidationResultStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(validationId).length == 0) revert LilypadProxy__EmptyValidationId();
        bool success = lilypadStorage.changeValidationResultStatus(validationId, status);
        if (success) {
            SharedStructs.ValidationResult memory validation = lilypadStorage.getValidationResult(validationId);
            SharedStructs.Result memory result = lilypadStorage.getResult(validation.resultId);
            SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);
            emit ValidationUpdated(validationId, deal.jobCreator, deal.resourceProvider, validation.validator, status);
        }
        return success;
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by Job Creators to read validation results
     * - Reverts if `validationId` is empty
     */
    function getValidationResult(string memory validationId)
        external
        view
        returns (SharedStructs.ValidationResult memory)
    {
        if (bytes(validationId).length == 0) revert LilypadProxy__EmptyValidationId();
        return lilypadStorage.getValidationResult(validationId);
    }

    /**
     * @inheritdoc ILilypadProxy
     * @notice
     * - This function is intended to be called by the Lilypad Admin Account (Solver) to set validation results
     * - Only accounts with the `CONTROLLER_ROLE` can call this function
     * - Reverts if `validationId` is empty
     * - Emits a `ValidationResultPosted` event upon successful save
     */
    function setValidationResult(string memory validationId, SharedStructs.ValidationResult memory verification)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(validationId).length == 0) revert LilypadProxy__EmptyValidationId();
        bool success = lilypadStorage.saveValidationResult(validationId, verification);
        if (success) {
            SharedStructs.Result memory result = lilypadStorage.getResult(verification.resultId);
            SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);
            emit ValidationResultPosted(result.dealId, deal.jobCreator, deal.resourceProvider, verification.validator);
        }
        return success;
    }

    /**
     * @dev Sets the payment address
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if `_paymentAddress` is the zero address
     * - Emits a `PaymentAddressUpdated` event upon successful update
     */
    function setPaymentAddress(address _paymentAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paymentAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        address oldAddress = paymentAddress;
        paymentAddress = _paymentAddress;
        emit PaymentAddressUpdated(oldAddress, _paymentAddress);
    }

    /**
     * @dev Sets the storage contract address
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if `_storageAddress` is the zero address
     * - Emits a `StorageAddressUpdated` event upon successful update
     */
    function setStorageAddress(address _storageAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_storageAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        address oldAddress = address(lilypadStorage);
        lilypadStorage = ILilypadStorage(_storageAddress);
        emit StorageAddressUpdated(oldAddress, _storageAddress);
    }

    /**
     * @dev Sets the user contract address
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if `_userAddress` is the zero address
     * - Emits a `UserAddressUpdated` event upon successful update
     */
    function setUserAddress(address _userAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_userAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        address oldAddress = address(lilypadUser);
        lilypadUser = ILilypadUser(_userAddress);
        emit UserAddressUpdated(oldAddress, _userAddress);
    }

    /**
     * @dev Sets the token address
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if `_tokenAddress` is the zero address
     * - Emits a `TokenAddressUpdated` event upon successful update
     */
    function setTokenAddress(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_tokenAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        address oldAddress = tokenAddress;
        tokenAddress = _tokenAddress;
        emit TokenAddressUpdated(oldAddress, _tokenAddress);
    }

    /**
     * @dev Sets the validation contract address
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if `_validationAddress` is the zero address
     * - Emits a `ValidationAddressUpdated` event upon successful update
     */
    function setValidationAddress(address _validationAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_validationAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        address oldAddress = address(lilypadValidation);
        lilypadValidation = ILilypadValidation(_validationAddress);
        emit ValidationAddressUpdated(oldAddress, _validationAddress);
    }

    /**
     * @dev Sets the vesting contract address
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if `_vestingAddress` is the zero address
     * - Emits a `VestingAddressUpdated` event upon successful update
     */
    function setVestingAddress(address _vestingAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_vestingAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        address oldAddress = vestingAddress;
        vestingAddress = _vestingAddress;
        emit VestingAddressUpdated(oldAddress, _vestingAddress);
    }

    /**
     * @dev Gets the payment address
     * @notice
     * - This is a public view function that can be called by anyone
     * @return The current payment address
     */
    function getPaymentAddress() external view returns (address) {
        return paymentAddress;
    }

    /**
     * @dev Gets the storage contract address
     * @notice
     * - This is a public view function that can be called by anyone
     * @return The current storage contract address
     */
    function getStorageAddress() external view returns (address) {
        return address(lilypadStorage);
    }

    /**
     * @dev Gets the user contract address
     * @notice
     * - This is a public view function that can be called by anyone
     * @return The current user contract address
     */
    function getUserAddress() external view returns (address) {
        return address(lilypadUser);
    }

    /**
     * @dev Gets the token address
     * @notice
     * - This is a public view function that can be called by anyone
     * @return The current token address
     */
    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Gets the validation contract address
     * @notice
     * - This is a public view function that can be called by anyone
     * @return The current validation contract address
     */
    function getValidationAddress() external view returns (address) {
        return address(lilypadValidation);
    }

    /**
     * @dev Gets the vesting contract address
     * @notice
     * - This is a public view function that can be called by anyone
     * @return The current vesting contract address
     */
    function getVestingAddress() external view returns (address) {
        return vestingAddress;
    }
}
