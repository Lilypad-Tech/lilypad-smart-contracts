// SPX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {ILilypadPaymentEngine} from "./interfaces/ILilypadPaymentEngine.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LilypadStorage} from "./LilypadStorage.sol";
import {LilypadUser} from "./LilypadUser.sol";
import {LilypadTokenomics} from "./LilypadTokenomics.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadPaymentEngine
 * @dev Implementation of the LilypadPaymentEngine contract
 */
contract LilypadPaymentEngine is ILilypadPaymentEngine, Initializable, AccessControlUpgradeable, ReentrancyGuard {

    ////////////////////////////////
    ///////// State Variables //////
    ////////////////////////////////

    IERC20 private l2token;
    LilypadStorage private lilypadStorage;
    LilypadUser private lilypadUser;
    LilypadTokenomics private lilypadTokenomics;
    // The version of the contract
    string public version;

    // The lock duration: 30 days in seconds
    uint256 public constant COLLATERAL_LOCK_DURATION = 30 days;

    // The minimum amount of escrow that a resource provider must deposit as collateral
    uint256 public constant MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT = 10 * 10 ** 18;

    // The wallets of where the fees are supposed to flow
    address public treasuryWallet;
    address public valueBasedRewardsWallet;
    address public validationPoolWallet;

    // This is the total escrow that is currently locked in the contract
    uint256 public totalEscrow;

    // This is the total active escrow for running jobs locked for actively running jobs
    uint256 public totalActiveEscrow;

    // The active amount of tokens that are up for being burned
    uint256 public activeBurnTokens;

    // This is a mapping of escrow deposits
    mapping(address account => uint256 amount) public escrowBalances;

    // This is a mapping of escrow that is active in a deal
    mapping(address account => uint256 activeEscrow) public activeEscrow;

    // This is a mapping keeping track of the deposits for each resource provider account and the timestamp of when they can be withdrawn
    mapping(address account => uint256 depositTimestamp) public depositTimestamps;

    ////////////////////////////////
    ///////// Events ///////////////
    ////////////////////////////////

    event LilypadPayment__escrowPaid(
        address indexed payee, SharedStructs.PaymentReason indexed paymentReason, uint256 amount
    );
    event LilypadPayment__escrowWithdrawn(address indexed withdrawer, uint256 amount);
    event LilypadPayment__escrowSlashed(address indexed account, SharedStructs.UserType indexed actor, uint256 amount);
    event LilypadPayment__ActiveEscrowLockedForJob(
        address indexed jobCreator, address indexed resourceProvider, string indexed dealId, uint256 cost
    );
    event LilypadPayment__JobCompleted(address indexed jobCreator, address indexed resourceProvider, string dealId);
    event LilypadPayment__TreasuryWalletUpdated(address indexed treasuryWallet);
    event LilypadPayment__ValueBasedRewardsWalletUpdated(address indexed valueBasedRewardsWallet);
    event LilypadPayment__ValidationPoolWalletUpdated(address indexed validationPoolWallet);
    event LilypadPayment__TotalFeesGeneratedByJob(
        address indexed resourceProvider, address indexed jobCreator, string dealId, uint256 amount
    );
    event LilypadPayment__JobFailed(address indexed jobCreator, address indexed resourceProvider, string resultId);
    event LilypadPayment__ZeroAmountPayout(address indexed intended_recipient);
    event LilypadPayment__ValidationPassed(
        address indexed jobCreator, address indexed resourceProvider, address indexed validator, uint256 amount
    );
    event LilypadPayment__ValidationFailed(
        address indexed jobCreator, address indexed resourceProvider, address indexed validator, uint256 amount
    );
    event LilypadPayment__ControllerRoleGranted(address indexed account, address indexed sender);
    event LilypadPayment__ControllerRoleRevoked(address indexed account, address indexed sender);
    event LilypadPayment__escrowPayout(address indexed to, uint256 amount);
    event LilypadPayment__TokensBurned(uint256 blockNumber, uint256 blockTimestamp, uint256 amountBurnt);

    error LilypadPayment__insufficientEscrowAmount(uint256 escrowAmount, uint256 requiredAmount);
    error LilypadPayment__insufficientActiveEscrowAmount();
    error LilypadPayment__amountMustBeGreaterThanZero(bytes4 functionSelector, uint256 amount);
    error LilypadPayment__escrowSlashAmountTooLarge();
    error LilypadPayment__insufficientEscrowBalanceForWithdrawal();
    error LilypadPayment__transferFailed();
    error LilypadPayment__escrowNotWithdrawable();
    error LilypadPayment__escrowNotWithdrawableForActor(address actor);
    error LilypadPayment__HandleJobCompletion__InvalidTreasuryAmounts(
        uint256 pValue, uint256 p1Value, uint256 p2Value, uint256 p3Value
    );
    error LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob(
        string dealId,
        uint256 jobCreatorActiveEscrow,
        uint256 resourceProviderActiveEscrow,
        uint256 totalCostOfJob,
        uint256 resourceProviderRequiredActiveEscrow
    );
    error LilypadPayment__HandleJobFailure__InsufficientActiveEscrowToCompleteJob(
        string dealId,
        uint256 jobCreatorActiveEscrow,
        uint256 resourceProviderActiveEscrow,
        uint256 totalCostOfJob,
        uint256 resourceProviderRequiredActiveEscrow
    );
    error LilypadPayment__unauthorizedWithdrawal();
    error LilypadPayment__minimumResourceProviderAndValidatorDepositAmountNotMet();
    error LilypadPayment__ZeroAddressNotAllowed();
    error LilypadPayment__ZeroTokenAddress();
    error LilypadPayment__ZeroTreasuryWallet();
    error LilypadPayment__ZeroValueBasedRewardsWallet();
    error LilypadPayment__ZeroValidationPoolWallet();
    error LilypadPayment__ZeroStorageAddress();
    error LilypadPayment__ZeroUserAddress();
    error LilypadPayment__InvalidResultStatus();
    error LilypadPayment__InvalidValidationResultStatus();
    error LilypadPayment__RoleNotFound();
    error LilypadPayment__CannotRevokeOwnRole();
    error LilypadPayment__RoleAlreadyAssigned();
    error LilypadPayment__ZeroPayoutAddress();
    error LilypadPayment__ZeroPayeeAddress();
    error LilypadPayment__ZeroSlashAddress();
    error LilypadPayment__ZeroWithdrawalAddress();
    error LilypadPayment__ZeroResourceProviderAddress();
    error LilypadPayment__ZeroJobCreatorAddress();
    error LilypadPayment__InsufficientActiveBurnTokens();
    error LilypadPayment__ZeroTokenomicsAddress();

    ////////////////////////////////
    ///////// Modifiers ///////////
    ////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert LilypadPayment__amountMustBeGreaterThanZero(msg.sig, amount);
        }
        _;
    }

    modifier hasEnoughEscrow(address _address, uint256 _amount) {
        if (escrowBalances[_address] < _amount) {
            revert LilypadPayment__insufficientEscrowAmount(escrowBalances[_address], _amount);
        }
        _;
    }

    modifier hasEnoughActiveEscrow(address _address, uint256 _amount) {
        if (activeEscrow[_address] < _amount) {
            revert LilypadPayment__insufficientActiveEscrowAmount();
        }
        _;
    }

    ////////////////////////////////
    ///////// Constructor //////////
    ////////////////////////////////

    function initialize(
        address _l2token,
        address _lilypadStorageAddress,
        address _lilypadUserAddress,
        address _lilypadTokenomicsAddress,
        address _treasuryWallet,
        address _valueBasedRewardsWallet,
        address _validationPoolWallet
    ) public initializer {
        if (_l2token == address(0)) revert LilypadPayment__ZeroTokenAddress();
        if (_lilypadStorageAddress == address(0)) revert LilypadPayment__ZeroStorageAddress();
        if (_lilypadUserAddress == address(0)) revert LilypadPayment__ZeroUserAddress();
        if (_lilypadTokenomicsAddress == address(0)) revert LilypadPayment__ZeroTokenomicsAddress();
        if (_treasuryWallet == address(0)) revert LilypadPayment__ZeroTreasuryWallet();
        if (_valueBasedRewardsWallet == address(0)) revert LilypadPayment__ZeroValueBasedRewardsWallet();
        if (_validationPoolWallet == address(0)) revert LilypadPayment__ZeroValidationPoolWallet();

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);

        l2token = IERC20(_l2token);
        lilypadStorage = LilypadStorage(_lilypadStorageAddress);
        lilypadUser = LilypadUser(_lilypadUserAddress);
        lilypadTokenomics = LilypadTokenomics(_lilypadTokenomicsAddress);
        treasuryWallet = _treasuryWallet;
        valueBasedRewardsWallet = _valueBasedRewardsWallet;
        validationPoolWallet = _validationPoolWallet;

        version = "1.0.0";
    }

    ////////////////////////////////
    ///////// Functions ////////////
    ////////////////////////////////

    /**
     * @notice Sets the treasury wallet address
     * @param _treasuryWallet New treasury wallet address
     */
    function setTreasuryWallet(address _treasuryWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasuryWallet == address(0)) revert LilypadPayment__ZeroTreasuryWallet();
        treasuryWallet = _treasuryWallet;
        emit LilypadPayment__TreasuryWalletUpdated(_treasuryWallet);
    }

    /**
     * @notice Sets the value based rewards wallet address
     * @param _valueBasedRewardsWallet New value based rewards wallet address
     */
    function setValueBasedRewardsWallet(address _valueBasedRewardsWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_valueBasedRewardsWallet == address(0)) revert LilypadPayment__ZeroValueBasedRewardsWallet();
        valueBasedRewardsWallet = _valueBasedRewardsWallet;
        emit LilypadPayment__ValueBasedRewardsWalletUpdated(_valueBasedRewardsWallet);
    }

    /**
     * @notice Sets the validation pool wallet address
     * @param _validationPoolWallet New validation pool wallet address
     */
    function setValidationPoolWallet(address _validationPoolWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_validationPoolWallet == address(0)) revert LilypadPayment__ZeroValidationPoolWallet();
        validationPoolWallet = _validationPoolWallet;
        emit LilypadPayment__ValidationPoolWalletUpdated(_validationPoolWallet);
    }

    function canWithdrawEscrow(address _address) public view returns (bool) {
        return block.timestamp >= depositTimestamps[_address];
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
        if (account == address(0)) revert LilypadPayment__ZeroAddressNotAllowed();
        if (hasRole(SharedStructs.CONTROLLER_ROLE, account)) revert LilypadPayment__RoleAlreadyAssigned();
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit LilypadPayment__ControllerRoleGranted(account, msg.sender);
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
        if (account == address(0)) revert LilypadPayment__ZeroAddressNotAllowed();
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, account)) revert LilypadPayment__RoleNotFound();
        if (account == msg.sender) revert LilypadPayment__CannotRevokeOwnRole();

        _revokeRole(SharedStructs.CONTROLLER_ROLE, account);
        emit LilypadPayment__ControllerRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Pays an escrow for a given address
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function payEscrow(address _payee, SharedStructs.PaymentReason _paymentReason, uint256 _amount)
        external
        moreThanZero(_amount)
        returns (bool)
    {
        if (_payee == address(0)) revert LilypadPayment__ZeroPayeeAddress();

        bool isResourceProviderOrValidator = lilypadUser.hasRole(_payee, SharedStructs.UserType.ResourceProvider)
            || lilypadUser.hasRole(_payee, SharedStructs.UserType.Validator);

        if (isResourceProviderOrValidator) {
            // Check if the resource provider has enough escrow to cover the amount
            if (_amount < MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT) {
                revert LilypadPayment__minimumResourceProviderAndValidatorDepositAmountNotMet();
            }
        }

        // Do the accounting to bump the escrow balance of the account
        escrowBalances[_payee] += _amount;

        bool success = l2token.transferFrom(_payee, address(this), _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        if (isResourceProviderOrValidator) {
            // In the case of a Resource Provider or Validator, set the time when the deposit can be withdrawn by the account
            // Note: If the account continueously tops up their escrow balance, the withdrawl time will be extended to 30 days from the last deposit
            depositTimestamps[_payee] = block.timestamp + COLLATERAL_LOCK_DURATION;
        }

        // Add the amount to the total escrow for tracking
        totalEscrow += _amount;

        emit LilypadPayment__escrowPaid(_payee, _paymentReason, _amount);
        return true;
    }

    /**
     * @dev Deducts (slashes) a specified amount from an escrow balance as a penalty.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function slashEscrow(address _address, SharedStructs.UserType _actor, uint256 _amount)
        private
        moreThanZero(_amount)
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (_address == address(0)) revert LilypadPayment__ZeroSlashAddress();

        activeEscrow[_address] -= _amount;

        // When an actor is slashed their active collateral, it is sent to the treasury wallet
        bool success = l2token.transfer(treasuryWallet, _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        // Subtract the amount from the total active escrow for tracking
        totalActiveEscrow -= _amount;

        // Subtract the amount from the total escrow for tracking
        totalEscrow -= _amount;

        emit LilypadPayment__escrowSlashed(_address, _actor, _amount);
        return true;
    }

    /**
     * @dev Withdraws a specified amount from an escrow balance.
     * @notice Only Resource Providers and Validators can withdraw their escrow
     */
    function withdrawEscrow(address _withdrawer, uint256 _amount)
        external
        nonReentrant
        moreThanZero(_amount)
        returns (bool)
    {
        if (_withdrawer == address(0)) revert LilypadPayment__ZeroWithdrawalAddress();
        if (msg.sender != _withdrawer) revert LilypadPayment__unauthorizedWithdrawal();
        if (
            lilypadUser.hasRole(_withdrawer, SharedStructs.UserType.ResourceProvider)
                || lilypadUser.hasRole(_withdrawer, SharedStructs.UserType.Validator)
        ) {
            if (block.timestamp < depositTimestamps[_withdrawer]) {
                revert LilypadPayment__escrowNotWithdrawable();
            }
        } else {
            // If we enter this block, it means a non-RP or non-Validator is trying to withdraw their escrow
            revert LilypadPayment__escrowNotWithdrawableForActor(_withdrawer);
        }
        if (escrowBalances[_withdrawer] < _amount || escrowBalances[_withdrawer] == 0) {
            revert LilypadPayment__insufficientEscrowBalanceForWithdrawal();
        }

        // Remove the amount from the actor's escrow balance
        // Note: We do not remove the active collateral from the actor's active escrow since that will be used for the completion of a currently active job
        escrowBalances[_withdrawer] -= _amount;

        bool success = l2token.transfer(_withdrawer, _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        // Subtract the amount from the total escrow for tracking
        totalEscrow -= _amount;

        emit LilypadPayment__escrowWithdrawn(_withdrawer, _amount);
        return true;
    }

    /**
     * @dev Processes a payout for a job, transferring a specified amount from the contracts balance to a specific address
     * @notice
     *     - This function is restricted to the CONTROLLER_ROLE.
     *     - If the amount is 0, it will emit an event and return false (this is to avoid reverts when the amount is 0)
     */
    function payout(address _to, uint256 _amount) private onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (_to == address(0)) revert LilypadPayment__ZeroPayoutAddress();

        if (_amount == 0) {
            emit LilypadPayment__ZeroAmountPayout(_to);
            return false;
        }

        bool success = l2token.transfer(_to, _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        emit LilypadPayment__escrowPayout(_to, _amount);
        return true;
    }

    /**
     * @dev Initiates the lockup of escrow for a job
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function initiateLockupOfEscrowForJob(
        address jobCreator,
        address resourceProvider,
        string memory dealId,
        uint256 cost,
        uint256 resourceProviderCollateralLockupAmount
    )
        external
        hasEnoughEscrow(jobCreator, cost)
        moreThanZero(cost)
        hasEnoughEscrow(resourceProvider, resourceProviderCollateralLockupAmount)
        moreThanZero(resourceProviderCollateralLockupAmount)
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (jobCreator == address(0)) revert LilypadPayment__ZeroJobCreatorAddress();
        if (resourceProvider == address(0)) revert LilypadPayment__ZeroResourceProviderAddress();

        // Deduct the escrow balances for the job creator and resource provider
        escrowBalances[jobCreator] -= cost;
        escrowBalances[resourceProvider] -= resourceProviderCollateralLockupAmount;

        // Move the escrow balances to active escrow
        // We add on top of the existing active escrow in the event of a job creator running multple jobs at once or a resource provider running multiple jobs at once
        activeEscrow[jobCreator] += cost;
        activeEscrow[resourceProvider] += resourceProviderCollateralLockupAmount;

        // Add the amount to the total active escrow for running jobs
        totalActiveEscrow += cost + resourceProviderCollateralLockupAmount;

        emit LilypadPayment__ActiveEscrowLockedForJob(jobCreator, resourceProvider, dealId, cost);
        return true;
    }

    /**
     * @dev This method will update the active burn tokens.  This function is meant to called by an external process who will be responsible for initiate the burning of the tokens on the l1 token contract following the below flow:
     *     - The external process call the activeBurnTokens() function to get the amount of tokens that are up for being burned at the time of the call (i.e. according to the epoch for burning tokens laid out in the tokenomics paper)
     *     - The external process then burns the tokens on the l1 token contract
     *     - The external process then calls the updateActiveBurnTokens() function to update the amount of active burn tokens passing in the amount that was burned so that the contract knows how much to subtract from the activeBurnTokens variable (as the amount can still be accumlating as the protocol is running)
     *     - updateActiveBurnTokens will then emit an event to notify the outside world of the amount of tokens that were burned including block number, block time, and the amount burnt
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function updateActiveBurnTokens(uint256 _amountBurnt)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (_amountBurnt > activeBurnTokens) {
            revert LilypadPayment__InsufficientActiveBurnTokens();
        }

        // Subtract the amount from the active burn tokens
        activeBurnTokens -= _amountBurnt;

        emit LilypadPayment__TokensBurned(block.number, block.timestamp, _amountBurnt);
        return true;
    }

    /**
     * @dev Handles the completion of a job
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleJobCompletion(SharedStructs.Result memory result)
        external
        nonReentrant
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (result.status != SharedStructs.ResultStatusEnum.ResultsAccepted) {
            revert LilypadPayment__InvalidResultStatus();
        }

        // Get the deal from the storage contract, if it doesn't exist, revert
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);

        // Calculate fees and payments in a separate internal function
        _processJobCompletion(deal);

        emit LilypadPayment__JobCompleted(deal.jobCreator, deal.resourceProvider, deal.dealId);
        return true;
    }

    /**
     * @dev Processes the completion of a job by calculating payments for various parties involved in a deal
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function _processJobCompletion(SharedStructs.Deal memory deal) private {
        // Calculate the total cost of the job
        uint256 totalCostOfJob = deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.jobCreatorSolverFee
            + deal.paymentStructure.moduleCreatorFee + deal.paymentStructure.networkCongestionFee;

        // Calculate the required active collateral for the resource provider
        uint256 resoureProviderRequiredActiveEscrow = (
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee
        ) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        // Get the active escrow for both parties
        uint256 jobCreatorActiveEscrow = activeEscrow[deal.jobCreator];
        uint256 resourceProviderActiveEscrow = activeEscrow[deal.resourceProvider];

        // Check the accounting to ensure both parties have enough active escrow locked in to complete the job agreement
        if (
            resourceProviderActiveEscrow < resoureProviderRequiredActiveEscrow
                || jobCreatorActiveEscrow < totalCostOfJob
        ) {
            revert LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob(
                deal.dealId,
                jobCreatorActiveEscrow,
                resourceProviderActiveEscrow,
                totalCostOfJob,
                resoureProviderRequiredActiveEscrow
            );
        }

        // Calculate protocol fees
        uint256 totalProtocolFees = deal.paymentStructure.networkCongestionFee
            + (deal.paymentStructure.moduleCreatorFee * lilypadTokenomics.m()) / 10000;

        // P: Protocol Revenue
        uint256 TreasuryPaymentTotalAmount = (totalProtocolFees * lilypadTokenomics.p()) / 10000;

        // Value Based Rewards = total fees - treasury amount
        // Simplifiying the equation, we get : valueBasedRewardsAmount = totalProtocolFees - (totalProtocolFees * p)/10000 = totalProtocolFees(1-p)/10000
        uint256 valueBasedRewardsAmount = totalProtocolFees - TreasuryPaymentTotalAmount;

        // Calculate module creator payment (total fee minus the protocol's portion)
        // Simplifiying the equation, we get : moduleCreatorPaymentAmount = moduleCreatorFee(1-m)/10000
        uint256 moduleCreatorPaymentAmount = deal.paymentStructure.moduleCreatorFee
            - (deal.paymentStructure.moduleCreatorFee * lilypadTokenomics.m()) / 10000;

        // p1
        uint256 burnAmount = (TreasuryPaymentTotalAmount * (lilypadTokenomics.p1())) / 10000;

        // p2
        uint256 grantsAndAirdropsAmount = (TreasuryPaymentTotalAmount * (lilypadTokenomics.p2())) / 10000;

        // p3 - calculate as remainder to avoid rounding errors
        uint256 validationPoolAmount = TreasuryPaymentTotalAmount - burnAmount - grantsAndAirdropsAmount;

        // Only burn if the burn amount is greater than 0 to avoid reverting
        if (burnAmount > 0) {
            // Add the amount to the active burn tokens
            // Note: This is to keep track of the amount of tokens that are up for being burned, the actual burning of tokens will happen through an external process calling the l1 token contract via the treasury wallet
            activeBurnTokens += burnAmount;
        }

        // Remove the active escrow for the job creator and resource provider
        activeEscrow[deal.jobCreator] -= totalCostOfJob;
        activeEscrow[deal.resourceProvider] -= resoureProviderRequiredActiveEscrow;

        // Return the resource provider's active escrow to their balance
        escrowBalances[deal.resourceProvider] += resoureProviderRequiredActiveEscrow;

        // Pay the resource provider
        payout(deal.resourceProvider, deal.paymentStructure.priceOfJobWithoutFees);

        // Pay the module creator their portion
        payout(deal.moduleCreator, moduleCreatorPaymentAmount);

        // Pay the solver
        payout(deal.solver, deal.paymentStructure.jobCreatorSolverFee + deal.paymentStructure.resourceProviderSolverFee);

        // Pay the treasury
        payout(treasuryWallet, TreasuryPaymentTotalAmount + grantsAndAirdropsAmount + burnAmount);

        // Pay the value based rewards
        payout(valueBasedRewardsWallet, valueBasedRewardsAmount);

        // Send the validationPoolAmount to the validation pool
        payout(validationPoolWallet, validationPoolAmount);

        // Subtract the amount from the total active escrow for running jobs
        totalActiveEscrow -= totalCostOfJob + resoureProviderRequiredActiveEscrow;

        // Subtract the amount from the total escrow for running jobs since the total cost of the job is being paid out
        totalEscrow -= totalCostOfJob;

        emit LilypadPayment__TotalFeesGeneratedByJob(
            deal.resourceProvider, deal.jobCreator, deal.dealId, totalProtocolFees
        );
    }

    /**
     * @dev Handles the failure of a job
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleJobFailure(SharedStructs.Result memory result)
        external
        nonReentrant
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (result.status != SharedStructs.ResultStatusEnum.ResultsRejected) {
            revert LilypadPayment__InvalidResultStatus();
        }

        // Get the deal from the storage contract, if it doesn't exist, revert
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);

        // Calculate the total cost of the job
        uint256 totalCostOfJob = deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.jobCreatorSolverFee
            + deal.paymentStructure.moduleCreatorFee + deal.paymentStructure.networkCongestionFee;

        // Calculate the required active collateral for the resource provider to be slashed
        uint256 resoureProviderRequiredActiveEscrow = (
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee
        ) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        // Get the active escrow for both parties
        uint256 jobCreatorActiveEscrow = activeEscrow[deal.jobCreator];
        uint256 resourceProviderActiveEscrow = activeEscrow[deal.resourceProvider];

        // Check the accounting to ensure both parties have enough active escrow locked in to complete the job agreement
        if (
            resourceProviderActiveEscrow < resoureProviderRequiredActiveEscrow
                || jobCreatorActiveEscrow < totalCostOfJob
        ) {
            revert LilypadPayment__HandleJobFailure__InsufficientActiveEscrowToCompleteJob(
                deal.dealId,
                jobCreatorActiveEscrow,
                resourceProviderActiveEscrow,
                totalCostOfJob,
                resoureProviderRequiredActiveEscrow
            );
        }

        // Slash the resource provider
        slashEscrow(deal.resourceProvider, SharedStructs.UserType.ResourceProvider, resoureProviderRequiredActiveEscrow);

        // Deduct the active escrow for the job creator
        activeEscrow[deal.jobCreator] -= totalCostOfJob;

        // Refund the job creator
        payout(deal.jobCreator, totalCostOfJob);

        // Subtract the amount from the total active escrow for running jobs
        totalActiveEscrow -= totalCostOfJob;

        // Subtract the amount from the total escrow for running jobs since the total cost of the job is being paid out
        totalEscrow -= totalCostOfJob;

        emit LilypadPayment__JobFailed(deal.jobCreator, deal.resourceProvider, result.resultId);
        return true;
    }

    /**
     * @dev Handles the passing of a validation which would be called in the event of a resource provider acting honestly
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleValidationPassed(SharedStructs.ValidationResult memory _validationResult)
        external
        nonReentrant
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (_validationResult.status != SharedStructs.ValidationResultStatusEnum.ValidationAccepted) {
            revert LilypadPayment__InvalidValidationResultStatus();
        }

        SharedStructs.Result memory result = lilypadStorage.getResult(_validationResult.resultId);
        // This is the deal that the validation was initiated with, not the original job deal that was the cause of the validation
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);

        // Calculate the total cost of the validation job
        uint256 totalCostOfValidation = deal.paymentStructure.priceOfJobWithoutFees
            + deal.paymentStructure.jobCreatorSolverFee + deal.paymentStructure.moduleCreatorFee
            + deal.paymentStructure.networkCongestionFee;

        // Calculate the required active collateral for the validator
        uint256 validatorRequiredActiveEscrow = (
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee
        ) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        _processValidationPayment(
            _validationResult.validator, deal.jobCreator, totalCostOfValidation, validatorRequiredActiveEscrow
        );

        emit LilypadPayment__ValidationPassed(
            deal.jobCreator, deal.resourceProvider, _validationResult.validator, totalCostOfValidation
        );
        return true;
    }

    /**
     * @dev Handles the failure of a validation
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleValidationFailed(
        SharedStructs.ValidationResult memory _validationResult,
        SharedStructs.Deal memory _originalJobDeal
    ) external nonReentrant onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (_validationResult.status != SharedStructs.ValidationResultStatusEnum.ValidationRejected) {
            revert LilypadPayment__InvalidValidationResultStatus();
        }

        // Find the result from the storage contract
        SharedStructs.Result memory result = lilypadStorage.getResult(_validationResult.resultId);

        // Find the deal from the storage contract, this is the deal that the validation was initiated with, not the original job deal that was the cause of the validation
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);

        // Calculate the total cost of the validation job
        uint256 totalCostOfValidation = deal.paymentStructure.priceOfJobWithoutFees
            + deal.paymentStructure.jobCreatorSolverFee + deal.paymentStructure.moduleCreatorFee
            + deal.paymentStructure.networkCongestionFee;

        // Calculate the required active collateral for the validator
        uint256 validatorRequiredActiveEscrow = (
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee
        ) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        // Calculate the total cost of the original job from _originalJobDeal
        uint256 totalCostOfOriginalJob = _originalJobDeal.paymentStructure.priceOfJobWithoutFees
            + _originalJobDeal.paymentStructure.jobCreatorSolverFee + _originalJobDeal.paymentStructure.moduleCreatorFee
            + _originalJobDeal.paymentStructure.networkCongestionFee;

        // Calculate the total penalty for the resource provider who acted dishonestly
        uint256 totalPenalty = totalCostOfValidation + totalCostOfOriginalJob;

        // Deduct the total penalty from the resource provider from escrow balances but check if the resource provider has enough escrow
        if (escrowBalances[deal.resourceProvider] < totalPenalty) {
            uint256 amountToDeduct = escrowBalances[deal.resourceProvider];
            // If the resource provider doesn't have enough escrow, set the escrow balance to 0
            escrowBalances[deal.resourceProvider] = 0;

            // Deduct the total penalty from the total escrow
            totalPenalty = amountToDeduct;
        } else {
            // If the resource provider has enough escrow, deduct the total penalty
            escrowBalances[deal.resourceProvider] -= totalPenalty;
        }

        // Pay the validator for their validation work
        _processValidationPayment(
            _validationResult.validator, deal.jobCreator, totalCostOfValidation, validatorRequiredActiveEscrow
        );

        // Send the total penalty to the validation pool
        payout(validationPoolWallet, totalPenalty);

        // Deduct the total penalty from the running total escrow
        totalEscrow -= totalPenalty;

        emit LilypadPayment__ValidationFailed(
            deal.jobCreator, deal.resourceProvider, _validationResult.validator, totalPenalty
        );
        return true;
    }

    function _processValidationPayment(
        address validator,
        address jobCreator,
        uint256 totalCostOfValidation,
        uint256 validatorRequiredActiveEscrow
    ) private {
        // Deduct the active escrow for the job creator
        activeEscrow[jobCreator] -= totalCostOfValidation;

        // Deduct the active escrow for the validator
        activeEscrow[validator] -= validatorRequiredActiveEscrow;

        // Return the validator's active escrow to their balance
        escrowBalances[validator] += validatorRequiredActiveEscrow;

        // Pay the validator
        payout(validator, totalCostOfValidation);

        // Subtract the amount from the total active escrow for running jobs
        totalActiveEscrow -= totalCostOfValidation + validatorRequiredActiveEscrow;

        // Subtract the amount from the total escrow for running jobs since the total cost of the validation job is being paid out
        totalEscrow -= totalCostOfValidation;
    }
}
