// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LilypadPaymentEngine} from "../src/LilypadPaymentEngine.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {LilypadStorage} from "../src/LilypadStorage.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {LilypadTokenomics} from "../src/LilypadTokenomics.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract LilypadPaymentEngineTest is Test {
    LilypadPaymentEngine public paymentEngine;
    LilypadToken public token;
    LilypadStorage public lilypadStorage;
    LilypadUser public user;
    LilypadTokenomics public lilypadTokenomics;

    address public constant ALICE = address(0x1); // Job Creator
    address public constant BOB = address(0x2); // Resource Provider
    address public constant CHARLIE = address(0x3); // Module Creator
    address public constant DAVE = address(0x4); // Solver
    address public constant EVE = address(0x5); // Validator
    address public constant TREASURY = address(0x6);
    address public constant VALUE_REWARDS = address(0x7);
    address public constant VALIDATION_POOL = address(0x8);

    uint256 public constant INITIAL_BALANCE = 1000 * 10 ** 18;
    uint256 public constant INITIAL_TREASURY_BALANCE = 10000 * 10 ** 18;
    uint256 public constant INITIAL_VALUE_REWARDS_BALANCE = 10000 * 10 ** 18;
    uint256 public constant INITIAL_VALIDATION_POOL_BALANCE = 10000 * 10 ** 18;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event LilypadPayment__escrowPaid(
        address indexed payee, SharedStructs.PaymentReason indexed paymentReason, uint256 amount
    );
    event LilypadPayment__escrowWithdrawn(address indexed withdrawer, uint256 amount);
    event LilypadPayment__ActiveEscrowLockedForJob(
        address indexed jobCreator, address indexed resourceProvider, string indexed dealId, uint256 cost
    );
    event LilypadPayment__JobCompleted(address indexed jobCreator, address indexed resourceProvider, string dealId);
    event LilypadPayment__JobFailed(address indexed jobCreator, address indexed resourceProvider, string resultId);
    event LilypadPayment__ValidationPassed(
        address indexed jobCreator, address indexed resourceProvider, address indexed validator, uint256 amount
    );
    event LilypadPayment__ValidationFailed(
        address indexed jobCreator, address indexed resourceProvider, address indexed validator, uint256 amount
    );
    event LilypadPayment__TokenomicsParameterUpdated(string indexed parameter, uint256 value);
    event LilypadPayment__TreasuryWalletUpdated(address indexed treasuryWallet);
    event LilypadPayment__ValueBasedRewardsWalletUpdated(address indexed valueBasedRewardsWallet);
    event LilypadPayment__ValidationPoolWalletUpdated(address indexed validationPoolWallet);
    event LilypadPayment__TokensBurned(uint256 blockNumber, uint256 timestamp, uint256 amount);
    event LilypadPayment__L2LilypadTokenUpdated(address indexed l2LilypadToken, address indexed caller);
    event LilypadPayment__LilypadStorageUpdated(address indexed lilypadStorage, address indexed caller);
    event LilypadPayment__LilypadUserUpdated(address indexed lilypadUser, address indexed caller);

    function setUp() public {
        // Deploy token with initial supply (using 1 million instead of 1 billion for initial supply)
        uint256 initialSupply = 1_000_000 * 10 ** 18; // 1 million tokens
        token = new LilypadToken(initialSupply);

        // Deploy and initialize storage
        LilypadStorage storageImpl = new LilypadStorage();
        bytes memory storageInitData = abi.encodeWithSelector(LilypadStorage.initialize.selector);
        ERC1967Proxy storageProxy = new ERC1967Proxy(address(storageImpl), storageInitData);
        lilypadStorage = LilypadStorage(address(storageProxy));

        // Deploy and initialize user
        LilypadUser userImpl = new LilypadUser();
        bytes memory userInitData = abi.encodeWithSelector(LilypadUser.initialize.selector);
        ERC1967Proxy userProxy = new ERC1967Proxy(address(userImpl), userInitData);
        user = LilypadUser(address(userProxy));

        // Deploy and initialize tokenomics
        LilypadTokenomics tokenomicsImpl = new LilypadTokenomics();
        bytes memory tokenomicsInitData = abi.encodeWithSelector(LilypadTokenomics.initialize.selector);
        ERC1967Proxy tokenomicsProxy = new ERC1967Proxy(address(tokenomicsImpl), tokenomicsInitData);
        lilypadTokenomics = LilypadTokenomics(address(tokenomicsProxy));

        // Deploy and initialize payment engine
        LilypadPaymentEngine engineImpl = new LilypadPaymentEngine();
        bytes memory engineInitData = abi.encodeWithSelector(
            LilypadPaymentEngine.initialize.selector,
            address(token),
            address(lilypadStorage),
            address(user),
            address(lilypadTokenomics),
            TREASURY,
            VALUE_REWARDS,
            VALIDATION_POOL
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), engineInitData);
        paymentEngine = LilypadPaymentEngine(address(engineProxy));

        // Setup roles
        token.grantRole(SharedStructs.MINTER_ROLE, address(this));
        user.grantRole(SharedStructs.CONTROLLER_ROLE, address(this));
        user.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));
        lilypadStorage.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));
        paymentEngine.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));
        paymentEngine.grantRole(bytes32(0x00), address(this));

        // Setup test accounts
        token.mint(ALICE, INITIAL_BALANCE);
        token.mint(BOB, INITIAL_BALANCE);
        token.mint(CHARLIE, INITIAL_BALANCE);
        token.mint(DAVE, INITIAL_BALANCE);
        token.mint(EVE, INITIAL_BALANCE);
        token.mint(TREASURY, INITIAL_TREASURY_BALANCE);
        token.mint(VALUE_REWARDS, INITIAL_VALUE_REWARDS_BALANCE);
        token.mint(VALIDATION_POOL, INITIAL_VALIDATION_POOL_BALANCE);

        // Register users and add roles
        user.insertUser(ALICE, "metadata", "url", SharedStructs.UserType.JobCreator);
        user.insertUser(BOB, "metadata", "url", SharedStructs.UserType.ResourceProvider);
        user.insertUser(CHARLIE, "metadata", "url", SharedStructs.UserType.ModuleCreator);
        user.insertUser(DAVE, "metadata", "url", SharedStructs.UserType.Solver);
        user.insertUser(EVE, "metadata", "url", SharedStructs.UserType.Validator);
        user.insertUser(address(this), "metadata", "url", SharedStructs.UserType.Admin);

        // For fuzz tests, we need to modify the test functions to use valid users
        vm.label(ALICE, "Job Creator");
        vm.label(BOB, "Resource Provider");
        vm.label(CHARLIE, "Module Creator");
        vm.label(DAVE, "Solver");
        vm.label(EVE, "Validator");
    }

    // Basic Functionality Tests
    function test_InitialState() public {
        assertEq(paymentEngine.version(), "1.0.0");
        assertEq(paymentEngine.treasuryWallet(), TREASURY);
        assertEq(paymentEngine.valueBasedRewardsWallet(), VALUE_REWARDS);
        assertEq(paymentEngine.validationPoolWallet(), VALIDATION_POOL);
    }

    function test_PayEscrow() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__escrowPaid(ALICE, SharedStructs.PaymentReason.JobFee, amount);

        bool success = paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, amount);

        assertTrue(success);
        assertEq(paymentEngine.escrowBalances(ALICE), amount);
        assertEq(paymentEngine.totalEscrow(), amount);
        vm.stopPrank();
    }

    // Fuzz Tests
    function testFuzz_PayEscrow(uint256 amount) public {
        // Bound amount to reasonable values and use ALICE (known JobCreator)
        amount = bound(amount, 1, INITIAL_BALANCE);

        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), amount);

        bool success = paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, amount);

        assertTrue(success);
        assertEq(paymentEngine.escrowBalances(ALICE), amount);
        assertEq(paymentEngine.totalEscrow(), amount);
        vm.stopPrank();
    }

    function testFuzz_WithdrawEscrow(uint256 depositAmount, uint256 withdrawAmount) public {
        // Bound amounts and use BOB (known ResourceProvider)
        depositAmount = bound(depositAmount, paymentEngine.MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT(), INITIAL_BALANCE);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        // Setup initial deposit
        vm.startPrank(BOB);
        token.approve(address(paymentEngine), depositAmount);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, depositAmount);
        vm.stopPrank();

        // Wait for lock period
        vm.warp(block.timestamp + paymentEngine.COLLATERAL_LOCK_DURATION());

        // Withdraw
        vm.startPrank(BOB);
        paymentEngine.withdrawEscrow(BOB, withdrawAmount);
        vm.stopPrank();

        assertEq(paymentEngine.escrowBalances(BOB), depositAmount - withdrawAmount);
        assertEq(paymentEngine.totalEscrow(), depositAmount - withdrawAmount);
    }

    // Error Cases
    function test_RevertWhen_WithdrawingBeforeLockPeriod() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), amount);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, amount);

        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__escrowNotWithdrawable.selector);
        paymentEngine.withdrawEscrow(BOB, amount);
        vm.stopPrank();
        assertEq(paymentEngine.totalEscrow(), amount);
    }

    function test_RevertWhen_WithdrawingMoreThanBalance() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), amount);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, amount);

        vm.warp(block.timestamp + paymentEngine.COLLATERAL_LOCK_DURATION() + 1);

        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__insufficientEscrowBalanceForWithdrawal.selector);
        paymentEngine.withdrawEscrow(BOB, amount + 1);
        vm.stopPrank();
        assertEq(paymentEngine.totalEscrow(), amount);
    }

    function test_SetTreasuryWallet() public {
        vm.startPrank(address(this));
        address newTreasuryWallet = address(5);

        paymentEngine.setTreasuryWallet(newTreasuryWallet);
        assertEq(paymentEngine.treasuryWallet(), newTreasuryWallet);
        vm.stopPrank();
    }

    function test_SetTreasuryWallet_Reverts_WhenNotAdmin() public {
        vm.startPrank(BOB);
        vm.expectRevert();
        paymentEngine.setTreasuryWallet(address(5));
        vm.stopPrank();
    }

    function test_SetTreasuryWallet_Reverts_WhenZeroAddress() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__ZeroTreasuryWallet.selector);
        paymentEngine.setTreasuryWallet(address(0));
        vm.stopPrank();
    }

    function test_SetValueBasedRewardsWallet() public {
        vm.startPrank(address(this));
        address newValueBasedRewardsWallet = address(5);

        paymentEngine.setValueBasedRewardsWallet(newValueBasedRewardsWallet);
        assertEq(paymentEngine.valueBasedRewardsWallet(), newValueBasedRewardsWallet);
        vm.stopPrank();
    }

    function test_SetValueBasedRewardsWallet_Reverts_WhenNotAdmin() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        paymentEngine.setValueBasedRewardsWallet(address(5));
        vm.stopPrank();
    }

    function test_SetValueBasedRewardsWallet_Reverts_WhenZeroAddress() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__ZeroValueBasedRewardsWallet.selector);
        paymentEngine.setValueBasedRewardsWallet(address(0));
        vm.stopPrank();
    }

    function test_SetValidationPoolWallet() public {
        vm.startPrank(address(this));
        address newValidationPoolWallet = address(5);

        paymentEngine.setValidationPoolWallet(newValidationPoolWallet);
        assertEq(paymentEngine.validationPoolWallet(), newValidationPoolWallet);
        vm.stopPrank();
    }

    function test_SetValidationPoolWallet_Reverts_WhenNotAdmin() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        paymentEngine.setValidationPoolWallet(address(5));
        vm.stopPrank();
    }

    function test_SetValidationPoolWallet_Reverts_WhenZeroAddress() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__ZeroValidationPoolWallet.selector);
        paymentEngine.setValidationPoolWallet(address(0));
        vm.stopPrank();
    }

    // Escrow Locking Tests
    function test_LockEscrowForJob() public {
        uint256 jobCost = 100 * 10 ** 18;
        uint256 rpCollateral = jobCost * 110 / 100;

        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        vm.startPrank(address(this));
        bool success = paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpCollateral);

        assertTrue(success);
        assertEq(paymentEngine.activeEscrow(ALICE), jobCost);
        assertEq(paymentEngine.activeEscrow(BOB), rpCollateral);
        assertEq(paymentEngine.escrowBalances(ALICE), 0);
        assertEq(paymentEngine.escrowBalances(BOB), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_LockingInsufficientEscrow() public {
        uint256 jobCost = 100 * 10 ** 18;
        uint256 rpCollateral = jobCost * 110 / 100;

        // Only fund job creator, not resource provider
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(address(this));
        // Update expectRevert to match the new error format with parameters
        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadPaymentEngine.LilypadPayment__insufficientEscrowAmount.selector,
                0, // BOB's current escrow balance
                rpCollateral // required amount
            )
        );
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpCollateral);
        vm.stopPrank();
    }

    // Job Completion Tests
    function test_HandleJobCompletion() public {
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10 ** 18; // Base payment without fees
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10 ** 18;

        // Setup escrow for job creator and resource provider
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment // Use the base payment amount
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow for job
        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);
        // At this point, the total active escrow should be the sum of the job creator's escrow and the resource provider's escrow
        assertEq(paymentEngine.totalActiveEscrow(), jobCost + rpRequiredEscrow);

        // Switch to payment engine to approve token transfers
        vm.stopPrank();
        vm.startPrank(address(paymentEngine));

        // Complete job
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);

        // Assert final balances
        assertEq(paymentEngine.activeEscrow(ALICE), 0);
        assertEq(paymentEngine.activeEscrow(BOB), 0);
        assertEq(paymentEngine.escrowBalances(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(
            token.balanceOf(CHARLIE),
            INITIAL_BALANCE
                + (
                    deal.paymentStructure.moduleCreatorFee
                        - (deal.paymentStructure.moduleCreatorFee * lilypadTokenomics.m()) / 10000
                )
        );
        assertEq(
            token.balanceOf(DAVE),
            INITIAL_BALANCE + deal.paymentStructure.jobCreatorSolverFee
                + deal.paymentStructure.resourceProviderSolverFee
        );

        // Calculate expected treasury amount
        uint256 protocolFees = deal.paymentStructure.networkCongestionFee
            + (deal.paymentStructure.moduleCreatorFee * lilypadTokenomics.m()) / 10000;
        uint256 expectedTreasuryAmount = (protocolFees * lilypadTokenomics.p()) / 10000;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);

        // Calculate expected value based rewards amount
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);

        // Verify that the total active escrow is reset to 0
        assertEq(paymentEngine.totalActiveEscrow(), 0);

        // Only the resource provider's collateral should be left
        assertEq(paymentEngine.totalEscrow(), rpCollateral);

        vm.stopPrank();
    }

    function test_HandleJobCompletion_whenPValueIsNonZero() public {
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10 ** 18; // Base payment without fees
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10 ** 18;

        vm.startPrank(address(this));
        lilypadTokenomics.setPvalues(2000, 4000, 4000);
        lilypadTokenomics.setP(1000);
        vm.stopPrank();

        // Setup escrow for job creator and resource provider
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment // Use the base payment amount
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow for job
        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);
        // At this point, the total active escrow should be the sum of the job creator's escrow and the resource provider's escrow
        assertEq(paymentEngine.totalActiveEscrow(), jobCost + rpRequiredEscrow);

        // Switch to payment engine to approve token transfers
        vm.stopPrank();
        vm.startPrank(address(paymentEngine));

        // Complete job
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);

        // Assert final balances
        assertEq(paymentEngine.activeEscrow(ALICE), 0);
        assertEq(paymentEngine.activeEscrow(BOB), 0);
        assertEq(paymentEngine.escrowBalances(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(
            token.balanceOf(CHARLIE),
            INITIAL_BALANCE
                + (
                    deal.paymentStructure.moduleCreatorFee
                        - (deal.paymentStructure.moduleCreatorFee * lilypadTokenomics.m()) / 10000
                )
        );
        assertEq(
            token.balanceOf(DAVE),
            INITIAL_BALANCE + deal.paymentStructure.jobCreatorSolverFee
                + deal.paymentStructure.resourceProviderSolverFee
        );

        // Calculate expected treasury amount
        uint256 protocolFees = deal.paymentStructure.networkCongestionFee
            + (deal.paymentStructure.moduleCreatorFee * lilypadTokenomics.m()) / 10000;
        uint256 expectedTreasuryAmount = (protocolFees * lilypadTokenomics.p()) / 10000;
        uint256 expectedBurnAmount = (expectedTreasuryAmount * lilypadTokenomics.p1()) / 10000;
        uint256 expectedGrantsAndAirdropsAmount = (expectedTreasuryAmount * lilypadTokenomics.p2()) / 10000;

        assertEq(
            token.balanceOf(TREASURY),
            INITIAL_TREASURY_BALANCE + expectedTreasuryAmount + expectedBurnAmount + expectedGrantsAndAirdropsAmount
        );

        // Calculate expected value based rewards amount
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);

        // Verify that the total active escrow is reset to 0
        assertEq(paymentEngine.totalActiveEscrow(), 0);

        // Only the resource provider's collateral should be left
        assertEq(paymentEngine.totalEscrow(), rpCollateral);

        assertEq(paymentEngine.activeBurnTokens(), expectedBurnAmount);

        vm.stopPrank();
    }

    function test_HandleJobCompletion_ZeroModuleCreatorFee() public {
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 0; // Zero module creator fee
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10 ** 18;

        // Setup escrow and complete standard setup
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create deal with zero module creator fee
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);
        assertEq(paymentEngine.activeEscrow(ALICE), 0);
        assertEq(paymentEngine.activeEscrow(BOB), 0);
        assertEq(paymentEngine.escrowBalances(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE); // Should remain unchanged
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee + resourceProviderSolverFee);

        // Calculate expected protocol fees
        uint256 protocolFees = networkCongestionFee + (moduleCreatorFee * lilypadTokenomics.m()) / 10000;
        uint256 expectedTreasuryAmount = (protocolFees * lilypadTokenomics.p()) / 10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);

        assertEq(paymentEngine.totalEscrow(), rpCollateral);
        assertEq(paymentEngine.totalActiveEscrow(), 0);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_ZeroNetworkCongestionFee() public {
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 0; // Zero network congestion fee
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10 ** 18;

        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);
        assertEq(paymentEngine.activeEscrow(ALICE), 0);
        assertEq(paymentEngine.activeEscrow(BOB), 0);
        assertEq(paymentEngine.escrowBalances(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(
            token.balanceOf(CHARLIE),
            INITIAL_BALANCE + (moduleCreatorFee - (moduleCreatorFee * lilypadTokenomics.m()) / 10000)
        );
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee + resourceProviderSolverFee);

        // Calculate expected protocol fees
        uint256 protocolFees = networkCongestionFee + (moduleCreatorFee * lilypadTokenomics.m()) / 10000;
        uint256 expectedTreasuryAmount = (protocolFees * lilypadTokenomics.p()) / 10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);

        assertEq(paymentEngine.totalActiveEscrow(), 0);
        assertEq(paymentEngine.totalEscrow(), rpCollateral);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_MinimalPayments() public {
        uint256 jobCreatorSolverFee = 0;
        uint256 resourceProviderSolverFee = 0;
        uint256 moduleCreatorFee = 0;
        uint256 networkCongestionFee = 0;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = paymentEngine.MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT();

        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);
        // Verify minimal payments were processed correctly
        assertEq(paymentEngine.activeEscrow(ALICE), 0);
        assertEq(paymentEngine.activeEscrow(BOB), 0);
        assertEq(paymentEngine.escrowBalances(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(
            token.balanceOf(CHARLIE),
            INITIAL_BALANCE + (moduleCreatorFee - (moduleCreatorFee * lilypadTokenomics.m()) / 10000)
        );
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee + resourceProviderSolverFee);

        // Calculate expected protocol fees
        uint256 protocolFees = networkCongestionFee + (moduleCreatorFee * lilypadTokenomics.m()) / 10000;
        uint256 expectedTreasuryAmount = (protocolFees * lilypadTokenomics.p()) / 10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;
        uint256 expectedValidationPoolAmount = protocolFees - expectedTreasuryAmount - expectedValueBasedRewardsAmount;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);
        assertEq(token.balanceOf(VALIDATION_POOL), INITIAL_VALIDATION_POOL_BALANCE + expectedValidationPoolAmount);
        assertEq(paymentEngine.totalActiveEscrow(), 0);
        assertEq(paymentEngine.totalEscrow(), rpCollateral);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_RevertWhen_DealNotFound() public {
        // We need to call HandleJobCompletion as the payment engine
        vm.startPrank(address(paymentEngine));

        // The error comes from LilypadStorage, and includes a string parameter
        bytes memory expectedError = abi.encodeWithSignature("LilypadStorage__DealNotFound(string)", "deal1");
        vm.expectRevert(expectedError);
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        paymentEngine.handleJobCompletion(result);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_RevertWhen_InvalidStatus() public {
        // Create result with wrong status
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsRejected, // Wrong status
            timestamp: block.timestamp
        });

        vm.startPrank(address(paymentEngine));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__InvalidResultStatus.selector);
        paymentEngine.handleJobCompletion(result);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_OnlyBasePayment() public {
        // All fees zero except base payment
        uint256 jobCreatorSolverFee = 0;
        uint256 resourceProviderSolverFee = 0;
        uint256 moduleCreatorFee = 0;
        uint256 networkCongestionFee = 0;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCost = basePayment; // No fees to add
        uint256 rpCollateral = 10 * 10 ** 18;

        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow = basePayment * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);
        // Verify only base payment was processed
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE); // Unchanged
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE); // Unchanged
        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE); // Unchanged
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE); // Unchanged
        assertEq(token.balanceOf(VALIDATION_POOL), INITIAL_VALIDATION_POOL_BALANCE); // Unchanged
        vm.stopPrank();
    }

    function test_HandleJobCompletion_MixedZeroAndNonZeroFees() public {
        // Mix of zero and non-zero fees
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 0;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 0;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10 ** 18;

        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.handleJobCompletion(result);

        assertTrue(success);
        // Verify mixed fee scenario worked correctly
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee); // Only job creator solver fee

        // Calculate expected protocol fees (only from module creator fee since network congestion is 0)
        uint256 protocolFees = (moduleCreatorFee * lilypadTokenomics.m()) / 10000;
        uint256 expectedTreasuryAmount = (protocolFees * lilypadTokenomics.p()) / 10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;
        uint256 expectedValidationPoolAmount = protocolFees - expectedTreasuryAmount - expectedValueBasedRewardsAmount;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);
        assertEq(token.balanceOf(VALIDATION_POOL), INITIAL_VALIDATION_POOL_BALANCE + expectedValidationPoolAmount);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_RevertWhen_InsufficientActiveEscrow() public {
        // Setup fees and costs
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);
        vm.stopPrank();

        // Calculate required escrows
        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        // Skip the lockup of escrow for job creator and resource provider

        // Test: Insufficient escrow
        vm.startPrank(address(paymentEngine));
        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadPaymentEngine.LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob.selector,
                "deal1",
                0, // jobCreatorActiveEscrow
                0, // resourceProviderActiveEscrow
                jobCost,
                rpRequiredEscrow
            )
        );
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        paymentEngine.handleJobCompletion(result);
        vm.stopPrank();
    }

    function test_HandleJobFailure() public {
        // Setup initial state
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 20 * 10 ** 18; // Large enough to cover slashing

        // Setup escrow for both parties
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow
        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpRequiredEscrow);
        vm.stopPrank();

        // Create result
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsRejected,
            timestamp: block.timestamp
        });

        // Test job failure
        vm.startPrank(address(paymentEngine));

        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__JobFailed(ALICE, BOB, "result1");

        uint256 initialTotalEscrow = paymentEngine.totalEscrow();
        uint256 initialActiveEscrow = paymentEngine.totalActiveEscrow();
        bool success = paymentEngine.handleJobFailure(result);
        assertTrue(success);

        // Verify escrow was slashed for the resource provider
        assertEq(paymentEngine.escrowBalances(BOB), rpCollateral - rpRequiredEscrow);
        assertEq(paymentEngine.totalEscrow(), initialTotalEscrow - rpRequiredEscrow - jobCost);
        assertEq(paymentEngine.totalActiveEscrow(), initialActiveEscrow - rpRequiredEscrow - jobCost);

        // Since the job creator's escrow was refunded, their balance should be the same as the initial balance
        assertEq(token.balanceOf(ALICE), INITIAL_BALANCE);

        vm.stopPrank();
    }

    function test_HandleJobFailure_RevertWhen_DealNotFound() public {
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "nonexistent",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsRejected,
            timestamp: block.timestamp
        });

        vm.startPrank(address(paymentEngine));
        vm.expectRevert(abi.encodeWithSignature("LilypadStorage__DealNotFound(string)", "nonexistent"));
        paymentEngine.handleJobFailure(result);
        vm.stopPrank();
    }

    function test_HandleJobFailure_RevertWhen_InvalidStatus() public {
        // Create result with wrong status
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted, // Wrong status
            timestamp: block.timestamp
        });

        vm.startPrank(address(paymentEngine));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__InvalidResultStatus.selector);
        paymentEngine.handleJobFailure(result);
        vm.stopPrank();
    }

    function test_HandleJobFailure_RevertWhen_InsufficientActiveEscrow() public {
        // Setup fees and costs
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 basePayment = 5 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);
        vm.stopPrank();

        // Calculate required escrows
        uint256 rpRequiredEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        // Skip the lockup of escrow for job creator and resource provider

        // Test: Insufficient escrow
        vm.startPrank(address(paymentEngine));
        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadPaymentEngine.LilypadPayment__HandleJobFailure__InsufficientActiveEscrowToCompleteJob.selector,
                "deal1",
                0, // jobCreatorActiveEscrow
                0, // resourceProviderActiveEscrow
                jobCost,
                rpRequiredEscrow
            )
        );
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsRejected,
            timestamp: block.timestamp
        });
        paymentEngine.handleJobFailure(result);
        vm.stopPrank();
    }

    function test_HandleValidationPassed() public {
        // Setup initial job
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 jobCost = basePayment + jobCreatorSolverFee + networkCongestionFee + moduleCreatorFee;
        uint256 rpCollateral = 20 * 10 ** 18;
        // Setup validation job deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        // Setup escrow for job creator and validator
        uint256 validatorRequiredActiveEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(EVE);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(EVE, SharedStructs.PaymentReason.ValidationCollateral, rpCollateral);
        vm.stopPrank();

        // Lock active escrow
        vm.startPrank(address(paymentEngine));
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, EVE, "deal1", jobCost, validatorRequiredActiveEscrow);
        vm.stopPrank();

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        lilypadStorage.saveResult("result1", result);
        vm.stopPrank();

        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationAccepted,
            timestamp: block.timestamp,
            validator: EVE
        });

        vm.startPrank(address(paymentEngine));

        uint256 initialValidatorBalance = token.balanceOf(EVE);
        uint256 initialActiveEscrow = paymentEngine.totalActiveEscrow();
        uint256 initialTotalEscrow = paymentEngine.totalEscrow();

        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__ValidationPassed(ALICE, BOB, EVE, jobCost);

        bool success = paymentEngine.handleValidationPassed(validationResult);
        assertTrue(success);

        // Verify escrow and payment state
        assertEq(paymentEngine.activeEscrow(ALICE), 0);
        assertEq(paymentEngine.totalActiveEscrow(), initialActiveEscrow - jobCost - validatorRequiredActiveEscrow);
        assertEq(token.balanceOf(EVE), initialValidatorBalance + jobCost);

        // Verify active escrow was reduced
        assertEq(paymentEngine.totalEscrow(), initialTotalEscrow - jobCost);

        // Verify validator's active escrow was returned to their balance
        assertEq(paymentEngine.escrowBalances(EVE), rpCollateral);

        vm.stopPrank();
    }

    function test_HandleValidationPassed_RevertWhen_InvalidStatus() public {
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationRejected,
            timestamp: block.timestamp,
            validator: EVE
        });

        vm.startPrank(address(paymentEngine));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__InvalidValidationResultStatus.selector);
        paymentEngine.handleValidationPassed(validationResult);
        vm.stopPrank();
    }

    function test_HandleValidationFailed() public {
        // Setup initial job
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 jobCost = basePayment + jobCreatorSolverFee + networkCongestionFee + moduleCreatorFee;
        uint256 rpCollateral = 20 * 10 ** 18;

        // Setup original job deal
        SharedStructs.Deal memory originalDeal = SharedStructs.Deal({
            dealId: "originalDeal",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        // Setup validation job deal
        SharedStructs.Deal memory validationDeal = SharedStructs.Deal({
            dealId: "validationDeal",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID2",
            resourceOfferCID: "resourceCID2",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        // Setup escrow for resource provider and validator
        uint256 validatorRequiredActiveEscrow =
            (basePayment + resourceProviderSolverFee) * (lilypadTokenomics.resourceProviderActiveEscrowScaler() / 10000);

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(EVE);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(EVE, SharedStructs.PaymentReason.ValidationCollateral, rpCollateral);
        vm.stopPrank();

        // Lock active escrow
        vm.startPrank(address(paymentEngine));
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, EVE, "validationDeal", jobCost, validatorRequiredActiveEscrow);
        vm.stopPrank();

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("originalDeal", originalDeal);
        lilypadStorage.saveDeal("validationDeal", validationDeal);

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "validationDeal",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        lilypadStorage.saveResult("result1", result);
        vm.stopPrank();

        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationRejected,
            timestamp: block.timestamp,
            validator: EVE
        });

        vm.startPrank(address(paymentEngine));

        uint256 initialRPBalance = paymentEngine.escrowBalances(BOB);
        uint256 totalPenalty = jobCost * 2; // Both validation and original job costs

        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__ValidationFailed(ALICE, BOB, EVE, totalPenalty);

        bool success = paymentEngine.handleValidationFailed(validationResult, originalDeal);
        assertTrue(success);

        // Verify escrow states
        assertEq(paymentEngine.escrowBalances(BOB), initialRPBalance - totalPenalty);
        assertEq(paymentEngine.escrowBalances(EVE), rpCollateral);
        assertEq(paymentEngine.totalActiveEscrow(), 0);
        assertEq(token.balanceOf(VALIDATION_POOL), INITIAL_VALIDATION_POOL_BALANCE + totalPenalty);

        vm.stopPrank();
    }

    function test_HandleValidationFailed_RevertWhen_InvalidStatus() public {
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });

        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationAccepted,
            timestamp: block.timestamp,
            validator: EVE
        });

        vm.startPrank(address(paymentEngine));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__InvalidValidationResultStatus.selector);
        paymentEngine.handleValidationFailed(validationResult, deal);
        vm.stopPrank();
    }

    function test_UpdateActiveBurnTokens() public {
        // We need to create a completed job to generate burn tokens
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 20 * 10 ** 18;

        vm.startPrank(address(this));
        lilypadTokenomics.setPvalues(2000, 4000, 4000);
        lilypadTokenomics.setP(1000);
        vm.stopPrank();

        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment // Changed from jobCost to basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow for job
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpCollateral);

        // Complete job to generate burn tokens
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result-1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        paymentEngine.handleJobCompletion(result);
        vm.stopPrank();

        uint256 currentActiveBurnTokens = paymentEngine.activeBurnTokens();
        assertTrue(currentActiveBurnTokens > 0, "Should have active burn tokens");

        // Update active burn tokens
        vm.startPrank(address(paymentEngine));
        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__TokensBurned(block.number, block.timestamp, currentActiveBurnTokens);

        bool success = paymentEngine.updateActiveBurnTokens(currentActiveBurnTokens);
        assertTrue(success);

        // Verify state changes
        assertEq(paymentEngine.activeBurnTokens(), 0);
        vm.stopPrank();
    }

    function testFuzz_UpdateActiveBurnTokens(uint256 burnAmount) public {
        // Bound burnAmount to a reasonable range (1 to 1000 tokens)
        burnAmount = bound(burnAmount, 1, 1000 * 10 ** 18);

        // Setup initial state with some active burn tokens
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 20 * 10 ** 18;

        vm.startPrank(address(this));
        lilypadTokenomics.setPvalues(2000, 4000, 4000);
        lilypadTokenomics.setP(1000);
        vm.stopPrank();

        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(ALICE, SharedStructs.PaymentReason.JobFee, jobCost);
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(BOB, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow for job
        paymentEngine.initiateLockupOfEscrowForJob(ALICE, BOB, "deal1", jobCost, rpCollateral);

        // Complete job to generate burn tokens
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result-1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        paymentEngine.handleJobCompletion(result);
        vm.stopPrank();

        uint256 currentActiveBurnTokens = paymentEngine.activeBurnTokens();

        // Skip test if burnAmount is greater than available tokens
        if (burnAmount > currentActiveBurnTokens) {
            return;
        }

        // Update active burn tokens
        vm.startPrank(address(paymentEngine));
        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__TokensBurned(block.number, block.timestamp, burnAmount);

        bool success = paymentEngine.updateActiveBurnTokens(burnAmount);
        assertTrue(success);

        // Verify state changes
        assertEq(paymentEngine.activeBurnTokens(), currentActiveBurnTokens - burnAmount);
        vm.stopPrank();
    }

    function test_RevertWhen_BurningMoreThanActive() public {
        uint256 currentActiveBurnTokens = paymentEngine.activeBurnTokens();

        vm.startPrank(address(paymentEngine));
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__InsufficientActiveBurnTokens.selector);
        paymentEngine.updateActiveBurnTokens(currentActiveBurnTokens + 1);
        vm.stopPrank();
    }

    function test_RevertWhen_NonControllerUpdatesBurnTokens() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        paymentEngine.updateActiveBurnTokens(1);
        vm.stopPrank();
    }
}
