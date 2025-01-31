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
import {ILilypadStorage} from "./interfaces/ILilypadStorage.sol";
import {ILilypadPaymentEngine} from "./interfaces/ILilypadPaymentEngine.sol";
import {ILilypadUser} from "./interfaces/ILilypadUser.sol";
import {ILilypadValidation} from "./interfaces/ILilypadValidation.sol";
import {LilypadToken} from "./LilypadToken.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract LilypadProxy is ILilypadProxy, AccessControlUpgradeable {
    // State Variables
    string public version;

    address public tokenAddress;

    ILilypadStorage public lilypadStorage;
    ILilypadPaymentEngine public paymentEngine;
    ILilypadValidation public lilypadValidation;
    ILilypadUser public lilypadUser;
    LilypadToken public lilypadToken;

    // Events
    event LilypadProxy__ControllerRoleGranted(address indexed account, address indexed caller);
    event LilypadProxy__ControllerRoleRevoked(address indexed account, address indexed caller);
    event LilypadProxy__JobCreatorEscrowPayment(address indexed jobCreator, uint256 amount);
    event LilypadProxy__ResourceProviderCollateralPayment(address indexed resourceProvider, uint256 amount);

    error LilypadProxy__ZeroAddressNotAllowed();
    error LilypadProxy__ZeroAmountNotAllowed();
    error LilypadProxy__RoleAlreadyAssigned();
    error LilypadProxy__RoleNotFound();
    error LilypadProxy__CannotRevokeOwnRole();
    error LilypadProxy__acceptJobPayment__NotJobCreator();
    error LilypadProxy__acceptResourceProviderCollateral__NotResourceProvider();
    error LilypadProxy__NotEnoughAllowance();

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

        lilypadStorage = ILilypadStorage(_storageAddress);
        paymentEngine = ILilypadPaymentEngine(_paymentEngineAddress);
        lilypadValidation = ILilypadValidation(_validationAddress);
        lilypadUser = ILilypadUser(_userAddress);
        lilypadToken = LilypadToken(_tokenAddress);
        version = "1.0.0";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
    }

    function getVersion() external view returns (string memory) {
        return version;
    }

    function setStorageContract(address _storageAddress) external returns (bool) {
        lilypadStorage = ILilypadStorage(_storageAddress);
        return true;
    }

    function setPaymentEngineContract(address _paymentEngineAddress) external returns (bool) {
        paymentEngine = ILilypadPaymentEngine(_paymentEngineAddress);
        return true;
    }

    function setValidationContract(address _validationAddress) external returns (bool) {
        lilypadValidation = ILilypadValidation(_validationAddress);
        return true;
    }

    function setUserContract(address _userAddress) external returns (bool) {
        lilypadUser = ILilypadUser(_userAddress);
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

    function acceptValidationCollateral(uint256 amount, address validatorAddress) external returns (bool) {
        revert("Not implemented");
    }

    function getEscrowBalance(address _address) external view returns (uint256) {
        revert("Not implemented");
    }

    function requestValidation(address requestorAddress, string memory moduleName, uint256 amount)
        external
        returns (bool)
    {
        revert("Not implemented");
    }

    function getResult(string memory dealId) external view returns (SharedStructs.Result memory) {
        revert("Not implemented");
    }

    function setResult(SharedStructs.Result memory result) external returns (bool) {
        revert("Not implemented");
    }

    function getDeal(string memory dealId) external view returns (SharedStructs.Deal memory) {
        revert("Not implemented");
    }

    function setDeal(SharedStructs.Deal memory deal) external returns (bool) {
        revert("Not implemented");
    }

    function updateDealState(string memory dealId, SharedStructs.DealStatusEnum state) external returns (bool) {
        revert("Not implemented");
    }

    function updateResultState(string memory resultId, SharedStructs.ResultStatusEnum state) external returns (bool) {
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

    function _payDeposit(address _payee, SharedStructs.PaymentReason _paymentReason, uint256 _amount)
        private
        returns (bool)
    {
        // Pay into the escrow
        paymentEngine.payEscrow(_payee, _paymentReason, _amount);
        return true;
    }
}
