// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LilypadProxy} from "../src/LilypadProxy.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {LilypadStorage} from "../src/LilypadStorage.sol";
import {LilypadPaymentEngine} from "../src/LilypadPaymentEngine.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {LilypadTokenomics} from "../src/LilypadTokenomics.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract LilypadProxyTest is Test {
    LilypadProxy public proxy;
    LilypadToken public token;
    LilypadStorage public storage_;
    LilypadPaymentEngine public paymentEngine;
    LilypadUser public user;
    LilypadTokenomics public tokenomics;
    address public constant ADMIN = address(0x1);
    address public constant JOB_CREATOR = address(0x2);
    address public constant RESOURCE_PROVIDER = address(0x4);
    address public constant TREASURY = address(0x5);
    address public constant VALUE_REWARDS = address(0x6);
    address public constant VALIDATION_POOL = address(0x7);
    address public constant NEW_USER = address(0x8);
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant INITIAL_USER_BALANCE = 100 * 10 ** 18;

    event LilypadProxy__ControllerRoleGranted(address indexed account, address indexed caller);
    event LilypadProxy__ControllerRoleRevoked(address indexed account, address indexed caller);
    event LilypadProxy__JobCreatorEscrowPayment(address indexed jobCreator, uint256 amount);
    event LilypadProxy__ResourceProviderCollateralPayment(address indexed resourceProvider, uint256 amount);
    event LilypadProxy__JobCreatorInserted(address indexed jobCreator);
    event LilypadProxy__ResourceProviderInserted(address indexed resourceProvider);

    function setUp() public {
        // Deploy implementations
        LilypadStorage storageImpl = new LilypadStorage();
        LilypadUser userImpl = new LilypadUser();
        LilypadTokenomics tokenomicsImpl = new LilypadTokenomics();
        LilypadPaymentEngine paymentEngineImpl = new LilypadPaymentEngine();
        LilypadProxy proxyImpl = new LilypadProxy();

        // Deploy token
        token = new LilypadToken(INITIAL_SUPPLY);

        // Initialize proxies
        ERC1967Proxy storageProxy =
            new ERC1967Proxy(address(storageImpl), abi.encodeWithSelector(LilypadStorage.initialize.selector));
        storage_ = LilypadStorage(address(storageProxy));

        ERC1967Proxy userProxy =
            new ERC1967Proxy(address(userImpl), abi.encodeWithSelector(LilypadUser.initialize.selector));
        user = LilypadUser(address(userProxy));

        ERC1967Proxy tokenomicsProxy =
            new ERC1967Proxy(address(tokenomicsImpl), abi.encodeWithSelector(LilypadTokenomics.initialize.selector));
        tokenomics = LilypadTokenomics(address(tokenomicsProxy));

        ERC1967Proxy paymentEngineProxy = new ERC1967Proxy(
            address(paymentEngineImpl),
            abi.encodeWithSelector(
                LilypadPaymentEngine.initialize.selector,
                address(token),
                address(storage_),
                address(user),
                address(tokenomics),
                TREASURY,
                VALUE_REWARDS,
                VALIDATION_POOL
            )
        );
        paymentEngine = LilypadPaymentEngine(address(paymentEngineProxy));

        ERC1967Proxy proxyProxy = new ERC1967Proxy(
            address(proxyImpl),
            abi.encodeWithSelector(
                LilypadProxy.initialize.selector,
                address(storage_),
                address(paymentEngine),
                address(user),
                address(token)
            )
        );
        proxy = LilypadProxy(address(proxyProxy));

        // Grant roles to proxy
        storage_.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));
        user.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));
        paymentEngine.grantRole(SharedStructs.CONTROLLER_ROLE, address(proxy));

        // Grant roles to payment engine
        storage_.grantRole(SharedStructs.CONTROLLER_ROLE, address(paymentEngine));

        // Set up JOB_CREATOR role
        user.insertUser(JOB_CREATOR, "metadata", "url", SharedStructs.UserType.JobCreator);
        user.insertUser(RESOURCE_PROVIDER, "metadata", "url", SharedStructs.UserType.ResourceProvider);

        token.mint(JOB_CREATOR, INITIAL_USER_BALANCE);
        token.mint(RESOURCE_PROVIDER, INITIAL_USER_BALANCE);
        token.mint(NEW_USER, INITIAL_USER_BALANCE);
    }

    function test_InitialState() public {
        assertEq(proxy.version(), "1.0.0");
        assertEq(proxy.getStorageAddress(), address(storage_));
        assertEq(proxy.getPaymentEngineAddress(), address(paymentEngine));
        assertEq(proxy.getUserAddress(), address(user));
        assertEq(proxy.getl2LilypadTokenAddress(), address(token));
        assertTrue(proxy.hasRole(bytes32(0x00), address(this))); // Check DEFAULT_ADMIN_ROLE first
        assertTrue(proxy.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
        assertTrue(storage_.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
        assertTrue(storage_.hasRole(bytes32(0x00), address(this)));
        assertTrue(paymentEngine.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
        assertTrue(paymentEngine.hasRole(bytes32(0x00), address(this)));
        assertTrue(user.hasRole(SharedStructs.CONTROLLER_ROLE, address(this)));
        assertTrue(user.hasRole(bytes32(0x00), address(this)));
        assertTrue(token.hasRole(SharedStructs.MINTER_ROLE, address(this)));
        assertTrue(token.hasRole(bytes32(0x00), address(this)));
    }

    function test_GetVersion() public {
        assertEq(proxy.getVersion(), "1.0.0");
    }

    function test_GrantControllerRole() public {
        address newController = address(0x123);

        vm.startPrank(address(this));
        vm.expectEmit(true, true, true, true);
        emit IAccessControl.RoleGranted(SharedStructs.CONTROLLER_ROLE, newController, address(this));

        proxy.grantRole(SharedStructs.CONTROLLER_ROLE, newController);
        assertTrue(proxy.hasRole(SharedStructs.CONTROLLER_ROLE, newController));
        vm.stopPrank();
    }

    function test_RevertWhen_NonAdminGrantsControllerRole() public {
        vm.startPrank(JOB_CREATOR);
        vm.expectRevert();
        proxy.grantRole(SharedStructs.CONTROLLER_ROLE, address(0x123));
        vm.stopPrank();
    }

    function test_RevokeControllerRole() public {
        address controller = address(0x123);

        vm.startPrank(address(this));
        proxy.grantRole(SharedStructs.CONTROLLER_ROLE, controller);

        vm.expectEmit(true, true, true, true);
        emit IAccessControl.RoleRevoked(SharedStructs.CONTROLLER_ROLE, controller, address(this));

        proxy.revokeRole(SharedStructs.CONTROLLER_ROLE, controller);
        assertFalse(proxy.hasRole(SharedStructs.CONTROLLER_ROLE, controller));
        vm.stopPrank();
    }

    function test_SetContracts() public {
        vm.startPrank(address(this));

        address newStorage = address(0x123);
        address newPaymentEngine = address(0x456);
        address newUser = address(0xabc);
        address newL2LilypadToken = address(0xdef);

        assertTrue(proxy.setStorageContract(newStorage));
        assertTrue(proxy.setPaymentEngineContract(newPaymentEngine));
        assertTrue(proxy.setUserContract(newUser));
        assertTrue(proxy.setL2LilypadTokenContract(newL2LilypadToken));

        assertEq(proxy.getStorageAddress(), newStorage);
        assertEq(proxy.getPaymentEngineAddress(), newPaymentEngine);
        assertEq(proxy.getUserAddress(), newUser);
        assertEq(proxy.getl2LilypadTokenAddress(), newL2LilypadToken);

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
        assertEq(paymentEngine.escrowBalances(JOB_CREATOR), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_AcceptJobPaymentWhenUserDoesNotExist() public {
        uint256 amount = 10 * 10 ** 18;

        vm.startPrank(NEW_USER);
        // JOB_CREATOR approves the paymentEngine to receive tokens
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__JobCreatorInserted(NEW_USER);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__JobCreatorEscrowPayment(NEW_USER, amount);

        bool success = proxy.acceptJobPayment(amount);

        assertTrue(success);
        assertEq(user.hasRole(NEW_USER, SharedStructs.UserType.JobCreator), true);
        assertEq(token.balanceOf(NEW_USER), INITIAL_USER_BALANCE - amount);
        assertEq(paymentEngine.escrowBalances(NEW_USER), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_RevertWhen_NonJobCreatorAcceptsJobPayment() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), amount);

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
        assertEq(paymentEngine.escrowBalances(JOB_CREATOR), amount);
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

    function test_AcceptJobPaymentWithMaxUint256() public {
        // Get the token's initial supply (from deployment it's 167_500_000 * 10 ** 18)
        uint256 initialSupply = 167_500_000 * 10 ** 18;

        // First clear any existing balance from the payment engine
        vm.startPrank(address(this));
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));
        if (initialPaymentEngineBalance > 0) {
            token.burn(initialPaymentEngineBalance);
        }
        vm.stopPrank();

        vm.startPrank(JOB_CREATOR);
        // Clear job creator's balance
        uint256 initialBalance = token.balanceOf(JOB_CREATOR);
        if (initialBalance > 0) {
            token.burn(initialBalance);
        }
        vm.stopPrank();

        vm.startPrank(address(this));
        // Now mint exactly the initial supply
        token.mint(JOB_CREATOR, initialSupply);
        vm.stopPrank();

        vm.startPrank(JOB_CREATOR);

        // Verify initial balance matches initial supply exactly
        assertEq(token.balanceOf(JOB_CREATOR), initialSupply, "Initial balance should match initial supply");

        // Approve payment engine to spend tokens
        token.approve(address(paymentEngine), initialSupply);

        // Expect the job payment event
        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__JobCreatorEscrowPayment(JOB_CREATOR, initialSupply);

        // Attempt the payment
        bool success = proxy.acceptJobPayment(initialSupply);
        assertTrue(success);

        // Verify final balances
        assertEq(token.balanceOf(JOB_CREATOR), 0, "Job creator should have 0 balance");
        assertEq(
            token.balanceOf(address(paymentEngine)), initialSupply, "Payment engine should have exactly initial supply"
        );
        assertEq(
            paymentEngine.escrowBalances(JOB_CREATOR), initialSupply, "Escrow balance should be exactly initial supply"
        );

        vm.stopPrank();
    }

    function test_RevertWhen_AcceptJobPaymentExceedsBalance() public {
        uint256 maxAmount = type(uint256).max;
        uint256 actualBalance = 1000 * 10 ** 18; // Some smaller amount

        // First clear any existing balances
        vm.startPrank(address(this));
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));
        if (initialPaymentEngineBalance > 0) {
            token.burn(initialPaymentEngineBalance);
        }
        vm.stopPrank();

        vm.startPrank(JOB_CREATOR);
        uint256 initialBalance = token.balanceOf(JOB_CREATOR);
        if (initialBalance > 0) {
            token.burn(initialBalance);
        }
        vm.stopPrank();

        // Mint a limited amount of tokens
        vm.startPrank(address(this));
        token.mint(JOB_CREATOR, actualBalance);
        vm.stopPrank();

        vm.startPrank(JOB_CREATOR);
        // Approve spending of max amount (even though we don't have it)
        token.approve(address(paymentEngine), maxAmount);

        // Expect revert with ERC20InsufficientBalance error
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")),
                JOB_CREATOR,
                actualBalance,
                maxAmount
            )
        );
        proxy.acceptJobPayment(maxAmount);
        vm.stopPrank();
    }

    function test_AcceptJobPaymentWithMaxAllowedAmount() public {
        // Get the token's initial supply (from deployment it's 167_500_000 * 10 ** 18)
        uint256 initialSupply = 167_500_000 * 10 ** 18;

        // First clear any existing balance from the payment engine
        vm.startPrank(address(this));
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));
        if (initialPaymentEngineBalance > 0) {
            token.burn(initialPaymentEngineBalance);
        }
        vm.stopPrank();

        vm.startPrank(JOB_CREATOR);
        // Clear job creator's balance
        uint256 initialBalance = token.balanceOf(JOB_CREATOR);
        if (initialBalance > 0) {
            token.burn(initialBalance);
        }
        vm.stopPrank();

        vm.startPrank(address(this));
        // Now mint exactly the initial supply
        token.mint(JOB_CREATOR, initialSupply);
        vm.stopPrank();

        vm.startPrank(JOB_CREATOR);

        // Verify initial balance matches initial supply exactly
        assertEq(token.balanceOf(JOB_CREATOR), initialSupply, "Initial balance should match max supply");

        // Approve payment engine to spend tokens
        token.approve(address(paymentEngine), initialSupply);

        // Expect the job payment event
        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__JobCreatorEscrowPayment(JOB_CREATOR, initialSupply);

        // Attempt the payment
        bool success = proxy.acceptJobPayment(initialSupply);
        assertTrue(success);

        // Verify final balances
        assertEq(token.balanceOf(JOB_CREATOR), 0, "Job creator should have 0 balance");
        assertEq(
            token.balanceOf(address(paymentEngine)), initialSupply, "Payment engine should have exactly initial supply"
        );
        assertEq(
            paymentEngine.escrowBalances(JOB_CREATOR), initialSupply, "Escrow balance should be exactly initial supply"
        );

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
        assertEq(paymentEngine.escrowBalances(RESOURCE_PROVIDER), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_AcceptResourceProviderCollateralWhenUserDoesNotExist() public {
        uint256 amount = 10 * 10 ** 18;

        vm.startPrank(NEW_USER);
        // RESOURCE_PROVIDER approves the paymentEngine to receive tokens
        token.approve(address(paymentEngine), amount);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ResourceProviderInserted(NEW_USER);

        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ResourceProviderCollateralPayment(NEW_USER, amount);

        bool success = proxy.acceptResourceProviderCollateral(amount);

        assertTrue(success);
        assertEq(user.hasRole(NEW_USER, SharedStructs.UserType.ResourceProvider), true);
        assertEq(token.balanceOf(NEW_USER), INITIAL_USER_BALANCE - amount);
        assertEq(paymentEngine.escrowBalances(NEW_USER), amount);
        assertEq(token.balanceOf(address(paymentEngine)), amount);
        vm.stopPrank();
    }

    function test_RevertWhen_NonResourceProviderAcceptsCollateral() public {
        uint256 amount = 100 * 10 ** 18;

        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), amount);

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
        assertEq(paymentEngine.escrowBalances(RESOURCE_PROVIDER), amount, "Wrong escrow balance");
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

    function test_AcceptResourceProviderCollateralWithMaxUint256() public {
        // Get the token's initial supply (from deployment it's 167_500_000 * 10 ** 18)
        uint256 initialSupply = 167_500_000 * 10 ** 18;

        // First clear any existing balance from the payment engine
        vm.startPrank(address(this));
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));
        if (initialPaymentEngineBalance > 0) {
            token.burn(initialPaymentEngineBalance);
        }
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        // Clear job creator's balance
        uint256 initialBalance = token.balanceOf(RESOURCE_PROVIDER);
        if (initialBalance > 0) {
            token.burn(initialBalance);
        }
        vm.stopPrank();

        vm.startPrank(address(this));
        // Now mint exactly the initial supply
        token.mint(RESOURCE_PROVIDER, initialSupply);
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);

        // Verify initial balance matches initial supply exactly
        assertEq(token.balanceOf(RESOURCE_PROVIDER), initialSupply, "Initial balance should match initial supply");

        // Approve payment engine to spend tokens
        token.approve(address(paymentEngine), initialSupply);

        // Expect the job payment event
        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ResourceProviderCollateralPayment(RESOURCE_PROVIDER, initialSupply);

        // Attempt the payment
        bool success = proxy.acceptResourceProviderCollateral(initialSupply);
        assertTrue(success);

        // Verify final balances
        assertEq(token.balanceOf(RESOURCE_PROVIDER), 0, "Resource provider should have 0 balance");
        assertEq(
            token.balanceOf(address(paymentEngine)), initialSupply, "Payment engine should have exactly initial supply"
        );
        assertEq(
            paymentEngine.escrowBalances(RESOURCE_PROVIDER),
            initialSupply,
            "Escrow balance should be exactly initial supply"
        );

        vm.stopPrank();
    }

    function test_RevertWhen_AcceptResourceProviderCollateralExceedsBalance() public {
        uint256 maxAmount = type(uint256).max;
        uint256 actualBalance = 1000 * 10 ** 18; // Some smaller amount

        // First clear any existing balances
        vm.startPrank(address(this));
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));
        if (initialPaymentEngineBalance > 0) {
            token.burn(initialPaymentEngineBalance);
        }
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        uint256 initialBalance = token.balanceOf(RESOURCE_PROVIDER);
        if (initialBalance > 0) {
            token.burn(initialBalance);
        }
        vm.stopPrank();

        // Mint a limited amount of tokens
        vm.startPrank(address(this));
        token.mint(RESOURCE_PROVIDER, actualBalance);
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        // Approve spending of max amount (even though we don't have it)
        token.approve(address(paymentEngine), maxAmount);

        // Expect revert with ERC20InsufficientBalance error
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")),
                RESOURCE_PROVIDER,
                actualBalance,
                maxAmount
            )
        );
        proxy.acceptResourceProviderCollateral(maxAmount);
        vm.stopPrank();
    }

    function test_AcceptResourceProviderCollateralWithMaxAllowedAmount() public {
        // Get the token's initial supply (from deployment it's 167_500_000 * 10 ** 18)
        uint256 initialSupply = 167_500_000 * 10 ** 18;

        // First clear any existing balance from the payment engine
        vm.startPrank(address(this));
        uint256 initialPaymentEngineBalance = token.balanceOf(address(paymentEngine));
        if (initialPaymentEngineBalance > 0) {
            token.burn(initialPaymentEngineBalance);
        }
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        // Clear job creator's balance
        uint256 initialBalance = token.balanceOf(RESOURCE_PROVIDER);
        if (initialBalance > 0) {
            token.burn(initialBalance);
        }
        vm.stopPrank();

        vm.startPrank(address(this));
        // Now mint exactly the initial supply
        token.mint(RESOURCE_PROVIDER, initialSupply);
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);

        // Verify initial balance matches initial supply exactly
        assertEq(token.balanceOf(RESOURCE_PROVIDER), initialSupply, "Initial balance should match max supply");

        // Approve payment engine to spend tokens
        token.approve(address(paymentEngine), initialSupply);

        // Expect the job payment event
        vm.expectEmit(true, true, true, true);
        emit LilypadProxy__ResourceProviderCollateralPayment(RESOURCE_PROVIDER, initialSupply);

        // Attempt the payment
        bool success = proxy.acceptResourceProviderCollateral(initialSupply);
        assertTrue(success);

        // Verify final balances
        assertEq(token.balanceOf(RESOURCE_PROVIDER), 0, "Resource provider should have 0 balance");
        assertEq(
            token.balanceOf(address(paymentEngine)), initialSupply, "Payment engine should have exactly initial supply"
        );
        assertEq(
            paymentEngine.escrowBalances(RESOURCE_PROVIDER),
            initialSupply,
            "Escrow balance should be exactly initial supply"
        );

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
        assertEq(paymentEngine.escrowBalances(JOB_CREATOR), jobCreatorAmount - jobCreatorCost);
        assertEq(paymentEngine.escrowBalances(RESOURCE_PROVIDER), rpAmount - resourceProviderCost);
        assertEq(paymentEngine.activeEscrow(JOB_CREATOR), jobCreatorCost);
        assertEq(paymentEngine.activeEscrow(RESOURCE_PROVIDER), resourceProviderCost);
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
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyResultId.selector);
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
        vm.assume(bytes(resultCID).length > 0); // Add this check to prevent empty CID
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

    function test_SetResult_Calling_HanleJobCompletion() public {
        string memory dealId = "test-deal-1";
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;

        uint256 totalCost = basePayment + jobCreatorSolverFee + networkCongestionFee + moduleCreatorFee;
        uint256 rpCollateral = paymentEngine.MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT();

        // Setup escrow
        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), totalCost);

        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), rpCollateral);
        vm.stopPrank();

        vm.startPrank(address(proxy));
        paymentEngine.payEscrow(JOB_CREATOR, SharedStructs.PaymentReason.JobFee, totalCost);
        paymentEngine.payEscrow(RESOURCE_PROVIDER, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        vm.prank(address(proxy));
        paymentEngine.initiateLockupOfEscrowForJob(JOB_CREATOR, RESOURCE_PROVIDER, dealId, totalCost, rpCollateral);

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
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        storage_.saveDeal(dealId, deal);

        // Create and set result
        string memory resultId = "result-1";
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        bool success = proxy.setResult(result);
        assertTrue(success);

        // Verify result and balances
        SharedStructs.Result memory savedResult = storage_.getResult(resultId);
        assertEq(savedResult.resultId, resultId);
        assertEq(savedResult.dealId, dealId);
        assertEq(savedResult.resultCID, "resultCID1");
        assertEq(uint8(savedResult.status), uint8(SharedStructs.ResultStatusEnum.ResultsAccepted));

        vm.stopPrank();
    }

    function test_SetResult_Calling_HandleJobFailed() public {
        string memory dealId = "test-deal-1";
        uint256 basePayment = 5 * 10 ** 18;
        uint256 jobCreatorSolverFee = 1 * 10 ** 18;
        uint256 resourceProviderSolverFee = 1 * 10 ** 18;
        uint256 networkCongestionFee = 1 * 10 ** 18;
        uint256 moduleCreatorFee = 1 * 10 ** 18;

        uint256 totalCost = basePayment + jobCreatorSolverFee + networkCongestionFee + moduleCreatorFee;
        uint256 rpCollateral = paymentEngine.MIN_RESOURCE_PROVIDER_DEPOSIT_AMOUNT();

        // Setup escrow
        vm.startPrank(JOB_CREATOR);
        token.approve(address(paymentEngine), totalCost);
        vm.stopPrank();

        vm.startPrank(RESOURCE_PROVIDER);
        token.approve(address(paymentEngine), rpCollateral);
        vm.stopPrank();

        vm.startPrank(address(proxy));
        paymentEngine.payEscrow(JOB_CREATOR, SharedStructs.PaymentReason.JobFee, totalCost);
        paymentEngine.payEscrow(RESOURCE_PROVIDER, SharedStructs.PaymentReason.ResourceProviderCollateral, rpCollateral);
        vm.stopPrank();

        vm.prank(address(proxy));
        paymentEngine.initiateLockupOfEscrowForJob(JOB_CREATOR, RESOURCE_PROVIDER, dealId, totalCost, rpCollateral);

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
                jobCreatorSolverFee: jobCreatorSolverFee,
                resourceProviderSolverFee: resourceProviderSolverFee,
                networkCongestionFee: networkCongestionFee,
                moduleCreatorFee: moduleCreatorFee,
                priceOfJobWithoutFees: basePayment
            })
        });

        vm.startPrank(address(this));
        storage_.saveDeal(dealId, deal);

        // Create and set result
        string memory resultId = "result-1";
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsRejected,
            timestamp: block.timestamp
        });

        bool success = proxy.setResult(result);
        assertTrue(success);

        // Verify result and balances
        SharedStructs.Result memory savedResult = storage_.getResult(resultId);
        assertEq(savedResult.resultId, resultId);
        assertEq(savedResult.dealId, dealId);
        assertEq(savedResult.resultCID, "resultCID1");
        assertEq(uint8(savedResult.status), uint8(SharedStructs.ResultStatusEnum.ResultsRejected));

        vm.stopPrank();
    }

    function test_RevertWhen_NonControllerSetsResult() public {
        vm.startPrank(JOB_CREATOR);
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result-1",
            dealId: "deal-1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        vm.expectRevert();
        proxy.setResult(result);
        vm.stopPrank();
    }

    function test_RevertWhen_SettingResultForNonexistentDeal() public {
        vm.startPrank(address(this));
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result-1",
            dealId: "nonexistent-deal",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(LilypadStorage.LilypadStorage__DealNotFound.selector, "nonexistent-deal")
        );
        proxy.setResult(result);
        vm.stopPrank();
    }

    function test_RevertWhen_SettingResultWithNoResultID() public {
        vm.startPrank(address(this));
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "",
            dealId: "nonexistent-deal",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        vm.expectRevert(abi.encodeWithSelector(LilypadStorage.LilypadStorage__EmptyResultId.selector));
        proxy.setResult(result);
        vm.stopPrank();
    }

    function test_RevertWhen_SettingResultWithEmptyCID() public {
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

        vm.startPrank(address(this));
        storage_.saveDeal(dealId, deal);

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result-1",
            dealId: dealId,
            resultCID: "", // Empty CID
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyCID.selector);
        proxy.setResult(result);
        vm.stopPrank();
    }
}
