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
    Note: v1 > v2
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
        SharedStructs.UserType indexed actor,
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

    event TokenomicsParameterUpdated(string parameter, uint256 value);
    event ActiveCollateralLockupPercentageUpdated(uint256 percentage);

    event LilypadPayment__JobCompleted(
        address indexed jobCreator,
        address indexed resourceProvider,
        string dealId
    );

    event LilypadPayment__ZeroAmountPayout(address indexed intended_recipient);
    
    error LilypadPayment__amountMustBeNonNegative(bytes4 functionSelector, uint256 amount);
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

    ////////////////////////////////
    ///////// Modifiers ///////////
    ////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert LilypadPayment__amountMustBeGreaterThanZero(msg.sig, amount);
        }
        _;
    }

    modifier nonNegative(uint256 amount) {
        if (amount < 0) {
            revert LilypadPayment__amountMustBeNonNegative(msg.sig, amount);
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
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);

        token = LilypadToken(_tokenAddress);
        lilypadStorage = LilypadStorage(_lilypadStorageAddress);
        lilypadUser = LilypadUser(_lilypadUserAddress);

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
        
        alpha = 0;
        
        v1 = 2;
        v2 = 1;

        // Set to 11000 (representing 110% in basis points, or a 10% increase)
        resourceProviderActiveEscrowScaler = 11000;

        totalActiveEscrow = 0;
        totalEscrow = 0;
    }

    ////////////////////////////////
    ///////// Functions ////////////
    ////////////////////////////////

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

    // TODO: In the case of a resource provider, we need to check if they meet the minimum collateral requirement
    function payEscrow(
        address _payee,
        SharedStructs.UserType _actor,
        SharedStructs.PaymentReason _paymentReason,
        uint256 _amount
    ) external moreThanZero(_amount) returns (bool) {
        // Do the accounting to bump the escrow balance of the account
        escrowBalances[_payee] += _amount;

        bool success = token.transferFrom(_payee, address(this), _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }

        if (
            lilypadUser.hasRole(_payee, SharedStructs.UserType.ResourceProvider) || lilypadUser.hasRole(_payee, SharedStructs.UserType.Validator)
        ) {
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
            _actor,
            _paymentReason,
            _amount
        );
        return true;
    }

    /**
     * @dev Deducts (slashes) a specified amount from an escrow balance as a penalty.
     * @param _address The address whose escrow balance will be deducted.
     * @param _actor The actor type of the address whose escrow balance will be deducted.
     * @param _amount The amount to deduct as a penalty.
     * @return Returns true if the slash operation is successful.
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
        if (activeEscrow[_address] < _amount) {
            revert LilypadPayment__escrowSlashAmountTooLarge();
        }

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

    function withdrawEscrow(
        address _withdrawer,
        uint256 _amount
    ) external nonReentrant moreThanZero(_amount) returns (bool) {
        if (msg.sender != _withdrawer) {
            revert LilypadPayment__unauthorizedWithdrawal();
        }

        if (lilypadUser.hasRole(_withdrawer,SharedStructs.UserType.ResourceProvider) || lilypadUser.hasRole(_withdrawer, SharedStructs.UserType.Validator)) {
            if (block.timestamp < depositTimestamps[_withdrawer]) {
                revert LilypadPayment__escrowNotWithdrawable();
            }
        } else {
            //  If we enter this block, it means a non-RP or Validator is trying to withdraw their escrow
            revert LilypadPayment__escrowNotWithdrawableForActor(_withdrawer);
        }

        if (escrowBalances[_withdrawer] < _amount) {
            revert LilypadPayment__insufficientEscrowBalanceForWithdrawal();
        }

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
     * @param _to The address receiving the payout.
     * @param _amount The amount to transfer as a payout.
     * @return Returns true if the payout operation is successful.
     * @notice 
        - This function is restricted to the CONTROLLER_ROLE.
        - If the amount is 0, it will emit an event and return false (this is to avoid reverts when the amount is 0)
     */
    function payoutJob(
        address _to,
        uint256 _amount
    ) private onlyRole(SharedStructs.CONTROLLER_ROLE) nonNegative(_amount) returns (bool) {
        if (_amount == 0) {
            emit LilypadPayment__ZeroAmountPayout(_to);
            return false;
        }
        
        bool success = token.transfer(_to, _amount);
        if (!success) {
            revert LilypadPayment__transferFailed();
        }
        return true;
    }

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
        hasEnoughEscrow(
            resourceProvider,
            resourceProviderCollateralLockupAmount
        )
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
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

    function HandleJobCompletion(
        string memory _dealId
    ) external nonReentrant onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        // Get the deal from the storage contract, if it doesn't exist, revert
        SharedStructs.Deal memory deal = lilypadStorage.getDeal(_dealId);

        // Calculate the total cost of the job
        uint256 totalCostOfJob = deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.moduleCreatorFee + deal.paymentStructure.JobCreatorSolverFee + deal.paymentStructure.networkCongestionFee;

        // Get the active escrow for the job creator
        uint256 jobCreatorActiveEscrow = activeEscrow[deal.jobCreator];
        
        // Calculate the required active escrow for the resource provider
        uint256 resoureProviderRequiredActiveEscrow = (deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee) * (resourceProviderActiveEscrowScaler/10000);

        // Get the active escrow for the resource provider
        uint256 resourceProviderActiveEscrow = activeEscrow[deal.resourceProvider];

        // Check the accounting to ensure both parties have enough active escrow locked in to complete the job agreement
        if (resourceProviderActiveEscrow < resoureProviderRequiredActiveEscrow || jobCreatorActiveEscrow < totalCostOfJob) {
            revert LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob(_dealId, jobCreatorActiveEscrow, resourceProviderActiveEscrow, totalCostOfJob, resoureProviderRequiredActiveEscrow);
        }

        // Calculate the total protocol fees - includes m% of module creator fee
        uint256 totalProtocolFees = deal.paymentStructure.networkCongestionFee + (deal.paymentStructure.moduleCreatorFee * m)/10000;

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
        payoutJob(treasuryWallet, TreasuryPaymentTotalAmount + grantsAndAirdropsAmount); // TODO: This is being calculated to 0 and reverting becasue of that.  Thought: should the payout return false instead of reverting?

        // Pay the value based rewards
        payoutJob(valueBasedRewardsWallet, valueBasedRewardsAmount);

        // TODO: Didn't distribute the validation pool amount or the the grants/airdrops amount
        
        // Add the amount to the total active escrow for running jobs
        totalActiveEscrow -= totalCostOfJob + resoureProviderRequiredActiveEscrow;

        emit LilypadPayment__JobCompleted(deal.jobCreator, deal.resourceProvider, deal.dealId);

        return true;
    }

    function HandleJobFailure(
        address jobCreator,
        address resourceProvider,
        address moduleCreator
    ) external returns (bool) {
        return true;
    }

    function HandleValidationPassed(
        address jobCreator,
        address resourceProvider,
        address moduleCreator,
        address validatorAddress,
        SharedStructs.ValidationResultStatusEnum state
    ) external returns (bool) {
        return true;
    }

    function HandleValidationFailed(
        address jobCreator,
        address resourceProvider,
        address moduleCreator,
        address validatorAddress
    ) external returns (bool) {
        return true;
    }
    
    /**
     * @notice Sets the p1 parameter (burn amount)
     * @param _p1 New p1 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setP1(uint256 _p1) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_p1 + p2 + p3 == 10000, "Parameters must sum to 10000");
        p1 = _p1;
        emit TokenomicsParameterUpdated("p1", _p1);
    }

    /**
     * @notice Sets the p2 parameter (grants/ecosystem pool fee)
     * @param _p2 New p2 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setP2(uint256 _p2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(p1 + _p2 + p3 == 10000, "Parameters must sum to 10000");
        p2 = _p2;
        emit TokenomicsParameterUpdated("p2", _p2);
    }

    /**
     * @notice Sets the p3 parameter (validation pool fee)
     * @param _p3 New p3 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setP3(uint256 _p3) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(p1 + p2 + _p3 == 10000, "Parameters must sum to 10000");
        p3 = _p3;
        emit TokenomicsParameterUpdated("p3", _p3);
    }

    /**
     * @notice Sets the p parameter (total fee)
     * @param _p New p value
     */
    function setP(uint256 _p) external onlyRole(DEFAULT_ADMIN_ROLE) {
        p = _p;
        emit TokenomicsParameterUpdated("p", _p);
    }

    /**
     * @notice Sets the m parameter (solver fee)
     * @param _m New m value
     */
    function setM(uint256 _m) external onlyRole(DEFAULT_ADMIN_ROLE) {
        m = _m;
        emit TokenomicsParameterUpdated("m", _m);
    }

    /**
     * @notice Sets the alpha parameter (value based rewards pool fee)
     * @param _alpha New alpha value
     */
    function setAlpha(uint256 _alpha) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alpha = _alpha;
        emit TokenomicsParameterUpdated("alpha", _alpha);
    }

    /**
     * @notice Sets the v1 parameter (job creator burn rate)
     * @param _v1 New v1 value
     */
    function setV1(uint256 _v1) external onlyRole(DEFAULT_ADMIN_ROLE) {
        v1 = _v1;
        emit TokenomicsParameterUpdated("v1", _v1);
    }

    /**
     * @notice Sets the v2 parameter (resource provider burn rate)
     * @param _v2 New v2 value
     */
    function setV2(uint256 _v2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        v2 = _v2;
        emit TokenomicsParameterUpdated("v2", _v2);
    }

    function setResourceProviderActiveEscrowScaler(uint256 _resourceProviderActiveEscrowScaler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        resourceProviderActiveEscrowScaler = _resourceProviderActiveEscrowScaler;
        emit TokenomicsParameterUpdated("resourceProviderActiveEscrowScaler", _resourceProviderActiveEscrowScaler);
    }
}
