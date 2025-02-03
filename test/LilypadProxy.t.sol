// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LilypadProxy.sol";
import "../src/LilypadToken.sol";
import "../src/LilypadStorage.sol";
import "../src/LilypadPaymentEngine.sol";
import "../src/LilypadValidation.sol";
import "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract LilypadProxyTest is Test {
    LilypadProxy public proxy;
    LilypadToken public token;
    LilypadStorage public storage_;
    LilypadPaymentEngine public paymentEngine;
    LilypadValidation public validation;
    LilypadUser public user;

    address public constant ADMIN = address(0x1);
    address public constant JOB_CREATOR = address(0x2);
    address public constant VALIDATOR = address(0x3);
    address public constant RESOURCE_PROVIDER = address(0x4);
    address public constant TREASURY = address(0x5);
    address public constant VALUE_REWARDS = address(0x6);
    address public constant VALIDATION_POOL = address(0x7);

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant INITIAL_USER_BALANCE = 100 * 10 ** 18;

    event LilypadProxy__ControllerRoleGranted(address indexed account, address indexed caller);
    event LilypadProxy__ControllerRoleRevoked(address indexed account, address indexed caller);
    event LilypadProxy__JobCreatorEscrowPayment(address indexed jobCreator, uint256 amount);
    event LilypadProxy__ResourceProviderCollateralPayment(address indexed resourceProvider, uint256 amount);
    event LilypadProxy__ValidationCollateralPayment(address indexed validator, uint256 amount);

    function setUp() public {
        // Deploy implementations
        LilypadStorage storageImpl = new LilypadStorage();
        LilypadUser userImpl = new LilypadUser();
        LilypadPaymentEngine paymentEngineImpl = new LilypadPaymentEngine();
        LilypadValidation validationImpl = new LilypadValidation();
        LilypadProxy proxyImpl = new LilypadProxy();

        // Deploy token
        token = new LilypadToken(INITIAL_SUPPLY);

        //vm.startPrank(ADMIN);

        // Initialize proxies
        ERC1967Proxy storageProxy =
            new ERC1967Proxy(address(storageImpl), abi.encodeWithSelector(LilypadStorage.initialize.selector));
        storage_ = LilypadStorage(address(storageProxy));

        ERC1967Proxy userProxy =
            new ERC1967Proxy(address(userImpl), abi.encodeWithSelector(LilypadUser.initialize.selector));
        user = LilypadUser(address(userProxy));

        ERC1967Proxy paymentEngineProxy = new ERC1967Proxy(
            address(paymentEngineImpl),
            abi.encodeWithSelector(
                LilypadPaymentEngine.initialize.selector,
                address(token),
                address(storage_),
                address(user),
                TREASURY,
                VALUE_REWARDS,
                VALIDATION_POOL
            )
        );
        paymentEngine = LilypadPaymentEngine(address(paymentEngineProxy));

        ERC1967Proxy validationProxy = new ERC1967Proxy(
            address(validationImpl),
            abi.encodeWithSelector(LilypadValidation.initialize.selector, address(storage_), address(user))
        );
        validation = LilypadValidation(address(validationProxy));

        ERC1967Proxy proxyProxy = new ERC1967Proxy(
            address(proxyImpl),
            abi.encodeWithSelector(
                LilypadProxy.initialize.selector,
                address(storage_),
                address(paymentEngine),
                address(validation),
                address(user),
                address(token)
            )
        );
        proxy = LilypadProxy(address(proxyProxy));

        // Grant controller roles
        token.grantRole(SharedStructs.MINTER_ROLE, address(this));
        storage_.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));
        user.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));
        paymentEngine.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));
        validation.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));

        // Set up JOB_CREATOR role
        user.insertUser(JOB_CREATOR, "metadata", "url", SharedStructs.UserType.JobCreator);
        user.insertUser(VALIDATOR, "metadata", "url", SharedStructs.UserType.Validator);
        user.insertUser(RESOURCE_PROVIDER, "metadata", "url", SharedStructs.UserType.ResourceProvider);

        token.mint(JOB_CREATOR, INITIAL_USER_BALANCE);
        token.mint(VALIDATOR, INITIAL_USER_BALANCE);
        token.mint(RESOURCE_PROVIDER, INITIAL_USER_BALANCE);

        //vm.stopPrank();
    }

    function test_InitialState() public {
        assertEq(proxy.version(), "1.0.0");
        assertEq(address(proxy.lilypadStorage()), address(storage_));
        assertEq(address(proxy.paymentEngine()), address(paymentEngine));
        assertEq(address(proxy.lilypadValidation()), address(validation));
        assertEq(address(proxy.lilypadUser()), address(user));
        assertEq(address(proxy.lilypadToken()), address(token));
        assertTrue(proxy.hasRole(bytes32(0x00), address(this))); // Check DEFAULT_ADMIN_ROLE first
        assertTrue(proxy.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
    }

    function test_GetVersion() public {
        assertEq(proxy.getVersion(), "1.0.0");
    }

    function test_GrantControllerRole() public {
        address newController = address(0x123);

        vm.startPrank(address(this));
        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ControllerRoleGranted(newController, address(this));

        proxy.grantControllerRole(newController);
        assertTrue(proxy.hasRole(SharedStructs.CONTROLLER_ROLE, newController));
        vm.stopPrank();
    }

    function test_RevertWhen_NonAdminGrantsControllerRole() public {
        vm.startPrank(JOB_CREATOR);
        vm.expectRevert();
        proxy.grantControllerRole(address(0x123));
        vm.stopPrank();
    }

    function test_RevokeControllerRole() public {
        address controller = address(0x123);

        vm.startPrank(address(this));
        proxy.grantControllerRole(controller);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ControllerRoleRevoked(controller, address(this));

        proxy.revokeControllerRole(controller);
        assertFalse(proxy.hasRole(SharedStructs.CONTROLLER_ROLE, controller));
        vm.stopPrank();
    }

    function test_RevertWhen_RevokingOwnRole() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadProxy.LilypadProxy__CannotRevokeOwnRole.selector);
        proxy.revokeControllerRole(address(this));
        vm.stopPrank();
    }

    function test_SetContracts() public {
        vm.startPrank(address(this));

        address newStorage = address(0x123);
        address newPaymentEngine = address(0x456);
        address newValidation = address(0x789);
        address newUser = address(0xabc);

        assertTrue(proxy.setStorageContract(newStorage));
        assertTrue(proxy.setPaymentEngineContract(newPaymentEngine));
        assertTrue(proxy.setValidationContract(newValidation));
        assertTrue(proxy.setUserContract(newUser));

        assertEq(address(proxy.lilypadStorage()), newStorage);
        assertEq(address(proxy.paymentEngine()), newPaymentEngine);
        assertEq(address(proxy.lilypadValidation()), newValidation);
        assertEq(address(proxy.lilypadUser()), newUser);

        vm.stopPrank();
    }

    function test_AcceptJobPayment() public {
        uint256 amount = 10 * 10 ** 18;

        vm.startPrank(JOB_CREATOR);
        // JOB_CREATOR approves the paymentEngine to receive tokens
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__JobCreatorEscrowPayment(JOB_CREATOR, amount);

        bool success = proxy.acceptJobPayment(amount);
        assertTrue(success);
        assertEq(token.balanceOf(JOB_CREATOR), INITIAL_USER_BALANCE - amount);
        assertEq(paymentEngine.escrowBalanceOf(JOB_CREATOR), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_RevertWhen_NonJobCreatorAcceptsJobPayment() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(VALIDATOR);

        vm.expectRevert(LilypadProxy.LilypadProxy__acceptJobPayment__NotJobCreator.selector);
        proxy.acceptJobPayment(amount);
        vm.stopPrank();
    }

    function test_RevertWhen_ZeroAmountJobPayment() public {
        vm.startPrank(JOB_CREATOR);
        vm.expectRevert(LilypadProxy.LilypadProxy__ZeroAmountNotAllowed.selector);
        proxy.acceptJobPayment(0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotEnoughAllowance() public {
        uint256 amount = 10 * 10 ** 18;
        vm.startPrank(JOB_CREATOR);

        // Try to call acceptJobPayment before approving any tokens
        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptJobPayment(amount);

        // Approve insufficient amount
        token.approve(address(paymentEngine), amount - 1);

        // Should still revert with insufficient allowance
        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptJobPayment(amount);

        vm.stopPrank();
    }

    function testFuzz_AcceptJobPayment(uint256 amount) public {
        // Bound amount to be between 1 and JOB_CREATOR's balance
        amount = bound(amount, 1, INITIAL_USER_BALANCE);

        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__JobCreatorEscrowPayment(JOB_CREATOR, amount);

        bool success = proxy.acceptJobPayment(amount);
        assertTrue(success);

        // Check balances
        assertEq(token.balanceOf(JOB_CREATOR), INITIAL_USER_BALANCE - amount);
        assertEq(paymentEngine.escrowBalanceOf(JOB_CREATOR), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function testFuzz_RevertWhen_InsufficientAllowance(uint256 amount, uint256 allowance) public {
        // Bound amount to be between 1 and JOB_CREATOR's balance
        amount = bound(amount, 1, INITIAL_USER_BALANCE);
        // Bound allowance to be less than amount
        allowance = bound(allowance, 0, amount - 1);

        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), allowance);

        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptJobPayment(amount);
        vm.stopPrank();
    }

    function testFuzz_RevertWhen_InsufficientBalance(uint256 amount) public {
        // Bound amount to be more than JOB_CREATOR's balance
        amount = bound(amount, INITIAL_USER_BALANCE + 1, type(uint256).max);

        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), amount);

        vm.expectRevert(); // Should revert with ERC20 insufficient balance error
        proxy.acceptJobPayment(amount);
        vm.stopPrank();
    }

    function test_AcceptResourceProviderCollateral() public {
        uint256 amount = 10 * 10 ** 18;

        vm.startPrank(RESOURCE_PROVIDER);
        // RESOURCE_PROVIDER approves the paymentEngine to receive tokens
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ResourceProviderCollateralPayment(RESOURCE_PROVIDER, amount);

        bool success = proxy.acceptResourceProviderCollateral(amount);
        assertTrue(success);
        assertEq(token.balanceOf(RESOURCE_PROVIDER), INITIAL_USER_BALANCE - amount);
        assertEq(paymentEngine.escrowBalanceOf(RESOURCE_PROVIDER), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_RevertWhen_NonResourceProviderAcceptsCollateral() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(VALIDATOR);

        vm.expectRevert(LilypadProxy.LilypadProxy__acceptResourceProviderCollateral__NotResourceProvider.selector);
        proxy.acceptResourceProviderCollateral(amount);
        vm.stopPrank();
    }

    function test_RevertWhen_ZeroAmountCollateral() public {
        vm.startPrank(RESOURCE_PROVIDER);
        vm.expectRevert(LilypadProxy.LilypadProxy__ZeroAmountNotAllowed.selector);
        proxy.acceptResourceProviderCollateral(0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotEnoughCollateralAllowance() public {
        uint256 amount = 10 * 10 ** 18;
        vm.startPrank(RESOURCE_PROVIDER);

        // Try to call acceptResourceProviderCollateral before approving any tokens
        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptResourceProviderCollateral(amount);

        // Approve insufficient amount
        token.approve(address(paymentEngine), amount - 1);

        // Should still revert with insufficient allowance
        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptResourceProviderCollateral(amount);

        vm.stopPrank();
    }

    function testFuzz_AcceptResourceProviderCollateral(uint256 amount) public {
        // Bound amount to be between 10 tokens and RESOURCE_PROVIDER's balance
        amount = bound(amount, 10 * 10 ** 18, INITIAL_USER_BALANCE);

        vm.startPrank(RESOURCE_PROVIDER);

        // Get initial balances for assertions
        uint256 initialBalance = token.balanceOf(RESOURCE_PROVIDER);
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));

        // First approve the payment engine to spend tokens
        token.approve(address(paymentEngine), amount);

        // Record expected event
        vm.recordLogs();

        // Make the call
        bool success = proxy.acceptResourceProviderCollateral(amount);
        assertTrue(success);

        // Get and check emitted event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length > 0, true, "No events emitted");

        // The event we care about should be the last one
        Vm.Log memory lastEntry = entries[entries.length - 1];

        // Check event signature
        bytes32 expectedEventSig = keccak256("LilypadProxy__ResourceProviderCollateralPayment(address,uint256)");
        assertEq(lastEntry.topics[0], expectedEventSig, "Wrong event signature");

        // Check indexed parameter (resource provider address)
        assertEq(address(uint160(uint256(lastEntry.topics[1]))), RESOURCE_PROVIDER, "Wrong resource provider in event");

        // Check non-indexed parameter (amount)
        assertEq(abi.decode(lastEntry.data, (uint256)), amount, "Wrong amount in event");

        // Check final balances
        assertEq(token.balanceOf(RESOURCE_PROVIDER), initialBalance - amount, "Wrong final resource provider balance");
        assertEq(paymentEngine.escrowBalanceOf(RESOURCE_PROVIDER), amount, "Wrong escrow balance");
        assertEq(
            token.balanceOf(address(paymentEngine)),
            initialPaymentEngineBalance + amount,
            "Wrong final payment engine balance"
        );

        vm.stopPrank();
    }

    function testFuzz_RevertWhen_InsufficientCollateralAllowance(uint256 amount, uint256 allowance) public {
        // Bound amount to be between 1 and RESOURCE_PROVIDER's balance
        amount = bound(amount, 1, INITIAL_USER_BALANCE);
        // Bound allowance to be less than amount
        allowance = bound(allowance, 0, amount - 1);

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), allowance);

        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptResourceProviderCollateral(amount);
        vm.stopPrank();
    }

    function testFuzz_RevertWhen_InsufficientCollateralBalance(uint256 amount) public {
        // Bound amount to be more than RESOURCE_PROVIDER's balance
        amount = bound(amount, INITIAL_USER_BALANCE + 1, type(uint256).max);

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), amount);

        vm.expectRevert(); // Should revert with ERC20 insufficient balance error
        proxy.acceptResourceProviderCollateral(amount);
        vm.stopPrank();
    }

    function testFuzz_RevertWhen_CollateralAmountTooLow(uint256 amount) public {
        // Bound amount to be between 1 wei and just under 10 tokens
        amount = bound(amount, 1, 10 * 10 ** 18 - 1);

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), amount);

        vm.expectRevert(
            LilypadPaymentEngine.LilypadPayment__minimumResourceProviderAndValidatorDepositAmountNotMet.selector
        );
        proxy.acceptResourceProviderCollateral(amount);
        vm.stopPrank();
    }

    function test_AcceptValidationCollateral() public {
        uint256 amount = 10 * 10 ** 18;

        vm.startPrank(VALIDATOR);
        // VALIDATOR approves the paymentEngine to receive tokens
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ValidationCollateralPayment(VALIDATOR, amount);

        bool success = proxy.acceptValidationCollateral(amount);
        assertTrue(success);
        assertEq(token.balanceOf(VALIDATOR), INITIAL_USER_BALANCE - amount);
        assertEq(paymentEngine.escrowBalanceOf(VALIDATOR), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_RevertWhen_NonValidatorAcceptsCollateral() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(JOB_CREATOR);

        vm.expectRevert(LilypadProxy.LilypadProxy__acceptValidationCollateral__NotValidator.selector);
        proxy.acceptValidationCollateral(amount);
        vm.stopPrank();
    }

    function test_RevertWhen_ZeroAmountValidationCollateral() public {
        vm.startPrank(VALIDATOR);
        vm.expectRevert(LilypadProxy.LilypadProxy__ZeroAmountNotAllowed.selector);
        proxy.acceptValidationCollateral(0);
        vm.stopPrank();
    }

    function test_RevertWhen_NotEnoughValidationCollateralAllowance() public {
        uint256 amount = 10 * 10 ** 18;
        vm.startPrank(VALIDATOR);

        // Try to call acceptValidationCollateral before approving any tokens
        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptValidationCollateral(amount);

        // Approve insufficient amount
        token.approve(address(paymentEngine), amount - 1);

        // Should still revert with insufficient allowance
        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptValidationCollateral(amount);

        vm.stopPrank();
    }

    function testFuzz_AcceptValidationCollateral(uint256 amount) public {
        // Bound amount to be between 10 tokens and VALIDATOR's balance
        amount = bound(amount, 10 * 10 ** 18, INITIAL_USER_BALANCE);

        vm.startPrank(VALIDATOR);

        // Get initial balances for assertions
        uint256 initialBalance = token.balanceOf(VALIDATOR);
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));

        // First approve the payment engine to spend tokens
        token.approve(address(paymentEngine), amount);

        // Record expected event
        vm.recordLogs();

        // Make the call
        bool success = proxy.acceptValidationCollateral(amount);
        assertTrue(success);

        // Get and check emitted event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length > 0, true, "No events emitted");

        // The event we care about should be the last one
        Vm.Log memory lastEntry = entries[entries.length - 1];

        // Check event signature
        bytes32 expectedEventSig = keccak256("LilypadProxy__ValidationCollateralPayment(address,uint256)");
        assertEq(lastEntry.topics[0], expectedEventSig, "Wrong event signature");

        // Check indexed parameter (validator address)
        assertEq(address(uint160(uint256(lastEntry.topics[1]))), VALIDATOR, "Wrong validator in event");

        // Check non-indexed parameter (amount)
        assertEq(abi.decode(lastEntry.data, (uint256)), amount, "Wrong amount in event");

        // Check final balances
        assertEq(token.balanceOf(VALIDATOR), initialBalance - amount, "Wrong final validator balance");
        assertEq(paymentEngine.escrowBalanceOf(VALIDATOR), amount, "Wrong escrow balance");
        assertEq(
            token.balanceOf(address(paymentEngine)),
            initialPaymentEngineBalance + amount,
            "Wrong final payment engine balance"
        );

        vm.stopPrank();
    }

    function testFuzz_RevertWhen_InsufficientValidationCollateralAllowance(uint256 amount, uint256 allowance) public {
        // Bound amount to be between 1 and VALIDATOR's balance
        amount = bound(amount, 1, INITIAL_USER_BALANCE);
        // Bound allowance to be less than amount
        allowance = bound(allowance, 0, amount - 1);

        vm.startPrank(VALIDATOR);
        token.approve(address(paymentEngine), allowance);

        vm.expectRevert(LilypadProxy.LilypadProxy__NotEnoughAllowance.selector);
        proxy.acceptValidationCollateral(amount);
        vm.stopPrank();
    }

    function testFuzz_RevertWhen_InsufficientValidationCollateralBalance(uint256 amount) public {
        // Bound amount to be more than VALIDATOR's balance
        amount = bound(amount, INITIAL_USER_BALANCE + 1, type(uint256).max);

        vm.startPrank(VALIDATOR);
        token.approve(address(paymentEngine), amount);

        vm.expectRevert(); // Should revert with ERC20 insufficient balance error
        proxy.acceptValidationCollateral(amount);
        vm.stopPrank();
    }

    function testFuzz_RevertWhen_ValidationCollateralAmountTooLow(uint256 amount) public {
        // Bound amount to be between 1 wei and just under 10 tokens
        amount = bound(amount, 1, 10 * 10 ** 18 - 1);

        vm.startPrank(VALIDATOR);
        token.approve(address(paymentEngine), amount);

        vm.expectRevert(
            LilypadPaymentEngine.LilypadPayment__minimumResourceProviderAndValidatorDepositAmountNotMet.selector
        );
        proxy.acceptValidationCollateral(amount);
        vm.stopPrank();
    }

    function test_SetDeal() public {
        uint256 jobCreatorAmount = 9 * 10 ** 18; // Total cost from JC perspective
        uint256 rpAmount = 20 * 10 ** 18; // More than required collateral

        SharedStructs.DealPaymentStructure memory paymentStructure = SharedStructs.DealPaymentStructure({
            jobCreatorSolverFee: 1 * 10 ** 18,
            resourceProviderSolverFee: 1 * 10 ** 18,
            networkCongestionFee: 1 * 10 ** 18,
            moduleCreatorFee: 1 * 10 ** 18,
            priceOfJobWithoutFees: 5 * 10 ** 18
        });

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "test-deal-1",
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: paymentStructure
        });

        // Setup escrow balances
        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), jobCreatorAmount);
        proxy.acceptJobPayment(jobCreatorAmount);
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), rpAmount);
        proxy.acceptResourceProviderCollateral(rpAmount);
        vm.stopPrank();

        vm.startPrank(address(this));
        bool success = proxy.setDeal(deal);
        assertTrue(success);

        // Verify deal was saved
        SharedStructs.Deal memory savedDeal = proxy.getDeal("test-deal-1");
        assertEq(savedDeal.dealId, deal.dealId);
        assertEq(savedDeal.jobCreator, deal.jobCreator);
        assertEq(savedDeal.resourceProvider, deal.resourceProvider);

        uint256 jobCreatorCost = deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.jobCreatorSolverFee
            + deal.paymentStructure.networkCongestionFee + deal.paymentStructure.moduleCreatorFee;
        uint256 resourceProviderCost =
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee;

        // Verify escrow balances
        assertEq(paymentEngine.escrowBalanceOf(JOB_CREATOR), jobCreatorAmount - jobCreatorCost);
        assertEq(paymentEngine.escrowBalanceOf(RESOURCE_PROVIDER), rpAmount - resourceProviderCost);
        assertEq(paymentEngine.activeEscrowBalanceOf(JOB_CREATOR), jobCreatorCost);
        assertEq(paymentEngine.activeEscrowBalanceOf(RESOURCE_PROVIDER), resourceProviderCost);
        assertEq(paymentEngine.totalActiveEscrow(), jobCreatorCost + resourceProviderCost);
        vm.stopPrank();
    }

    function test_RevertWhen_NonControllerSetsDeal() public {
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "test-deal-1",
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        vm.startPrank(JOB_CREATOR);
        vm.expectRevert();
        proxy.setDeal(deal);
        vm.stopPrank();
    }

    function test_RevertWhen_InsufficientJobCreatorBalance() public {
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "test-deal-1",
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        // fund resource provider's escrow but not job creator's
        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), 10 * 10 ** 18);
        proxy.acceptResourceProviderCollateral(10 * 10 ** 18);
        vm.stopPrank();

        uint256 jobCreatorCost = deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.jobCreatorSolverFee
            + deal.paymentStructure.networkCongestionFee + deal.paymentStructure.moduleCreatorFee;

        vm.startPrank(address(this));
        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadPaymentEngine.LilypadPayment__insufficientEscrowAmount.selector, 0, jobCreatorCost
            )
        );
        proxy.setDeal(deal);
        vm.stopPrank();
    }

    function test_RevertWhen_InsufficientResourceProviderBalance() public {
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "test-deal-1",
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        // fund the job creator's escrow but not the resource provider's
        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), 10 * 10 ** 18);
        proxy.acceptJobPayment(10 * 10 ** 18);
        vm.stopPrank();

        uint256 resourceProviderCost =
            deal.paymentStructure.priceOfJobWithoutFees + deal.paymentStructure.resourceProviderSolverFee;

        vm.startPrank(address(this));
        vm.expectRevert(
            abi.encodeWithSelector(
                LilypadPaymentEngine.LilypadPayment__insufficientEscrowAmount.selector, 0, resourceProviderCost
            )
        );
        proxy.setDeal(deal);
        vm.stopPrank();
    }

    function test_RevertWhen_DealFailsToSave() public {
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "", // Empty deal ID should cause save to fail
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        // Setup escrow balances to ensure the test fails due to deal save, not escrow
        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), 10 * 10 ** 18);
        proxy.acceptJobPayment(10 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), 10 * 10 ** 18);
        proxy.acceptResourceProviderCollateral(10 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(address(this));
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyDealId.selector);
        proxy.setDeal(deal);
        vm.stopPrank();
    }

    function test_GetResult() public {
        // First create and save a deal
        string memory dealId = "test-deal-1";
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        // Save the deal first
        vm.startPrank(address(this));
        storage_.saveDeal(dealId, deal);

        // Create and save a result
        string memory resultId = "result-1";
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        storage_.saveResult(resultId, result);
        vm.stopPrank();

        // Test getting result as job creator
        vm.startPrank(JOB_CREATOR);
        SharedStructs.Result memory retrievedResult = proxy.getResult(resultId);
        assertEq(retrievedResult.resultId, resultId);
        assertEq(retrievedResult.dealId, dealId);
        assertEq(retrievedResult.resultCID, "resultCID1");
        assertEq(uint8(retrievedResult.status), uint8(SharedStructs.ResultStatusEnum.ResultsAccepted));
        vm.stopPrank();
    }

    function test_RevertWhen_GettingResultWithEmptyId() public {
        vm.startPrank(JOB_CREATOR);
        vm.expectRevert(LilypadProxy.LilypadProxy__EmptyResultId.selector);
        proxy.getResult("");
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedUserGetsResult() public {
        // First create and save a deal
        string memory dealId = "test-deal-1";
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        // Save the deal first
        vm.startPrank(address(this));
        storage_.saveDeal(dealId, deal);

        // Create and save a result
        string memory resultId = "result-1";
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        storage_.saveResult(resultId, result);
        vm.stopPrank();

        // Try to get result as resource provider (unauthorized)
        vm.startPrank(RESOURCE_PROVIDER);
        vm.expectRevert(LilypadProxy.LilypadProxy__NotAuthorizedToGetResult.selector);
        proxy.getResult(resultId);
        vm.stopPrank();
    }

    function testFuzz_GetResult(string memory resultId, string memory dealId, string memory resultCID, uint8 status)
        public
    {
        vm.assume(bytes(resultId).length > 0);
        vm.assume(bytes(dealId).length > 0);
        vm.assume(bytes(resultCID).length > 0);  // Add this check to prevent empty CID
        vm.assume(status < 2); // Number of enum values in ResultStatusEnum

        // Create and save deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: JOB_CREATOR,
            resourceProvider: RESOURCE_PROVIDER,
            moduleCreator: address(0x123),
            solver: address(0x456),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 1 * 10 ** 18,
                resourceProviderSolverFee: 1 * 10 ** 18,
                networkCongestionFee: 1 * 10 ** 18,
                moduleCreatorFee: 1 * 10 ** 18,
                priceOfJobWithoutFees: 5 * 10 ** 18
            })
        });

        // Save the deal and result
        vm.startPrank(address(this));
        storage_.saveDeal(dealId, deal);

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: resultCID,
            status: SharedStructs.ResultStatusEnum(status),
            timestamp: block.timestamp
        });
        storage_.saveResult(resultId, result);
        vm.stopPrank();

        // Test retrieval
        vm.startPrank(JOB_CREATOR);
        SharedStructs.Result memory retrievedResult = proxy.getResult(resultId);
        assertEq(retrievedResult.resultId, resultId);
        assertEq(retrievedResult.dealId, dealId);
        assertEq(retrievedResult.resultCID, resultCID);
        assertEq(uint8(retrievedResult.status), status);
        vm.stopPrank();
    }
}
