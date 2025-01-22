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

// SPX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ILilypadPaymentEngine} from "./interfaces/ILilypadPaymentEngine.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LilypadToken} from "./LilypadToken.sol";
import {LilypadStorage} from "./LilypadStorage.sol";
import {LilypadUser} from "./LilypadUser.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadPaymentEngine
 * @dev Implementation of the LilypadPaymentEngine contract
 */
contract LilypadPaymentEngine is
    ILilypadPaymentEngine,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuard
{

    ////////////////////////////////
    ///////// State Variables //////
    ////////////////////////////////

    LilypadToken private token;
    LilypadStorage private lilypadStorage;
    LilypadUser private lilypadUser;
    //TODO: Add Validation cntracr when complete

    string public version;

    // The lock duration: 30 days in seconds
    uint256 public constant COLLATERAL_LOCK_DURATION = 30 days;

    // The minimum amount of escrow that a resource provider must deposit as collateral
    uint256 public constant MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT =
        10 * 10 ** 18;

    // The wallets of where the fees are supposed to flow
    address public treasuryWallet;
    address public valueBasedRewardsWallet;

    /**
    These are the parameters described in the Lilypad tokenomics paper
    src: _add_link_here_
    
    p: The percentage of total fees that go towads the protocol
    (1-p): The percentage of total fees that go towards the value based rewards
    
    p1: Percentage of P allocated to burn token
    p2: Percentage of P allocated to go to grants and airdrops
    p3: Percentage of P allocated to the validation pool
    Note:  p1 + p2 + p3 must equal 10000 (100%)

    m: The percentage of module creator fees that go towards protocol revenue
    
    alpha: The multipler for future stimulants of token (do I need this here?)
    
    v1: The scaling factor for determining value based rewards for RPs based on total fees geenrated by the RP
    v2: The scaling factor for determining value based rewards for RPs based on total average collateral locked up
    Note: v1 > v2 to scaoe the importance of fees over collateral
    */
    uint256 public p;
    uint256 public p1;
    uint256 public p2;
    uint256 public p3;

    uint256 public m;

    uint256 public alpha;

    uint256 public v1;
    uint256 public v2;

    // This is the scaler for the resource provider's active escrow
    uint256 public resourceProviderActiveEscrowScaler;

    // This is the total escrow for tracking
    uint256 public totalEscrow;

    // This is the total active escrow for running jobs
    uint256 public totalActiveEscrow;

    // This is a mapping of escrow deposits
    mapping(address account => uint256 amount) public escrowBalances;

    // This is a mapping of escrow that is active in a deal
    mapping(address account => uint256 activeEscrow) public activeEscrow;

    // This is a mapping keeping track of the deposits for each account and the timestamp of when they can be withdrawn
    mapping(address account => uint256 depositTimestamp)
        public depositTimestamps;

    ////////////////////////////////
    ///////// Events ///////////////
    ////////////////////////////////

    event LilypadPayment__escrowPaid(
        address indexed payee,
        SharedStructs.PaymentReason indexed paymentReason,
        uint256 amount
    );
    event LilypadPayment__escrowWithdrawn(
        address indexed withdrawer,
        uint256 amount
    );
    event LilypadPayment__escrowSlashed(
        address indexed account,
        SharedStructs.UserType indexed actor,
        uint256 amount
    );
    event LilypadPayment__ActiveEscrowLockedForJob(
        address indexed jobCreator,
        address indexed resourceProvider,
        string indexed dealId,
        uint256 cost
    );
    event TokenomicsParameterUpdated(string indexed parameter, uint256 value);
    event ActiveCollateralLockupPercentageUpdated(uint256 percentage);
    event LilypadPayment__JobCompleted(
        address indexed jobCreator,
        address indexed resourceProvider,
        string dealId
    );
    event LilypadPayment__JobFailed(
        address indexed jobCreator,
        address indexed resourceProvider,
        string resultId
    );
    event LilypadPayment__ZeroAmountPayout(address indexed intended_recipient);
    event LilypadPayment__ValidationPassed(address indexed jobCreator, address indexed resourceProvider, address indexed validator, uint256 amount);
    event LilypadPayment__ValidationFailed(address indexed jobCreator, address indexed resourceProvider, address indexed validator, uint256 amount);
    event LilypadPayment__ControllerRoleGranted(address indexed account, address indexed sender);
    event LilypadPayment__ControllerRoleRevoked(address indexed account, address indexed sender);
    event LilypadPayment__escrowPayout(address indexed to, uint256 amount);

    error LilypadPayment__insufficientEscrowAmount(uint256 escrowAmount, uint256 requiredAmount);
    error LilypadPayment__insufficientActiveEscrowAmount();
    error LilypadPayment__amountMustBeGreaterThanZero(bytes4 functionSelector, uint256 amount);
    error LilypadPayment__escrowSlashAmountTooLarge();
    error LilypadPayment__insufficientEscrowBalanceForWithdrawal();
    error LilypadPayment__transferFailed();
    error LilypadPayment__JobCreatorNotFound();
    error LilypadPayment__ResourceProviderNotFound();
    error LilypadPayment__escrowNotWithdrawable();
    error LilypadPayment__escrowNotWithdrawableForActor(address actor);
    error LilypadPayment__DealNotFound();
    error LilypadPayment__HandleJobCompletion__InvalidTreasuryAmounts(uint256 pValue, uint256 p1Value, uint256 p2Value, uint256 p3Value);
    error LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob(string dealId, uint256 jobCreatorActiveEscrow, uint256 resourceProviderActiveEscrow, uint256 totalCostOfJob, uint256 resourceProviderRequiredActiveEscrow);
    error LilypadPayment__unauthorizedWithdrawal();
    error LilypadPayment__minimumResourceProviderAndValidatorDepositAmountNotMet();
    error LilypadPayment__ZeroAddressNotAllowed();
    error LilypadPayment__ZeroTokenAddress();
    error LilypadPayment__ZeroTreasuryWallet();
    error LilypadPayment__ZeroValueBasedRewardsWallet();
    error LilypadPayment__ZeroStorageAddress();
    error LilypadPayment__ZeroUserAddress();
    error LilypadPayment__ParametersMustSumToTenThousand();
    error LilypadPayment__V1MustBeGreaterThanV2();
    error LilypadPayment__V2MustBeLessThanV1();
    error LilypadPayment__InvalidResultStatus();
    error LilypadPayment__InvalidValidationResultStatus();
    error LilypadPayment__RoleNotFound();
    error LilypadPayment__CannotRevokeOwnRole();
    error LilypadPayment__RoleAlreadyAssigned();

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
        address _tokenAddress,
        address _lilypadStorageAddress,
        address _lilypadUserAddress,
        address _treasuryWallet,
        address _valueBasedRewardsWallet
    ) public initializer {
        if (_tokenAddress == address(0)) revert LilypadPayment__ZeroTokenAddress();
        if (_lilypadStorageAddress == address(0)) revert LilypadPayment__ZeroStorageAddress();
        if (_lilypadUserAddress == address(0)) revert LilypadPayment__ZeroUserAddress();
        if (_treasuryWallet == address(0)) revert LilypadPayment__ZeroTreasuryWallet();
        if (_valueBasedRewardsWallet == address(0)) revert LilypadPayment__ZeroValueBasedRewardsWallet();

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);

        token = LilypadToken(_tokenAddress);
        lilypadStorage = LilypadStorage(_lilypadStorageAddress);
        lilypadUser = LilypadUser(_lilypadUserAddress);
        //TODO: Add validation contract

        treasuryWallet = _treasuryWallet;
        valueBasedRewardsWallet = _valueBasedRewardsWallet;

        version = "1.0.0";

        // Protocol Revenue, P, represented as a basis point
        p = 0;

        // P is further broken down into 3 parts represented as a basis points (each of which should sum to 10000 representing 100% of P)

        // Burn amount represented as a basis point
        p1 = 0;

        // Grants and airdrops represented as a basis point
        p2 = 5000;

        // Validation pool represented as a basis point
        p3 = 5000;

        // Setting is as a basis point representation of the percentage
        m = 200;
        
        // The stimulent factor for future growth of the token
        alpha = 0;
        
        // expoential weight for scaling fees
        v1 = 2;

        // exponential weight for scaling collateral
        v2 = 1;

        // Set to 11000 (representing 110% in basis points, or a 10% increase)
        resourceProviderActiveEscrowScaler = 11000;

        totalActiveEscrow = 0;
        totalEscrow = 0;
    }

    ////////////////////////////////
    ///////// Functions ////////////
    ////////////////////////////////

    /**
     * @dev Returns the current version of the contract
     * @notice
     * - Returns the semantic version string of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    function checkEscrowBalanceForAmount(
        address _address,
        uint256 _amount
    ) public view returns (bool) {
        return escrowBalances[_address] >= _amount;
    }

    function checkActiveEscrow(address _address) public view returns (bool) {
        return activeEscrow[_address] > 0;
    }

    function escrowBalanceOf(address _address) public view returns (uint256) {
        return escrowBalances[_address];
    }

    function activeEscrowBalanceOf(
        address _address
    ) public view returns (uint256) {
        return activeEscrow[_address];
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
    function payEscrow(
        address _payee,
        SharedStructs.PaymentReason _paymentReason,
        uint256 _amount
    ) external moreThanZero(_amount) returns (bool) {
        require(_payee != address(0), "Payee cannot be zero address");

        bool isResourceProviderOrValidator = lilypadUser.hasRole(_payee, SharedStructs.UserType.ResourceProvider) || lilypadUser.hasRole(_payee, SharedStructs.UserType.Validator);

        if (isResourceProviderOrValidator) {
            // Check if the resource provider has enough escrow to cover the amount
            if (_amount < MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT) {
                revert LilypadPayment__minimumResourceProviderAndValidatorDepositAmountNotMet();
            }
        }

        // Do the accounting to bump the escrow balance of the account
        escrowBalances[_payee] += _amount;

        bool success = token.transferFrom(_payee, address(this), _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        if (isResourceProviderOrValidator) {
            // In the case of a Resource Provider or Validator, set the time when the deposit can be withdrawn by the account
            // Note: If the account continueously tops up their escrow balance, the withdrawl time will be extended to 30 days from the last deposit
            depositTimestamps[_payee] =
                block.timestamp +
                COLLATERAL_LOCK_DURATION;
        }

        // Add the amount to the total escrow for tracking
        totalEscrow += _amount;

        emit LilypadPayment__escrowPaid(
            _payee,
            _paymentReason,
            _amount
        );
        return true;
    }

    /**
     * @dev Deducts (slashes) a specified amount from an escrow balance as a penalty.
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function slashEscrow(
        address _address,
        SharedStructs.UserType _actor,
        uint256 _amount
    )
        private
        moreThanZero(_amount)
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        require(_address != address(0), "Address cannot be zero address");

        activeEscrow[_address] -= _amount;

        // When an actor is slashed their active collateral, it is sent to the treasury wallet
        bool success = token.transfer(treasuryWallet, _amount);
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
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function withdrawEscrow(
        address _withdrawer,
        uint256 _amount
    ) external nonReentrant moreThanZero(_amount) returns (bool) {
        require(_withdrawer != address(0), "Withdrawer cannot be zero address");

        if (msg.sender != _withdrawer) {
            revert LilypadPayment__unauthorizedWithdrawal();
        }

        if (lilypadUser.hasRole(_withdrawer,SharedStructs.UserType.ResourceProvider) || lilypadUser.hasRole(_withdrawer, SharedStructs.UserType.Validator)) {
            if (block.timestamp < depositTimestamps[_withdrawer]) {
                revert LilypadPayment__escrowNotWithdrawable();
            }
        } else {
            //  If we enter this block, it means a non-RP or non-Validator is trying to withdraw their escrow
            revert LilypadPayment__escrowNotWithdrawableForActor(_withdrawer);
        }

        if (escrowBalances[_withdrawer] < _amount) {
            revert LilypadPayment__insufficientEscrowBalanceForWithdrawal();
        }

        // Remove the amount from the actor's escrow balance
        // Note: We do not remove the active collateral from the actor's active escrow since that will be used for the completion of a currently active job
        escrowBalances[_withdrawer] -= _amount;

        bool success = token.transfer(_withdrawer, _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        // Subtract the amount from the total escrow for tracking
        totalEscrow -= _amount;

        emit LilypadPayment__escrowWithdrawn(_withdrawer, _amount);
        return true;
    }

    /**
     * @dev Processes a payout for a job, transferring a specified amount from one address's escrow
     * to another.
     * @notice 
        - This function is restricted to the CONTROLLER_ROLE.
        - If the amount is 0, it will emit an event and return false (this is to avoid reverts when the amount is 0)
     */
    function payoutJob(
        address _to,
        uint256 _amount
    ) private onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        require(_to != address(0), "Payout address cannot be zero address");

        if (_amount == 0) {
            emit LilypadPayment__ZeroAmountPayout(_to);
            return false;
        }
        
        bool success = token.transfer(_to, _amount);
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
        hasEnoughEscrow(
            jobCreator,
            cost
        )
        moreThanZero(cost)
        hasEnoughEscrow(
            resourceProvider,
            resourceProviderCollateralLockupAmount
        )
        moreThanZero(resourceProviderCollateralLockupAmount)
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        require(jobCreator != address(0), "Job creator cannot be zero address");
        require(resourceProvider != address(0), "Resource provider cannot be zero address");

        // Deduct the escrow balances for the job creator and resource provider
        escrowBalances[jobCreator] -= cost;
        escrowBalances[resourceProvider] -= resourceProviderCollateralLockupAmount;

        // Move the escrow balances to active escrow
        // We add on top of the existing active escrow in the event of a job creator running multple jobs at once or a resource provider running multiple jobs at once
        activeEscrow[jobCreator] += cost;
        activeEscrow[resourceProvider] += resourceProviderCollateralLockupAmount;

        // Add the amount to the total active escrow for running jobs
        totalActiveEscrow += cost + resourceProviderCollateralLockupAmount;

        emit LilypadPayment__ActiveEscrowLockedForJob(
            jobCreator,
            resourceProvider,
            dealId,
            cost
        );
        return true;
    }

    /**
     * @dev Handles the completion of a job
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleJobCompletion(
        SharedStructs.Result memory result
    ) external nonReentrant onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (result.status != SharedStructs.ResultStatusEnum.ResultsAccepted) revert LilypadPayment__InvalidResultStatus();

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
        uint256 totalCostOfJob = deal.paymentStructure.priceOfJobWithoutFees + 
            deal.paymentStructure.JobCreatorSolverFee + 
            deal.paymentStructure.moduleCreatorFee + 
            deal.paymentStructure.networkCongestionFee;

        // Calculate the required active collateral for the resource provider
        uint256 resoureProviderRequiredActiveEscrow = (deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee) * (resourceProviderActiveEscrowScaler/10000);

        // Get the active escrow for both parties
        uint256 jobCreatorActiveEscrow = activeEscrow[deal.jobCreator];
        uint256 resourceProviderActiveEscrow = activeEscrow[deal.resourceProvider];

        // Check the accounting to ensure both parties have enough active escrow locked in to complete the job agreement
        if (resourceProviderActiveEscrow < resoureProviderRequiredActiveEscrow || jobCreatorActiveEscrow < totalCostOfJob) {
            revert LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob(
                deal.dealId, 
                jobCreatorActiveEscrow, 
                resourceProviderActiveEscrow, 
                totalCostOfJob, 
                resoureProviderRequiredActiveEscrow
            );
        }

        // Calculate protocol fees
        uint256 totalProtocolFees = deal.paymentStructure.networkCongestionFee + 
            (deal.paymentStructure.moduleCreatorFee * m)/10000;

        // P: Protocol Revenue
        uint256 TreasuryPaymentTotalAmount = (totalProtocolFees * p)/10000;

        // Value Based Rewards = total fees - treasury amount
        // Simplifiying the equation, we get : valueBasedRewardsAmount = totalProtocolFees - (totalProtocolFees * p)/10000 = totalProtocolFees(1-p)/10000
        uint256 valueBasedRewardsAmount = totalProtocolFees - TreasuryPaymentTotalAmount;

        // Calculate module creator payment (total fee minus the protocol's portion)
        // Simplifiying the equation, we get : moduleCreatorPaymentAmount = moduleCreatorFee(1-m)/10000
        uint256 moduleCreatorPaymentAmount = deal.paymentStructure.moduleCreatorFee - (deal.paymentStructure.moduleCreatorFee * m)/10000;

        // p1
        uint256 burnAmount = (TreasuryPaymentTotalAmount * (p1))/10000;

        // p2
        uint256 grantsAndAirdropsAmount = (TreasuryPaymentTotalAmount * (p2))/10000;

        // p3 - calculate as remainder to avoid rounding errors
        uint256 validationPoolAmount = TreasuryPaymentTotalAmount - burnAmount - grantsAndAirdropsAmount;

        // Only burn if the burn amount is greater than 0 to avoid reverting
        if (burnAmount > 0) {
            // Burn the amount
            token.burn(burnAmount);
        }

        // Remove the active escrow for the job creator and resource provider
        activeEscrow[deal.jobCreator] -= totalCostOfJob;
        activeEscrow[deal.resourceProvider] -= resoureProviderRequiredActiveEscrow;

        // Return the resource provider's active escrow to their balance
        escrowBalances[deal.resourceProvider] += resoureProviderRequiredActiveEscrow;
        
        // Pay the resource provider
        payoutJob(deal.resourceProvider, deal.paymentStructure.priceOfJobWithoutFees);

        // Pay the module creator their portion
        payoutJob(deal.moduleCreator, moduleCreatorPaymentAmount);

        // Pay the solver
        payoutJob(deal.solver, deal.paymentStructure.JobCreatorSolverFee + deal.paymentStructure.resourceProviderSolverFee);

        // Pay the treasury
        payoutJob(treasuryWallet, TreasuryPaymentTotalAmount + grantsAndAirdropsAmount);

        // Pay the value based rewards
        payoutJob(valueBasedRewardsWallet, valueBasedRewardsAmount);

        // TODO: send the validationPoolAmount to the validation contract when complete
        
        // Add the amount to the total active escrow for running jobs
        totalActiveEscrow -= totalCostOfJob + resoureProviderRequiredActiveEscrow;

        // Subtract the amount from the total escrow for tracking
        totalEscrow -= totalCostOfJob;
    }

    /**
     * @dev Handles the failure of a job
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleJobFailure(
        SharedStructs.Result memory result
    ) external nonReentrant onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (result.status != SharedStructs.ResultStatusEnum.ResultsRejected) revert LilypadPayment__InvalidResultStatus();

        // Get the deal from the storage contract, if it doesn't exist, revert
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);
    
        // Calculate the required active collateral for the resource provider to be slashed
        uint256 resoureProviderRequiredActiveEscrow = (deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee) * (resourceProviderActiveEscrowScaler/10000);

        // Slash the resource provider
        slashEscrow(deal.resourceProvider, SharedStructs.UserType.ResourceProvider, resoureProviderRequiredActiveEscrow);

        //TODO: What happens to the job creator's escrow?

        emit LilypadPayment__JobFailed(deal.jobCreator, deal.resourceProvider, result.resultId);
        return true;
    }

    /**
     * @dev Handles the passing of a validation
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleValidationPassed(
        SharedStructs.ValidationResult memory _validationResult
    ) external nonReentrant onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (_validationResult.status != SharedStructs.ValidationResultStatusEnum.ValidationAccepted) revert LilypadPayment__InvalidValidationResultStatus();

        SharedStructs.Result memory result = lilypadStorage.getResult(_validationResult.resultId);
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(result.dealId);

        // Calculate the required active collateral for the resource provider
        uint256 totalCostOfJob = deal.paymentStructure.priceOfJobWithoutFees + 
            deal.paymentStructure.JobCreatorSolverFee + 
            deal.paymentStructure.moduleCreatorFee + 
            deal.paymentStructure.networkCongestionFee;

        require(activeEscrow[deal.jobCreator] >= totalCostOfJob, "Active escrow is less than the total cost of the job");
        
        // Deduct the active escrow for the job creator
        activeEscrow[deal.jobCreator] -= totalCostOfJob;

        // Subtract the amount from the total active escrow for running jobs
        totalActiveEscrow -= totalCostOfJob;
        
        // Pay the validator
        payoutJob(_validationResult.validator, totalCostOfJob);

        emit LilypadPayment__ValidationPassed(deal.jobCreator, deal.resourceProvider, _validationResult.validator, totalCostOfJob);
        return true;
    }

    /**
     * @dev Handles the failure of a validation
     * @notice This function is restricted to the CONTROLLER_ROLE.
     */
    function handleValidationFailed(
        SharedStructs.ValidationResult memory _validationResult
    ) external returns (bool) {
        if (_validationResult.status != SharedStructs.ValidationResultStatusEnum.ValidationRejected) revert LilypadPayment__InvalidValidationResultStatus();
        /**
            Resource Provider acted dishonestly
            - Deduct an amount from the resource provider (where TBD)
            - Send a percentage to the job creator and a percentage to the validation pool
            - update the active escrow and total escrow
            - emit event
         */
        
        return true;
    }
    
    /**
     * @notice Sets the p1 parameter (burn amount)
     * @param _p1 New p1 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setP1(uint256 _p1) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_p1 + p2 + p3 != 10000) revert LilypadPayment__ParametersMustSumToTenThousand();
        p1 = _p1;
        emit TokenomicsParameterUpdated("p1", _p1);
    }

    /**
     * @notice Sets the p2 parameter (grants/ecosystem pool fee)
     * @param _p2 New p2 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setP2(uint256 _p2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (p1 + _p2 + p3 != 10000) revert LilypadPayment__ParametersMustSumToTenThousand();
        p2 = _p2;
        emit TokenomicsParameterUpdated("p2", _p2);
    }

    /**
     * @notice Sets the p3 parameter (validation pool fee)
     * @param _p3 New p3 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setP3(uint256 _p3) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (p1 + p2 + _p3 != 10000) revert LilypadPayment__ParametersMustSumToTenThousand();
        p3 = _p3;
        emit TokenomicsParameterUpdated("p3", _p3);
    }

    /**
     * @notice Sets the p parameter (the amount of fees to be paid to the treasury)
     * @param _p New p value
     */
    function setP(uint256 _p) external onlyRole(DEFAULT_ADMIN_ROLE) {
        p = _p;
        emit TokenomicsParameterUpdated("p", _p);
    }

    /**
     * @notice Sets the m parameter (The module creator fee)
     * @param _m New m value
     */
    function setM(uint256 _m) external onlyRole(DEFAULT_ADMIN_ROLE) {
        m = _m;
        emit TokenomicsParameterUpdated("m", _m);
    }

    /**
     * @notice Sets the alpha parameter ()
     * @param _alpha New alpha value
     */
    function setAlpha(uint256 _alpha) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alpha = _alpha;
        emit TokenomicsParameterUpdated("alpha", _alpha);
    }

    /**
     * @notice Sets the v1 parameter ()
     * @param _v1 New v1 value
     */
    function setV1(uint256 _v1) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_v1 <= v2) revert LilypadPayment__V1MustBeGreaterThanV2();
        v1 = _v1;
        emit TokenomicsParameterUpdated("v1", _v1);
    }

    /**
     * @notice Sets the v2 parameter ()
     * @param _v2 New v2 value
     */
    function setV2(uint256 _v2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_v2 >= v1) revert LilypadPayment__V2MustBeLessThanV1();
        v2 = _v2;
        emit TokenomicsParameterUpdated("v2", _v2);
    }

    /**
     * @notice Sets the resource provider active escrow scaler
     * @param _resourceProviderActiveEscrowScaler New resource provider active escrow scaler
     */
    function setResourceProviderActiveEscrowScaler(uint256 _resourceProviderActiveEscrowScaler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        resourceProviderActiveEscrowScaler = _resourceProviderActiveEscrowScaler;
        emit TokenomicsParameterUpdated("resourceProviderActiveEscrowScaler", _resourceProviderActiveEscrowScaler);
    }

    /**
     * @notice Sets the treasury wallet address
     * @param _treasuryWallet New treasury wallet address
     */
    function setTreasuryWallet(address _treasuryWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasuryWallet == address(0)) revert LilypadPayment__ZeroTreasuryWallet();
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @notice Sets the value based rewards wallet address
     * @param _valueBasedRewardsWallet New value based rewards wallet address
     */
    function setValueBasedRewardsWallet(address _valueBasedRewardsWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_valueBasedRewardsWallet == address(0)) revert LilypadPayment__ZeroValueBasedRewardsWallet();
        valueBasedRewardsWallet = _valueBasedRewardsWallet;
    }
}
