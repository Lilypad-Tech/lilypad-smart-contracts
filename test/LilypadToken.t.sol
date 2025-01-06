// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {SharedStructs} from "../src/SharedStructs.sol";

contract LilypadTokenTest is Test {
    LilypadToken public token;
    address public admin;
    address public minter;
    address public pauser;
    address public user;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        admin = makeAddr("admin");
        minter = makeAddr("minter");
        pauser = makeAddr("pauser");
        user = makeAddr("user");

        vm.startPrank(admin);
        token = new LilypadToken(INITIAL_SUPPLY);
        vm.stopPrank();
    }

    // Constructor Tests
    function test_InitialState() public view {
        assertEq(token.name(), "Lilypad Token");
        assertEq(token.symbol(), "LILY");
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(SharedStructs.MINTER_ROLE, admin));
        assertTrue(token.hasRole(SharedStructs.PAUSER_ROLE, admin));
    }

    function testFuzz_ConstructorRevertsIfInitialSupplyTooHigh(
        uint256 invalidSupply
    ) public {
        vm.assume(invalidSupply > MAX_SUPPLY);
        vm.expectRevert(LilypadToken.LilypadToken__MaxSupplyReached.selector);
        new LilypadToken(invalidSupply);
    }

    // Role Management Tests
    function test_AddMinter() public {
        vm.prank(admin);
        assertTrue(token.addMinter(minter));
        assertTrue(token.hasRole(SharedStructs.MINTER_ROLE, minter));
    }

    function test_RevertAddMinterIfNotAdmin() public {
        vm.prank(user);
        vm.expectRevert();
        token.addMinter(minter);
    }

    function test_RevertAddMinterIfZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(LilypadToken.LilypadToken__InvalidAddress.selector);
        token.addMinter(address(0));
    }

    // Minting Tests
    function testFuzz_Mint(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY - INITIAL_SUPPLY);

        vm.prank(admin);
        assertTrue(token.mint(user, amount));
        assertEq(token.balanceOf(user), amount);
    }

    function test_RevertMintIfNotMinter() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 1000);
    }

    function test_RevertMintIfExceedsMaxSupply() public {
        vm.prank(admin);
        vm.expectRevert(LilypadToken.LilypadToken__MaxSupplyReached.selector);
        token.mint(user, MAX_SUPPLY);
    }

    // Burning Tests
    function test_Burn() public {
        // Setup minter role
        uint256 mintAmount = 10000;
        vm.startPrank(admin);
        token.addMinter(minter);
        token.transfer(minter, mintAmount);
        vm.stopPrank();
        assertTrue(token.hasRole(SharedStructs.MINTER_ROLE, minter));

        uint256 burnAmount = 1000;
        vm.prank(minter);
        token.burn(burnAmount);
        vm.stopPrank();
        assertEq(token.balanceOf(minter), mintAmount - burnAmount); // Verify remaining balance
    }

    function test_RevertBurnIfInsufficientBalance() public {
        vm.startPrank(admin);
        token.addMinter(minter);
        vm.stopPrank();

        vm.prank(minter);
        vm.expectRevert(LilypadToken.LilypadToken__NotEnoughBalance.selector);
        token.burn(1000);
    }

    // Pause Tests
    function test_PauseAndUnpause() public {
        vm.startPrank(admin);
        token.pause();
        assertTrue(token.paused());

        vm.expectRevert();
        token.transfer(user, 1000);

        token.unpause();
        assertFalse(token.paused());

        // Transfer should work after unpausing
        assertTrue(token.transfer(user, 1000));
        vm.stopPrank();
    }

    function test_RevertPauseIfNotPauser() public {
        vm.prank(user);
        vm.expectRevert();
        token.pause();
    }

    // Transfer Tests
    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY);

        vm.prank(admin);
        token.transfer(user, amount);
        assertEq(token.balanceOf(user), amount);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - amount);
    }
}
