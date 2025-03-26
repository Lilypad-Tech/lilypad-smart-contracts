// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {ILilypadVesting} from "./interfaces/ILilypadVesting.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SharedStructs} from "./SharedStructs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LilypadVesting is ILilypadVesting, ReentrancyGuard, AccessControl {
    IERC20 private l2LilypadToken;

    // Vesting schedule id counter which will be incremented each time a new vesting schedule is created
    uint256 public vestingScheduleCount;

    // Total amount of l2Tokens vested in all schedules
    uint256 private vestingSchedulesTotalAmount;

    // Vesting schedule struct
    struct VestingSchedule {
        // The address of the beneficiary to whom the l2Tokens are vested
        address beneficiary;
        // The total amount of l2Tokens to be vested
        uint256 totalAmount;
        // The start time of the vesting
        uint64 startTime;
        // The amount of l2Tokens already released
        uint256 released;
        // The duration of the cliff period
        uint64 cliffDuration;
        // The duration of the vesting period
        uint64 vestingDuration;
        // Whether vesting is revoked
        bool revoked;
    }

    // Mapping from vesting schedule id to their vesting schedule
    mapping(uint256 => VestingSchedule) public vestingSchedules;

    // Mapping from beneficiary to their vesting schedule ids
    mapping(address => uint256[]) public beneficiarySchedules;

    event LilypadVesting__VestingScheduleCreated(
        address indexed beneficiary, uint256 indexed scheduleId, uint256 amount, uint256 startTime
    );
    event LilypadVesting__l2TokensReleased(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount);

    error LilypadVesting__ZeroAddressNotAllowed();
    error LilypadVesting__InvalidVestingSchedule();
    error LilypadVesting__InvalidBeneficiary();
    error LilypadVesting__InvalidAmount();
    error LilypadVesting__NoVestingSchedule();
    error LilypadVesting__NothingToRelease();
    error LilypadVesting__TransferFailed();
    error LilypadVesting__VestingScheduleRevoked();
    error LilypadVesting__InvalidStartTime();
    error LilypadVesting__InvalidDuration();
    error LilypadVesting__InvalidScheduleId();
    error LilypadVesting__InsufficientBalanceToWithdraw();

    constructor(address _l2TokenAddress) {
        if (_l2TokenAddress == address(0)) {
            revert LilypadVesting__ZeroAddressNotAllowed();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.VESTING_ROLE, msg.sender);
        l2LilypadToken = IERC20(_l2TokenAddress);
    }

    /**
     * @dev Creates a vesting schedule for a specified beneficiary.
     * @return Returns true if the vesting schedule is successfully created.
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint64 startTime,
        uint64 cliffDuration,
        uint64 vestingDuration
    ) external onlyRole(SharedStructs.VESTING_ROLE) returns (bool) {
        if (beneficiary == address(0)) revert LilypadVesting__InvalidBeneficiary();
        if (beneficiary == msg.sender) revert LilypadVesting__InvalidBeneficiary();
        if (amount == 0) revert LilypadVesting__InvalidAmount();
        if (cliffDuration == 0 || vestingDuration == 0) revert LilypadVesting__InvalidDuration();
        if (startTime < uint64(block.timestamp)) revert LilypadVesting__InvalidStartTime();

        // Check each addition separately to prevent overflow
        uint64 cliffEnd;
        uint64 vestingEnd;

        unchecked {
            cliffEnd = startTime + cliffDuration;
            vestingEnd = cliffEnd + vestingDuration;
        }

        // Ensure no overflow occurred and end time is valid
        if (cliffEnd < startTime || vestingEnd < cliffEnd) revert LilypadVesting__InvalidDuration();
        if (vestingEnd < uint64(block.timestamp)) revert LilypadVesting__InvalidStartTime();

        // Increment the vesting schedule count
        vestingScheduleCount++;

        uint256 vestingIndex = vestingScheduleCount;

        // Create the vesting schedule
        vestingSchedules[vestingIndex] = VestingSchedule({
            beneficiary: beneficiary,
            totalAmount: amount,
            startTime: startTime,
            released: 0,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            revoked: false
        });

        // Add the vesting schedule id to the beneficiary's vesting schedule ids
        beneficiarySchedules[beneficiary].push(vestingIndex);

        bool success = l2LilypadToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert LilypadVesting__TransferFailed();

        vestingSchedulesTotalAmount += amount;

        emit LilypadVesting__VestingScheduleCreated(beneficiary, vestingIndex, amount, startTime);
        return true;
    }

    /**
     * @dev Calculates the amount of l2Tokens that can be released for a given vesting schedule.
     * @param beneficiary The address of the beneficiary.
     * @param scheduleId The ID of the vesting schedule.
     * @return The amount of l2Tokens that can be released.
     */
    function calculateReleasableTokens(address beneficiary, uint256 scheduleId) external view returns (uint256) {
        return _calculateReleasableTokens(beneficiary, scheduleId);
    }

    function _calculateReleasableTokens(address beneficiary, uint256 scheduleId) private view returns (uint256) {
        if (beneficiary == address(0)) revert LilypadVesting__InvalidBeneficiary();

        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary != beneficiary) revert LilypadVesting__InvalidBeneficiary();
        if (schedule.revoked) revert LilypadVesting__VestingScheduleRevoked();

        uint64 timeElapsed = uint64(block.timestamp) - schedule.startTime;

        // Before cliff, nothing is vested
        if (timeElapsed < schedule.cliffDuration) return 0;

        uint256 vestedAmount;
        uint256 totalDuration = schedule.cliffDuration + schedule.vestingDuration;

        if (timeElapsed >= totalDuration) {
            // After total vesting period, everything is vested
            vestedAmount = schedule.totalAmount;
        } else {
            if (timeElapsed <= schedule.cliffDuration) {
                vestedAmount = 0;
            } else {
                // Linear vesting after cliff
                uint256 timeElapsedAfterCliff = timeElapsed - schedule.cliffDuration;
                vestedAmount = (timeElapsedAfterCliff * schedule.totalAmount) / schedule.vestingDuration;
            }
        }

        return vestedAmount - schedule.released;
    }

    /**
     * @dev Releases the l2Tokens that have been vested up to the current time for a given vesting schedule.
     * @return Returns true if the l2Token release operation is successful.
     */
    function releaseTokens(uint256 scheduleId) external nonReentrant returns (bool) {
        if (scheduleId > vestingScheduleCount) revert LilypadVesting__InvalidScheduleId();

        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        address beneficiary = schedule.beneficiary;
        if (schedule.revoked) revert LilypadVesting__VestingScheduleRevoked();
        if (msg.sender != beneficiary) revert LilypadVesting__InvalidBeneficiary();

        uint256 releasableAmount = _calculateReleasableTokens(beneficiary, scheduleId);
        if (releasableAmount == 0) revert LilypadVesting__NothingToRelease();

        schedule.released += releasableAmount;

        bool success = l2LilypadToken.transfer(beneficiary, releasableAmount);
        if (!success) revert LilypadVesting__TransferFailed();

        vestingSchedulesTotalAmount -= releasableAmount;
        emit LilypadVesting__l2TokensReleased(beneficiary, scheduleId, releasableAmount);
        return true;
    }

    /**
     * @dev Withdraws the specified amount of l2Tokens from the vesting contract.
     * @return Returns true if the withdrawal operation is successful.
     */
    function withdraw(uint256 amount) external onlyRole(SharedStructs.VESTING_ROLE) returns (bool) {
        if (amount > getWithdrawableAmount()) revert LilypadVesting__InsufficientBalanceToWithdraw();
        bool success = l2LilypadToken.transfer(msg.sender, amount);
        if (!success) revert LilypadVesting__TransferFailed();
        return true;
    }

    /**
     * @dev Returns the amount of l2Tokens that can be withdrawn from the vesting contract.
     * @return The amount of l2Tokens that can be withdrawn.
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return l2LilypadToken.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @dev Returns the vesting schedule IDs for a given beneficiary.
     * @return The vesting schedule IDs.
     */
    function getVestingScheduleIds(address beneficiary) public view returns (uint256[] memory) {
        return beneficiarySchedules[beneficiary];
    }

    /**
     * @dev Returns the vesting schedule for a given schedule ID.
     * @return The vesting schedule.
     */
    function getVestingSchedule(uint256 scheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[scheduleId];
    }

    /**
     * @dev Returns the total number of vesting schedules.
     * @return The total number of vesting schedules.
     */
    function getVestingScheduleCount() public view returns (uint256) {
        return vestingScheduleCount;
    }

    /**
     * @dev Checks if a vesting schedule exists.
     * @return Returns true if the vesting schedule exists and is not revoked.
     */
    function scheduleExists(uint256 scheduleId) public view returns (bool) {
        return scheduleId < vestingScheduleCount && !vestingSchedules[scheduleId].revoked;
    }

    /**
     * @dev Returns the number of vesting schedules for a given beneficiary
     * @return The number of vesting schedules.
     */
    function getNumberOfSchedulesForBeneficiary(address beneficiary) public view returns (uint256) {
        return beneficiarySchedules[beneficiary].length;
    }

    /**
     * @dev Returns the address of the ERC20 l2Token managed by the vesting contract.
     * @return The address of the ERC20 l2Token.
     */
    function getL2TokenAddress() external view returns (address) {
        return address(l2LilypadToken);
    }
}
