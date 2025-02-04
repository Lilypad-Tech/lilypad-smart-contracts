// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// Type declarations
// State variables
// errors
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILilypadProxy} from "./interfaces/ILilypadProxy.sol";
import {LilypadStorage} from "./LilypadStorage.sol";
import {LilypadPaymentEngine} from "./LilypadPaymentEngine.sol";
import {LilypadUser} from "./LilypadUser.sol";
import {LilypadValidation} from "./LilypadValidation.sol";
import {LilypadToken} from "./LilypadToken.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract LilypadProxy is ILilypadProxy, AccessControlUpgradeable {
    // State Variables
    string public version;

    address public tokenAddress;

    LilypadStorage public lilypadStorage;
    LilypadPaymentEngine public paymentEngine;
    LilypadValidation public lilypadValidation;
    LilypadUser public lilypadUser;
    LilypadToken public lilypadToken;

    // Events
    event LilypadProxy__ControllerRoleGranted(address indexed account, address indexed caller);
    event LilypadProxy__ControllerRoleRevoked(address indexed account, address indexed caller);
    event LilypadProxy__JobCreatorEscrowPayment(address indexed jobCreator, uint256 amount);
    event LilypadProxy__ResourceProviderCollateralPayment(address indexed resourceProvider, uint256 amount);
    event LilypadProxy__ValidationCollateralPayment(address indexed validator, uint256 amount);

    error LilypadProxy__ZeroAddressNotAllowed();
    error LilypadProxy__ZeroAmountNotAllowed();
    error LilypadProxy__RoleAlreadyAssigned();
    error LilypadProxy__RoleNotFound();
    error LilypadProxy__CannotRevokeOwnRole();
    error LilypadProxy__acceptJobPayment__NotJobCreator();
    error LilypadProxy__acceptResourceProviderCollateral__NotResourceProvider();
    error LilypadProxy__acceptValidationCollateral__NotValidator();
    error LilypadProxy__NotEnoughAllowance();
    error LilypadProxy__DealFailedToSave();
    error LilypadProxy__DealFailedToLockup();
    error LilypadProxy__NotAuthorizedToGetResult();
    error LilypadProxy__ResultFailedToSave();

    function initialize(
        address _storageAddress,
        address _paymentEngineAddress,
        address _validationAddress,
        address _userAddress,
        address _tokenAddress
    ) external initializer {
        if (_storageAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (_paymentEngineAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (_validationAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (_userAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (_tokenAddress == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();

        lilypadStorage = LilypadStorage(_storageAddress);
        paymentEngine = LilypadPaymentEngine(_paymentEngineAddress);
        lilypadValidation = LilypadValidation(_validationAddress);
        lilypadUser = LilypadUser(_userAddress);
        lilypadToken = LilypadToken(_tokenAddress);
        version = "1.0.0";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
    }

    function getVersion() external view returns (string memory) {
        return version;
    }

    function setStorageContract(address _storageAddress) external returns (bool) {
        lilypadStorage = LilypadStorage(_storageAddress);
        return true;
    }

    function setPaymentEngineContract(address _paymentEngineAddress) external returns (bool) {
        paymentEngine = LilypadPaymentEngine(_paymentEngineAddress);
        return true;
    }

    function setValidationContract(address _validationAddress) external returns (bool) {
        lilypadValidation = LilypadValidation(_validationAddress);
        return true;
    }

    function setUserContract(address _userAddress) external returns (bool) {
        lilypadUser = LilypadUser(_userAddress);
        return true;
    }

    /**
     * @dev Grants the controller role to a specified account
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if the `account` is the zero address
     * - Reverts if the `account` already has the controller role
     * - Emits a `ControllerRoleGranted` event upon successful role assignment
     */
    function grantControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) {
            revert LilypadProxy__ZeroAddressNotAllowed();
        }
        if (hasRole(SharedStructs.CONTROLLER_ROLE, account)) {
            revert LilypadProxy__RoleAlreadyAssigned();
        }
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit LilypadProxy__ControllerRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revokes the controller role from an account
     * @notice
     * - Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function
     * - Reverts if the `account` is the zero address
     * - Reverts if the `account` does not have the controller role
     * - Reverts if trying to revoke own role
     * - Emits a `ControllerRoleRevoked` event upon successful role revocation
     */
    function revokeControllerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) {
            revert LilypadProxy__ZeroAddressNotAllowed();
        }
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, account)) {
            revert LilypadProxy__RoleNotFound();
        }
        if (account == msg.sender) revert LilypadProxy__CannotRevokeOwnRole();

        _revokeRole(SharedStructs.CONTROLLER_ROLE, account);
        emit LilypadProxy__ControllerRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Accepts a job payment from a job creator
     * @notice
     * - The caller of this function must call the token.approve() approving the paymentEngine contract address to recieve tokens on the callers behalf
     * - Only job creators can call this function
     * - Reverts if the `msg.sender` is the zero address
     * - Reverts if the `msg.sender` does not have the job creator role
     * - Reverts if the `_amount` is zero
     * - Emits a `JobCreatorEscrowPayment` event upon successful payment
     */
    function acceptJobPayment(uint256 _amount) external returns (bool) {
        if (msg.sender == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (!lilypadUser.hasRole(msg.sender, SharedStructs.UserType.JobCreator)) {
            revert LilypadProxy__acceptJobPayment__NotJobCreator();
        }
        if (_amount == 0) revert LilypadProxy__ZeroAmountNotAllowed();
        if (lilypadToken.allowance(msg.sender, address(paymentEngine)) < _amount) {
            revert LilypadProxy__NotEnoughAllowance();
        }

        _payDeposit(msg.sender, SharedStructs.PaymentReason.JobPayment, _amount);

        emit LilypadProxy__JobCreatorEscrowPayment(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Accepts a resource provider collateral payment
     * @notice
     * - The caller of this function must call the token.approve() approving the paymentEngine contract address to recieve tokens on the callers behalf
     * - Only resource providers can call this function
     * - Reverts if the `msg.sender` is the zero address
     * - Reverts if the `msg.sender` does not have the resource provider role
     * - Reverts if the `_amount` is zero
     * - Emits a `ResourceProviderCollateralPayment` event upon successful payment
     */
    function acceptResourceProviderCollateral(uint256 _amount) external returns (bool) {
        if (msg.sender == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (!lilypadUser.hasRole(msg.sender, SharedStructs.UserType.ResourceProvider)) {
            revert LilypadProxy__acceptResourceProviderCollateral__NotResourceProvider();
        }
        if (_amount == 0) revert LilypadProxy__ZeroAmountNotAllowed();
        if (lilypadToken.allowance(msg.sender, address(paymentEngine)) < _amount) {
            revert LilypadProxy__NotEnoughAllowance();
        }

        _payDeposit(msg.sender, SharedStructs.PaymentReason.ResourceProviderCollateral, _amount);

        emit LilypadProxy__ResourceProviderCollateralPayment(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Accepts a validation collateral payment
     * @notice
     * - The caller of this function must call the token.approve() approving the paymentEngine contract address to recieve tokens on the callers behalf
     * - Only validators can call this function
     * - Reverts if the `msg.sender` is the zero address
     * - Reverts if the `msg.sender` does not have the validator role
     * - Reverts if the `_amount` is zero
     * - Emits a `ValidationCollateralPayment` event upon successful payment
     */
    function acceptValidationCollateral(uint256 _amount) external returns (bool) {
        if (msg.sender == address(0)) revert LilypadProxy__ZeroAddressNotAllowed();
        if (!lilypadUser.hasRole(msg.sender, SharedStructs.UserType.Validator)) {
            revert LilypadProxy__acceptValidationCollateral__NotValidator();
        }
        if (_amount == 0) revert LilypadProxy__ZeroAmountNotAllowed();
        if (lilypadToken.allowance(msg.sender, address(paymentEngine)) < _amount) {
            revert LilypadProxy__NotEnoughAllowance();
        }

        _payDeposit(msg.sender, SharedStructs.PaymentReason.ValidationCollateral, _amount);

        emit LilypadProxy__ValidationCollateralPayment(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Gets the escrow balance for an address
     * @notice
     * - Reverts if the `_address` is the zero address
     * - Returns the escrow balance for the `_address`
     */
    function getEscrowBalance(address _address) external view returns (uint256) {
        return paymentEngine.escrowBalanceOf(_address);
    }

    /**
     * @dev Gets a deal from the storage contract
     * @notice
     * - Reverts if the `dealId` is empty or deal does not exist
     * - Returns the deal for the `dealId`
     */
    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        return lilypadStorage.getDeal(dealId);
    }

    /**
     * @dev Sets a deal in the storage contract and locks up the escrow in the paymentEngine contract
     * @notice
     * - Reverts if the `dealId` is empty or deal does not exist
     * - Reverts if the `deal` is not valid
     * - Reverts if the job creator and/or resource provider do not have enough escrow balance to satify running the job
     * - Returns true if the deal is successfully saved
     */
    function setDeal(SharedStructs.Deal memory deal) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        // Save the deal to the storage contract where the checks on the object are done in the storage contract
        bool _dealSaveSuccess = lilypadStorage.saveDeal(deal.dealId, deal);
        if (!_dealSaveSuccess) revert LilypadProxy__DealFailedToSave();

        // Calculate the cost of the job from the job creator's perspective
        uint256 jobCost = deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.jobCreatorSolverFee
            + deal.paymentStructure.networkCongestionFee + deal.paymentStructure.moduleCreatorFee;
        // Calculate the cost of the job from the resource provider's perspective
        uint256 resourceProviderCost =
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee;

        // Lock up the escrow in active state the paymentEngine contract
        bool _collateralLockupSuccess = paymentEngine.initiateLockupOfEscrowForJob(
            deal.jobCreator, deal.resourceProvider, deal.dealId, jobCost, resourceProviderCost
        );
        if (!_collateralLockupSuccess) revert LilypadProxy__DealFailedToLockup();

        return true;
    }

    function getResult(string memory _resultId) external view returns (SharedStructs.Result memory) {
        // Retrieve the result from the storage contract, if it doesn't exist, the storage contract will revert
        SharedStructs.Result memory result = lilypadStorage.getResult(_resultId);
        // Retrieve the deal from the storage contract, if it doesn't exist, the storage contract will revert
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);

        // Only the job creator can get their result
        if (msg.sender != deal.jobCreator) revert LilypadProxy__NotAuthorizedToGetResult();
        return result;
    }

    function setResult(SharedStructs.Result memory result)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        // Save the Result Object to the storage contract where the checks on the object are done in the storage contract
        bool _resultSaveSuccess = lilypadStorage.saveResult(result.resultId, result);
        if (!_resultSaveSuccess) revert LilypadProxy__ResultFailedToSave();

        // Check if the result status is ResultAccepted, if so call handleJobCompletion
        if (result.status == SharedStructs.ResultStatusEnum.ResultsAccepted) {
            // This will handle finalizing the payouts for all the respective parties
            paymentEngine.handleJobCompletion(result);
        } else {
            // This will handle finalizing the payouts for all the respective parties as well as slashing the resource provider for failing to provide a result
            paymentEngine.handleJobFailure(result);
        }

        return true;
    }

    function updateResultState(string memory resultId, SharedStructs.ResultStatusEnum state) external returns (bool) {
        revert("Not implemented");
    }

    function requestValidation(address requestorAddress, string memory moduleName, uint256 amount)
        external
        returns (bool)
    {
        revert("Not implemented");
    }

    function updateValidationState(string memory validationId, SharedStructs.ValidationResultStatusEnum state)
        external
        returns (bool)
    {
        revert("Not implemented");
    }

    function getValidationResult(string memory validationId)
        external
        view
        returns (SharedStructs.ValidationResult memory)
    {
        revert("Not implemented");
    }

    function setValidationResult(string memory validationId, SharedStructs.ValidationResult memory validation)
        external
        returns (bool)
    {
        revert("Not implemented");
    }

    function getPaymentEngineAddress() external view returns (address) {
        return address(paymentEngine);
    }

    function getLilypadTokenAddress() external view returns (address) {
        return address(lilypadToken);
    }

    function getStorageAddress() external view returns (address) {
        return address(lilypadStorage);
    }

    function getValidationAddress() external view returns (address) {
        return address(lilypadValidation);
    }

    function getUserAddress() external view returns (address) {
        return address(lilypadUser);
    }

    function getMinimumResourceProviderCollateralAmount() external view returns (uint256) {
        return paymentEngine.MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT();
    }

    function _payDeposit(address _payee, SharedStructs.PaymentReason _paymentReason, uint256 _amount)
        private
        returns (bool)
    {
        // Pay into the escrow
        paymentEngine.payEscrow(_payee, _paymentReason, _amount);
        return true;
    }
}
