// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LilypadPaymentEngine.sol";
import "../src/LilypadToken.sol";
import "../src/LilypadStorage.sol";
import "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract LilypadPaymentEngineTest is Test {
    LilypadPaymentEngine public paymentEngine;
    LilypadToken public token;
    LilypadStorage public lilypadStorage;
    LilypadUser public user;

    address public constant ALICE = address(0x1);  // Job Creator
    address public constant BOB = address(0x2);    // Resource Provider
    address public constant CHARLIE = address(0x3); // Module Creator
    address public constant DAVE = address(0x4);    // Solver
    address public constant EVE = address(0x5);     // Validator
    address public constant TREASURY = address(0x6);
    address public constant VALUE_REWARDS = address(0x7);

    uint256 public constant INITIAL_BALANCE = 1000 * 10**18;
    uint256 public constant INITIAL_TREASURY_BALANCE = 10000 * 10**18;
    uint256 public constant INITIAL_VALUE_REWARDS_BALANCE = 10000 * 10**18;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event LilypadPayment__escrowPaid(
        address indexed payee,
        SharedStructs.PaymentReason indexed paymentReason,
        uint256 amount
    );
    event LilypadPayment__escrowWithdrawn(
        address indexed withdrawer,
        uint256 amount
    );
    event LilypadPayment__ActiveEscrowLockedForJob(
        address indexed jobCreator,
        address indexed resourceProvider,
        string indexed dealId,
        uint256 cost
    );
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

    function setUp() public {
        // Deploy token with initial supply (using 1 million instead of 1 billion for initial supply)
        uint256 initialSupply = 1_000_000 * 10**18; // 1 million tokens
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

        // Deploy and initialize payment engine
        LilypadPaymentEngine engineImpl = new LilypadPaymentEngine();
        bytes memory engineInitData = abi.encodeWithSelector(
            LilypadPaymentEngine.initialize.selector,
            address(token),
            address(lilypadStorage),
            address(user),
            TREASURY,
            VALUE_REWARDS
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

        // Set initial parameters
        paymentEngine.setP(0); // 0 protocol revenue
        paymentEngine.setP1(0); // 50%    
        paymentEngine.setP2(5000); // 50%
        paymentEngine.setP3(5000); // 50%
        paymentEngine.setM(200);   // 2%
        paymentEngine.setAlpha(150); // 1.5x
        paymentEngine.setV1(200);    // 2x
        paymentEngine.setV2(150);    // 1.5x
    }

    // Basic Functionality Tests
    function test_InitialState() public {
        assertEq(paymentEngine.version(), "1.0.0");
        assertEq(paymentEngine.treasuryWallet(), TREASURY);
        assertEq(paymentEngine.valueBasedRewardsWallet(), VALUE_REWARDS);
    }

    function test_PayEscrow() public {
        uint256 amount = 100 * 10**18;
        
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), amount);
        
        vm.expectEmit(true, true, true, true);
        emit LilypadPayment__escrowPaid(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            amount
        );

        bool success = paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            amount
        );
        
        assertTrue(success);
        assertEq(paymentEngine.escrowBalanceOf(ALICE), amount);
        assertEq(paymentEngine.totalEscrow(), amount);
        vm.stopPrank();
    }

    // Fuzz Tests
    function testFuzz_PayEscrow(uint256 amount) public {
        // Bound amount to reasonable values and use ALICE (known JobCreator)
        amount = bound(amount, 1, INITIAL_BALANCE);
        
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), amount);
        
        bool success = paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            amount
        );
        
        assertTrue(success);
        assertEq(paymentEngine.escrowBalanceOf(ALICE), amount);
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
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            depositAmount
        );
        vm.stopPrank();
        
        // Wait for lock period
        vm.warp(block.timestamp + paymentEngine.COLLATERAL_LOCK_DURATION());
        
        // Withdraw
        vm.startPrank(BOB);
        paymentEngine.withdrawEscrow(BOB, withdrawAmount);
        vm.stopPrank();
        
        assertEq(paymentEngine.escrowBalanceOf(BOB), depositAmount - withdrawAmount);
        assertEq(paymentEngine.totalEscrow(), depositAmount - withdrawAmount);
    }

    // Error Cases
    function test_RevertWhen_WithdrawingBeforeLockPeriod() public {
        uint256 amount = 100 * 10**18;
        
        vm.startPrank(BOB);
        token.approve(address(paymentEngine), amount);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            amount
        );
        
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__escrowNotWithdrawable.selector);
        paymentEngine.withdrawEscrow(BOB, amount);
        vm.stopPrank();
        assertEq(paymentEngine.totalEscrow(), amount);
    }

    function test_RevertWhen_WithdrawingMoreThanBalance() public {
        uint256 amount = 100 * 10**18;
        
        vm.startPrank(BOB);
        token.approve(address(paymentEngine), amount);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            amount
        );
        
        vm.warp(block.timestamp + paymentEngine.COLLATERAL_LOCK_DURATION() + 1);
        
        vm.expectRevert(LilypadPaymentEngine.LilypadPayment__insufficientEscrowBalanceForWithdrawal.selector);
        paymentEngine.withdrawEscrow(BOB, amount + 1);
        vm.stopPrank();
        assertEq(paymentEngine.totalEscrow(), amount);
    }

    // Job Completion Tests
    function test_HandleJobCompletion() public {
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 1 * 10**18;
        uint256 moduleCreatorFee = 1 * 10**18;
        uint256 networkCongestionFee = 1 * 10**18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10**18;  // Base payment without fees
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10**18;
        
        // Setup escrow for job creator and resource provider
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment  // Use the base payment amount
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow for job
        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );
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
        bool success = paymentEngine.HandleJobCompletion(result);
        
        assertTrue(success);
        
        // Assert final balances
        assertEq(paymentEngine.activeEscrowBalanceOf(ALICE), 0);
        assertEq(paymentEngine.activeEscrowBalanceOf(BOB), 0);
        assertEq(paymentEngine.escrowBalanceOf(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE + (deal.paymentStructure.moduleCreatorFee - (deal.paymentStructure.moduleCreatorFee * paymentEngine.m())/10000));
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + deal.paymentStructure.JobCreatorSolverFee + deal.paymentStructure.resourceProviderSolverFee);

        // Calculate expected treasury amount
        uint256 protocolFees = deal.paymentStructure.networkCongestionFee + 
            (deal.paymentStructure.moduleCreatorFee * paymentEngine.m())/10000;
        uint256 expectedTreasuryAmount = (protocolFees * paymentEngine.p())/10000;

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

    function test_HandleJobCompletion_ZeroModuleCreatorFee() public {
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 1 * 10**18;
        uint256 moduleCreatorFee = 0;  // Zero module creator fee
        uint256 networkCongestionFee = 1 * 10**18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10**18;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10**18;
        
        // Setup escrow and complete standard setup
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));
         SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.HandleJobCompletion(result);
        
        assertTrue(success);
        assertEq(paymentEngine.activeEscrowBalanceOf(ALICE), 0);
        assertEq(paymentEngine.activeEscrowBalanceOf(BOB), 0);
        assertEq(paymentEngine.escrowBalanceOf(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE); // Should remain unchanged
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee + resourceProviderSolverFee);

        // Calculate expected protocol fees
        uint256 protocolFees = networkCongestionFee + (moduleCreatorFee * paymentEngine.m())/10000;
        uint256 expectedTreasuryAmount = (protocolFees * paymentEngine.p())/10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);

        assertEq(paymentEngine.totalEscrow(), rpCollateral);
        assertEq(paymentEngine.totalActiveEscrow(), 0);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_ZeroNetworkCongestionFee() public {
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 1 * 10**18;
        uint256 moduleCreatorFee = 1 * 10**18;
        uint256 networkCongestionFee = 0;  // Zero network congestion fee
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 basePayment = 5 * 10**18;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10**18;
        
        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));
         SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.HandleJobCompletion(result);
        
        assertTrue(success);
        assertEq(paymentEngine.activeEscrowBalanceOf(ALICE), 0);
        assertEq(paymentEngine.activeEscrowBalanceOf(BOB), 0);
        assertEq(paymentEngine.escrowBalanceOf(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE + (moduleCreatorFee - (moduleCreatorFee * paymentEngine.m())/10000));
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee + resourceProviderSolverFee);

        // Calculate expected protocol fees
        uint256 protocolFees = networkCongestionFee + (moduleCreatorFee * paymentEngine.m())/10000;
        uint256 expectedTreasuryAmount = (protocolFees * paymentEngine.p())/10000;
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
        uint256 basePayment = 5 * 10**18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = paymentEngine.MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT();
        
        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));
         SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.HandleJobCompletion(result);
        
        assertTrue(success);
        // Verify minimal payments were processed correctly
        assertEq(paymentEngine.activeEscrowBalanceOf(ALICE), 0);
        assertEq(paymentEngine.activeEscrowBalanceOf(BOB), 0);
        assertEq(paymentEngine.escrowBalanceOf(BOB), rpCollateral);
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE + (moduleCreatorFee - (moduleCreatorFee * paymentEngine.m())/10000));
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee + resourceProviderSolverFee);

        // Calculate expected protocol fees
        uint256 protocolFees = networkCongestionFee + (moduleCreatorFee * paymentEngine.m())/10000;
        uint256 expectedTreasuryAmount = (protocolFees * paymentEngine.p())/10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;

        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);
        assertEq(paymentEngine.totalActiveEscrow(), 0);
        assertEq(paymentEngine.totalEscrow(), rpCollateral);
        vm.stopPrank();
    }


    function test_HandleJobCompletion_RevertWhen_DealNotFound() public {
        // We need to call HandleJobCompletion as the payment engine
        vm.startPrank(address(paymentEngine));
        
        // The error comes from LilypadStorage, and includes a string parameter
        bytes memory expectedError = abi.encodeWithSignature(
            "LilypadStorage__DealNotFound(string)",
            "deal1"
        );
        vm.expectRevert(expectedError);
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        paymentEngine.HandleJobCompletion(result);
        vm.stopPrank();
    }

    // Parameter Update Tests
    function test_UpdateTokenomicsParameters() public {
        vm.startPrank(address(this)); // Default admin role
        paymentEngine.setP(0); // 0 protocol revenue
        paymentEngine.setP1(0); // 0%
        paymentEngine.setP2(5000); // 50%
        paymentEngine.setP3(5000); // 50% validation pool fee
        paymentEngine.setM(200);   // 2%
        paymentEngine.setAlpha(150); // 1.5x
        paymentEngine.setV1(200);    // 2x
        paymentEngine.setV2(150);    // 1.5x
        paymentEngine.setResourceProviderActiveEscrowScaler(10000);
        assertEq(paymentEngine.p1(), 0);
        assertEq(paymentEngine.p2(), 5000);
        assertEq(paymentEngine.p3(), 5000);
        assertEq(paymentEngine.p(), 0);
        assertEq(paymentEngine.m(), 200);
        assertEq(paymentEngine.alpha(), 150);
        assertEq(paymentEngine.v1(), 200);
        assertEq(paymentEngine.v2(), 150);
        assertEq(paymentEngine.resourceProviderActiveEscrowScaler(), 10000);
        vm.stopPrank();
    }

    function test_RevertWhen_NonAdminUpdatesParameters() public {
        vm.startPrank(ALICE);
        
        vm.expectRevert();
        paymentEngine.setM(5000);
        
        vm.expectRevert();
        paymentEngine.setP1(5000);
        
        vm.stopPrank();
    }

    // Escrow Locking Tests
    function test_LockEscrowForJob() public {
        uint256 jobCost = 100 * 10**18;
        uint256 rpCollateral = jobCost * 110 / 100;

        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
        vm.stopPrank();

        vm.startPrank(address(this));
        bool success = paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpCollateral
        );

        assertTrue(success);
        assertEq(paymentEngine.activeEscrowBalanceOf(ALICE), jobCost);
        assertEq(paymentEngine.activeEscrowBalanceOf(BOB), rpCollateral);
        assertEq(paymentEngine.escrowBalanceOf(ALICE), 0);
        assertEq(paymentEngine.escrowBalanceOf(BOB), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_LockingInsufficientEscrow() public {
        uint256 jobCost = 100 * 10**18;
        uint256 rpCollateral = jobCost * 110 / 100;

        // Only fund job creator, not resource provider
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(address(this));
        // Update expectRevert to match the new error format with parameters
        vm.expectRevert(abi.encodeWithSelector(
            LilypadPaymentEngine.LilypadPayment__insufficientEscrowAmount.selector,
            0,  // BOB's current escrow balance
            rpCollateral  // required amount
        ));
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpCollateral
        );
        vm.stopPrank();
    }

    function test_HandleJobCompletion_OnlyBasePayment() public {
        // All fees zero except base payment
        uint256 jobCreatorSolverFee = 0;
        uint256 resourceProviderSolverFee = 0;
        uint256 moduleCreatorFee = 0;
        uint256 networkCongestionFee = 0;
        uint256 basePayment = 5 * 10**18;
        uint256 jobCost = basePayment; // No fees to add
        uint256 rpCollateral = 10 * 10**18;
        
        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
        vm.stopPrank();

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow = basePayment * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.HandleJobCompletion(result);
        
        assertTrue(success);
        // Verify only base payment was processed
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(CHARLIE), INITIAL_BALANCE); // Unchanged
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE); // Unchanged
        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE); // Unchanged
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE); // Unchanged
        vm.stopPrank();
    }

    function test_HandleJobCompletion_MixedZeroAndNonZeroFees() public {
        // Mix of zero and non-zero fees
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 0;
        uint256 moduleCreatorFee = 1 * 10**18;
        uint256 networkCongestionFee = 0;
        uint256 basePayment = 5 * 10**18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 10 * 10**18;
        
        // Setup escrow
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
        vm.stopPrank();

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );

        vm.stopPrank();
        vm.startPrank(address(paymentEngine));

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        bool success = paymentEngine.HandleJobCompletion(result);
        
        assertTrue(success);
        // Verify mixed fee scenario worked correctly
        assertEq(token.balanceOf(BOB), INITIAL_BALANCE - rpCollateral + basePayment);
        assertEq(token.balanceOf(DAVE), INITIAL_BALANCE + jobCreatorSolverFee); // Only job creator solver fee
        
        // Calculate expected protocol fees (only from module creator fee since network congestion is 0)
        uint256 protocolFees = (moduleCreatorFee * paymentEngine.m())/10000;
        uint256 expectedTreasuryAmount = (protocolFees * paymentEngine.p())/10000;
        uint256 expectedValueBasedRewardsAmount = protocolFees - expectedTreasuryAmount;
        
        assertEq(token.balanceOf(TREASURY), INITIAL_TREASURY_BALANCE + expectedTreasuryAmount);
        assertEq(token.balanceOf(VALUE_REWARDS), INITIAL_VALUE_REWARDS_BALANCE + expectedValueBasedRewardsAmount);
        vm.stopPrank();
    }

    function test_HandleJobCompletion_RevertWhen_InsufficientActiveEscrow() public {
        // Setup fees and costs
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 1 * 10**18;
        uint256 moduleCreatorFee = 1 * 10**18;
        uint256 networkCongestionFee = 1 * 10**18;
        uint256 basePayment = 5 * 10**18;
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
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
        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);

        // Skip the lockup of escrow for job creator and resource provider

        // Test: Insufficient escrow
        vm.startPrank(address(paymentEngine));
        vm.expectRevert(abi.encodeWithSelector(
            LilypadPaymentEngine.LilypadPayment__HandleJobCompletion__InsufficientActiveEscrowToCompleteJob.selector,
            "deal1",
            0, // jobCreatorActiveEscrow
            0, // resourceProviderActiveEscrow
            jobCost,
            rpRequiredEscrow
        ));
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        paymentEngine.HandleJobCompletion(result);
        vm.stopPrank();
    }

    function test_HandleJobFailure() public {
        // Setup initial state
        uint256 basePayment = 5 * 10**18;
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 1 * 10**18;
        uint256 moduleCreatorFee = 1 * 10**18;
        uint256 networkCongestionFee = 1 * 10**18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 20 * 10**18; // Large enough to cover slashing
        
        // Setup escrow for both parties
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow
        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );
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
        bool success = paymentEngine.HandleJobFailure(result);
        assertTrue(success);

        // Verify escrow was slashed for the resource provider
        assertEq(paymentEngine.escrowBalanceOf(BOB), rpCollateral - rpRequiredEscrow);
        assertEq(paymentEngine.totalEscrow(), initialTotalEscrow - rpRequiredEscrow);
        assertEq(paymentEngine.totalActiveEscrow(), initialActiveEscrow - rpRequiredEscrow); // Need to update for the job creator active escorw

        // // Verify job creator's escrow is returned
        // assertEq(paymentEngine.escrowBalanceOf(ALICE), jobCost);
        // assertEq(token.balanceOf(ALICE), INITIAL_BALANCE - jobCost);

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
        vm.expectRevert(abi.encodeWithSignature(
            "LilypadStorage__DealNotFound(string)",
            "nonexistent"
        ));
        paymentEngine.HandleJobFailure(result);
        vm.stopPrank();
    }

    function test_HandleJobFailure_RevertWhen_ResultSaveFails() public {
        // Setup initial state
        uint256 basePayment = 5 * 10**18;
        uint256 jobCreatorSolverFee = 1 * 10**18;
        uint256 resourceProviderSolverFee = 1 * 10**18;
        uint256 moduleCreatorFee = 1 * 10**18;
        uint256 networkCongestionFee = 1 * 10**18;
        uint256 totalFees = jobCreatorSolverFee + moduleCreatorFee + networkCongestionFee;
        uint256 jobCost = basePayment + totalFees;
        uint256 rpCollateral = 20 * 10**18;
        
        // Setup escrow for both parties
        vm.startPrank(ALICE);
        token.approve(address(paymentEngine), jobCost);
        paymentEngine.payEscrow(
            ALICE,
            SharedStructs.PaymentReason.JobFee,
            jobCost
        );
        vm.stopPrank();

        vm.startPrank(BOB);
        token.approve(address(paymentEngine), rpCollateral);
        paymentEngine.payEscrow(
            BOB,
            SharedStructs.PaymentReason.ResourceProviderCollateral,
            rpCollateral
        );
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
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                JobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });
        
        vm.startPrank(address(this));
        lilypadStorage.saveDeal("deal1", deal);

        // Lock escrow
        uint256 rpRequiredEscrow = (basePayment + resourceProviderSolverFee) * (paymentEngine.resourceProviderActiveEscrowScaler() / 10000);
        paymentEngine.initiateLockupOfEscrowForJob(
            ALICE,
            BOB,
            "deal1",
            jobCost,
            rpRequiredEscrow
        );
        vm.stopPrank();

        // Create result with empty resultId which will cause save to fail
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "", // Empty resultId will cause save to fail
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsRejected,
            timestamp: block.timestamp
        });

        // Test job failure with invalid result
        vm.startPrank(address(paymentEngine));
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyResultId.selector);
        paymentEngine.HandleJobFailure(result);
        
        // Verify escrow state hasn't changed
        assertEq(paymentEngine.escrowBalanceOf(BOB), rpCollateral - rpRequiredEscrow);
        assertEq(paymentEngine.activeEscrow(BOB), rpRequiredEscrow);

        // TODO: uncomment once you figure out what happens to the job creator's escrow
        // assertEq(paymentEngine.escrowBalanceOf(ALICE), 0);
        // assertEq(paymentEngine.activeEscrow(ALICE), jobCost);
        vm.stopPrank();
    }

    // Add more complex scenario tests...
} 