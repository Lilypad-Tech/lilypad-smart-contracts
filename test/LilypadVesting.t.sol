// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LilypadVesting} from "../src/LilypadVesting.sol";
import {LilypadToken} from "../src/LilypadToken.sol";
import {SharedStructs} from "../src/SharedStructs.sol";

contract LilypadVestingTest is Test {
    LilypadVesting public vestingContract;
    LilypadToken public token;

    address public constant ADMIN = address(0x1);
    address public constant BENEFICIARY = address(0x2);
    address public constant VESTING_MANAGER = address(0x3);

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant VESTING_AMOUNT = 1_000 * 10 ** 18;
    uint64 public constant CLIFF_DURATION = 30 days;
    uint64 public constant VESTING_DURATION = 30 days;

    event LilypadVesting__VestingScheduleCreated(
        address indexed beneficiary, uint256 indexed scheduleId, uint256 amount, uint256 startTime
    );
    event LilypadVesting__TokensReleased(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount);
    event LilypadVesting__VestingRoleGranted(address indexed account, address indexed caller);
    event LilypadVesting__VestingRoleRevoked(address indexed account, address indexed caller);

    function setUp() public {
        vm.startPrank(ADMIN);

        // Deploy token
        token = new LilypadToken(INITIAL_SUPPLY);

        // Deploy vesting contract
        vestingContract = new LilypadVesting(address(token));

        // Grant vesting role to VESTING_MANAGER
        vestingContract.grantRole(SharedStructs.VESTING_ROLE, VESTING_MANAGER);

        // Mint tokens to ADMIN
        token.mint(ADMIN, INITIAL_SUPPLY);

        // Approve vesting contract to spend tokens
        token.approve(address(vestingContract), type(uint256).max);

        vm.stopPrank();
    }

    // Basic functionality tests
    function test_InitialState() public {
        assertEq(address(vestingContract.getL2TokenAddress()), address(token));
        assertEq(vestingContract.vestingScheduleCount(), 0);
        assertTrue(vestingContract.hasRole(SharedStructs.VESTING_ROLE, ADMIN));
        assertTrue(vestingContract.hasRole(SharedStructs.VESTING_ROLE, VESTING_MANAGER));
    }

    function test_CreateVestingSchedule() public {
        vm.startPrank(ADMIN);

        uint64 startTime = uint64(block.timestamp + 1 days);

        // First check initial state
        assertEq(vestingContract.vestingScheduleCount(), 0);

        vm.expectEmit(true, true, true, true);
        emit LilypadVesting__VestingScheduleCreated(BENEFICIARY, 1, VESTING_AMOUNT, startTime);

        bool success = vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, startTime, CLIFF_DURATION, VESTING_DURATION
        );

        assertTrue(success);

        // Check schedule count increased
        assertEq(vestingContract.vestingScheduleCount(), 1);

        // Get the schedule and verify all fields
        LilypadVesting.VestingSchedule memory schedule = vestingContract.getVestingSchedule(1);
        assertEq(schedule.beneficiary, BENEFICIARY, "Wrong beneficiary");
        assertEq(schedule.totalAmount, VESTING_AMOUNT, "Wrong amount");
        assertEq(schedule.startTime, startTime, "Wrong start time");
        assertEq(schedule.cliffDuration, CLIFF_DURATION, "Wrong cliff duration");
        assertEq(schedule.vestingDuration, VESTING_DURATION, "Wrong vesting duration");
        assertEq(schedule.released, 0, "Should have no released tokens");
        assertFalse(schedule.revoked, "Should not be revoked");

        // Verify beneficiary's schedule IDs
        uint256[] memory scheduleIds = vestingContract.getVestingScheduleIds(BENEFICIARY);
        assertEq(scheduleIds.length, 1, "Should have one schedule");
        assertEq(scheduleIds[0], 1, "Wrong schedule ID");

        vm.stopPrank();
    }

    function test_ReleaseTokens() public {
        // Create vesting schedule
        vm.startPrank(ADMIN);
        uint64 startTime = uint64(block.timestamp);

        // Create schedule and verify it was created
        bool success = vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, startTime, CLIFF_DURATION, VESTING_DURATION
        );
        assertTrue(success);

        // Verify schedule was created correctly
        assertEq(vestingContract.vestingScheduleCount(), 1);
        LilypadVesting.VestingSchedule memory schedule = vestingContract.getVestingSchedule(1);
        assertEq(schedule.beneficiary, BENEFICIARY, "Wrong beneficiary");
        vm.stopPrank();

        // Fast forward past cliff
        vm.warp(block.timestamp + CLIFF_DURATION + 1);

        // Release tokens as beneficiary
        vm.startPrank(BENEFICIARY);
        success = vestingContract.releaseTokens(1);
        assertTrue(success, "Token release failed");

        // Check released amount (should be slightly more than 0% after cliff)
        uint256 expectedAmount = (1 * VESTING_AMOUNT) / VESTING_DURATION; // 1 second after cliff
        assertApproxEqRel(
            token.balanceOf(BENEFICIARY),
            expectedAmount,
            0.01e18 // 1% tolerance
        );

        // Fast forward to middle of vesting period
        vm.warp(block.timestamp + VESTING_DURATION / 2);

        // Release more tokens
        success = vestingContract.releaseTokens(1);
        assertTrue(success, "Second token release failed");

        // Check released amount (should be ~50% at middle of vesting)
        assertApproxEqRel(
            token.balanceOf(BENEFICIARY),
            VESTING_AMOUNT / 2,
            0.01e18 // 1% tolerance
        );

        vm.stopPrank();
    }

    // Fuzz tests
    function testFuzz_CreateVestingSchedule(
        uint256 amount,
        uint64 startOffset,
        uint64 cliffDuration,
        uint64 vestingDuration
    ) public {
        // Bound the fuzzing inputs to reasonable values
        amount = bound(amount, 1, INITIAL_SUPPLY);
        startOffset = uint64(bound(startOffset, 1, 365 days));
        cliffDuration = uint64(bound(cliffDuration, 1 days, 365 days));
        vestingDuration = uint64(bound(vestingDuration, 1 days, 365 days));

        uint64 startTime = uint64(block.timestamp + startOffset);

        vm.startPrank(ADMIN);
        bool success =
            vestingContract.createVestingSchedule(BENEFICIARY, amount, startTime, cliffDuration, vestingDuration);
        assertTrue(success);

        // Check schedule count
        assertEq(vestingContract.vestingScheduleCount(), 1);

        LilypadVesting.VestingSchedule memory schedule = vestingContract.getVestingSchedule(1);
        assertEq(schedule.totalAmount, amount);
        assertEq(schedule.startTime, startTime);
        assertEq(schedule.cliffDuration, cliffDuration);
        assertEq(schedule.vestingDuration, vestingDuration);
        vm.stopPrank();
    }

    function testFuzz_ReleaseTokens(uint256 amount, uint64 timeElapsed) public {
        // Bound the fuzzing inputs
        amount = bound(amount, 1000, INITIAL_SUPPLY);
        // Ensure timeElapsed is between cliff and total duration
        timeElapsed = uint64(bound(timeElapsed, CLIFF_DURATION + 1 days, CLIFF_DURATION + VESTING_DURATION));

        uint64 startTime = uint64(block.timestamp);

        // Create schedule
        vm.startPrank(ADMIN);
        bool success =
            vestingContract.createVestingSchedule(BENEFICIARY, amount, startTime, CLIFF_DURATION, VESTING_DURATION);
        assertTrue(success, "Schedule creation failed");
        vm.stopPrank();

        // Warp time
        vm.warp(startTime + timeElapsed);

        // Calculate expected vested amount
        uint256 expectedVestedAmount;
        if (timeElapsed >= (CLIFF_DURATION + VESTING_DURATION)) {
            expectedVestedAmount = amount;
        } else {
            uint256 timeElapsedAfterCliff = timeElapsed - CLIFF_DURATION;
            expectedVestedAmount = (timeElapsedAfterCliff * amount) / VESTING_DURATION;
        }

        // Release tokens
        vm.startPrank(BENEFICIARY);
        success = vestingContract.releaseTokens(1);
        assertTrue(success, "Token release failed");
        vm.stopPrank();

        // Verify balance matches expected vested amount
        assertApproxEqRel(
            token.balanceOf(BENEFICIARY),
            expectedVestedAmount,
            0.01e18 // 1% tolerance
        );

        // Verify balance is never more than total amount
        assertTrue(token.balanceOf(BENEFICIARY) <= amount, "Released more than total amount");
    }

    // Revert tests
    function test_RevertWhen_CreatingScheduleWithZeroAddress() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(LilypadVesting.LilypadVesting__InvalidBeneficiary.selector);
        vestingContract.createVestingSchedule(
            address(0), VESTING_AMOUNT, uint64(block.timestamp + 1 days), CLIFF_DURATION, VESTING_DURATION
        );
        vm.stopPrank();
    }

    function test_RevertWhen_CreatingScheduleWithZeroAmount() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(LilypadVesting.LilypadVesting__InvalidAmount.selector);
        vestingContract.createVestingSchedule(
            BENEFICIARY, 0, uint64(block.timestamp + 1 days), CLIFF_DURATION, VESTING_DURATION
        );
        vm.stopPrank();
    }

    function test_RevertWhen_ReleasingBeforeCliff() public {
        // Create schedule
        vm.startPrank(ADMIN);
        vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, uint64(block.timestamp), CLIFF_DURATION, VESTING_DURATION
        );
        vm.stopPrank();

        // Try to release before cliff
        vm.startPrank(BENEFICIARY);
        vm.expectRevert(LilypadVesting.LilypadVesting__NothingToRelease.selector);
        vestingContract.releaseTokens(1);
        vm.stopPrank();
    }

    function test_RevertWhen_NonBeneficiaryReleasesTokens() public {
        // Create schedule
        vm.startPrank(ADMIN);
        vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, uint64(block.timestamp), CLIFF_DURATION, VESTING_DURATION
        );
        vm.stopPrank();

        // Try to release as non-beneficiary
        vm.startPrank(ADMIN);
        vm.expectRevert(bytes4(keccak256("LilypadVesting__InvalidBeneficiary()")));
        vestingContract.releaseTokens(0);
        vm.stopPrank();
    }

    function test_MultipleSchedulesForSameBeneficiary() public {
        vm.startPrank(ADMIN);

        // Create two schedules
        vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, uint64(block.timestamp), CLIFF_DURATION, VESTING_DURATION
        );

        vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT * 2, uint64(block.timestamp + 1 days), CLIFF_DURATION * 2, VESTING_DURATION * 2
        );

        // Verify schedules
        uint256[] memory scheduleIds = vestingContract.getVestingScheduleIds(BENEFICIARY);
        assertEq(scheduleIds.length, 2, "Should have two schedules");
        assertEq(scheduleIds[0], 1, "Wrong first schedule ID");
        assertEq(scheduleIds[1], 2, "Wrong second schedule ID");

        vm.stopPrank();
    }

    function test_WithdrawUnusedTokens() public {
        uint256 extraAmount = 1000 * 10 ** 18;

        vm.startPrank(ADMIN);
        // Send extra tokens to contract
        token.transfer(address(vestingContract), extraAmount);

        // Create a vesting schedule
        vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, uint64(block.timestamp), CLIFF_DURATION, VESTING_DURATION
        );

        // Check withdrawable amount
        assertEq(vestingContract.getWithdrawableAmount(), extraAmount);

        // Withdraw extra tokens
        bool success = vestingContract.withdraw(extraAmount);
        assertTrue(success, "Withdrawal failed");

        vm.stopPrank();
    }

    function test_CompleteVestingCycle() public {
        vm.startPrank(ADMIN);
        uint64 startTime = uint64(block.timestamp);

        vestingContract.createVestingSchedule(BENEFICIARY, VESTING_AMOUNT, startTime, CLIFF_DURATION, VESTING_DURATION);
        vm.stopPrank();

        // Check at different points
        // Before cliff
        assertEq(vestingContract.calculateReleasableTokens(BENEFICIARY, 1), 0);

        // At cliff
        vm.warp(startTime + CLIFF_DURATION);
        assertEq(vestingContract.calculateReleasableTokens(BENEFICIARY, 1), 0);

        // Middle of vesting
        vm.warp(startTime + CLIFF_DURATION + VESTING_DURATION / 2);
        assertApproxEqRel(vestingContract.calculateReleasableTokens(BENEFICIARY, 1), VESTING_AMOUNT / 2, 0.01e18);

        // End of vesting
        vm.warp(startTime + CLIFF_DURATION + VESTING_DURATION);
        assertEq(vestingContract.calculateReleasableTokens(BENEFICIARY, 1), VESTING_AMOUNT);
    }

    function test_RevertWhen_WithdrawingTooMuch() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(LilypadVesting.LilypadVesting__InsufficientBalanceToWithdraw.selector);
        vestingContract.withdraw(INITIAL_SUPPLY + 1);
        vm.stopPrank();
    }

    function test_RevertWhen_NonAdminGrantsRole() public {
        vm.startPrank(BENEFICIARY);
        vm.expectRevert();
        vestingContract.grantRole(SharedStructs.VESTING_ROLE, BENEFICIARY);
        vm.stopPrank();
    }

    function test_RevertWhen_StartTimeInPast() public {
        vm.startPrank(ADMIN);
        vm.expectRevert(LilypadVesting.LilypadVesting__InvalidStartTime.selector);
        vestingContract.createVestingSchedule(
            BENEFICIARY, VESTING_AMOUNT, uint64(block.timestamp - 1), CLIFF_DURATION, VESTING_DURATION
        );
        vm.stopPrank();
    }

    function testFuzz_WithdrawPartialAmount(uint256 withdrawAmount) public {
        uint256 extraAmount = INITIAL_SUPPLY / 2;
        withdrawAmount = bound(withdrawAmount, 1, extraAmount);

        vm.startPrank(ADMIN);
        // Send extra tokens to contract
        token.transfer(address(vestingContract), extraAmount);

        // Withdraw partial amount
        bool success = vestingContract.withdraw(withdrawAmount);
        assertTrue(success, "Withdrawal failed");

        // Verify remaining amount
        assertEq(vestingContract.getWithdrawableAmount(), extraAmount - withdrawAmount, "Incorrect remaining amount");
        vm.stopPrank();
    }

    function test_StartTimeValidationOverflow() public {
        vm.startPrank(ADMIN);

        // Using values that will cause overflow
        uint64 startTime = type(uint64).max - 100;
        uint64 cliffDuration = 50;
        uint64 vestingDuration = 100;

        // Should revert with InvalidDuration due to overflow check
        vm.expectRevert(LilypadVesting.LilypadVesting__InvalidDuration.selector);
        vestingContract.createVestingSchedule(BENEFICIARY, VESTING_AMOUNT, startTime, cliffDuration, vestingDuration);

        vm.stopPrank();
    }

    function test_PrecisionInVestingCalculation() public {
        vm.startPrank(ADMIN);

        // Small amount to test precision
        uint256 smallAmount = 1000 * 10 ** 18; // 1000 tokens
        uint64 startTime = uint64(block.timestamp);

        vestingContract.createVestingSchedule(
            BENEFICIARY,
            smallAmount,
            startTime,
            CLIFF_DURATION,
            365 days // 1 year vesting
        );

        // Move to 1 day after cliff
        vm.warp(startTime + CLIFF_DURATION + 1 days);

        // Calculate expected amount: (1 day / 365 days) * 1000 tokens ≈ 2.739726027397260274 tokens
        uint256 releasableAmount = vestingContract.calculateReleasableTokens(BENEFICIARY, 1);

        // With proper precision handling, we should get at least 2 tokens
        assertGt(releasableAmount, 2 * 10 ** 18, "Lost precision in vesting calculation");

        // Move to end of vesting
        vm.warp(startTime + CLIFF_DURATION + 365 days);

        // Should get exact amount at end
        releasableAmount = vestingContract.calculateReleasableTokens(BENEFICIARY, 1);
        assertEq(releasableAmount, smallAmount, "Did not vest full amount");

        vm.stopPrank();
    }

    function test_MaximumValues() public {
        vm.startPrank(ADMIN);

        // Use a large but reasonable amount that won't exceed token supply
        uint256 maxAmount = 1_000_000 * 10 ** 18; // 1 million tokens
        uint64 startTime = uint64(block.timestamp + 1);
        uint64 maxDuration = type(uint64).max / 3; // Divide by 3 to prevent overflow when adding

        bool success =
            vestingContract.createVestingSchedule(BENEFICIARY, maxAmount, startTime, maxDuration, maxDuration);

        assertTrue(success, "Failed to create schedule with maximum values");

        // Verify the schedule was created correctly
        LilypadVesting.VestingSchedule memory schedule = vestingContract.getVestingSchedule(1);
        assertEq(schedule.totalAmount, maxAmount);
        assertEq(schedule.cliffDuration, maxDuration);
        assertEq(schedule.vestingDuration, maxDuration);

        vm.stopPrank();
    }

    function test_MultipleReleasesInSameBlock() public {
        vm.startPrank(ADMIN);

        // Create schedule
        uint64 startTime = uint64(block.timestamp);
        vestingContract.createVestingSchedule(BENEFICIARY, VESTING_AMOUNT, startTime, CLIFF_DURATION, VESTING_DURATION);
        vm.stopPrank();

        // Move to middle of vesting
        vm.warp(startTime + CLIFF_DURATION + VESTING_DURATION / 2);

        vm.startPrank(BENEFICIARY);
        // First release should succeed
        bool success = vestingContract.releaseTokens(1);
        assertTrue(success, "First release failed");

        // Second release in same block should revert with nothing to release
        vm.expectRevert(LilypadVesting.LilypadVesting__NothingToRelease.selector);
        vestingContract.releaseTokens(1);

        vm.stopPrank();
    }
}
