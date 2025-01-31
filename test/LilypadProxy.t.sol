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
}
