// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./interfaces/ILilypadVesting.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SharedStructs} from "./SharedStructs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LilypadToken} from "./LilypadToken.sol";

contract LilypadVesting is ILilypadVesting, ReentrancyGuard, AccessControl {
    LilypadToken public token;

    // Vesting schedule id counter which will be incremented each time a new vesting schedule is created
    uint256 public vestingScheduleCount;

    // Vesting schedule struct
    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;      // Total amount to be vested
        uint64 startTime;         // Start time of vesting
        uint256 released;         // Amount already released
        uint64 cliffDuration;     // Duration of the cliff period
        uint64 vestingDuration;   // Duration of the vesting period
        bool isActive;            // Whether vesting is active
    }

    // Mapping from vesting schedule id to their vesting schedule
    mapping(uint256 => VestingSchedule) public vestingSchedules;

    // Mapping from beneficiary to their vesting schedule ids
    mapping(address => uint256[]) public beneficiarySchedules;

    event VestingScheduleCreated(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount, uint256 startTime);
    event TokensReleased(address indexed beneficiary, uint256 indexed scheduleId, uint256 amount);
    event VestingScheduleInvalidated(address indexed beneficiary, uint256 indexed scheduleId);

    error LilypadVesting__ZeroAddressNotAllowed();
    error LilypadVesting__InvalidVestingSchedule();
    error LilypadVesting__InvalidBeneficiary();
    error LilypadVesting__InvalidAmount();
    error LilypadVesting__NoVestingSchedule();
    error LilypadVesting__NothingToRelease();
    error LilypadVesting__TransferFailed();
    error LilypadVesting__VestingScheduleNotActive();
    error LilypadVesting__InvalidStartTime();
    error LilypadVesting__InvalidDuration();

    constructor(address _tokenAddress) {
        if (_tokenAddress == address(0)) {
            revert LilypadVesting__ZeroAddressNotAllowed();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
        token = LilypadToken(_tokenAddress);
    }

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
        if (startTime < uint64(block.timestamp) || startTime + cliffDuration + vestingDuration < uint64(block.timestamp)) {
            revert LilypadVesting__InvalidStartTime();
        }
        if (cliffDuration == 0 || vestingDuration == 0) revert LilypadVesting__InvalidDuration();

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
            isActive: true
        });

        // Add the vesting schedule id to the beneficiary's vesting schedule ids
        beneficiarySchedules[beneficiary].push(vestingIndex);

        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert LilypadVesting__TransferFailed();

        emit VestingScheduleCreated(beneficiary, vestingIndex, amount, startTime);
        return true;
    }

    function invalidateVestingSchedule(uint256 scheduleId) external onlyRole(SharedStructs.VESTING_ROLE) returns (bool) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        if (!schedule.isActive) revert LilypadVesting__VestingScheduleNotActive();
        schedule.isActive = false;

        emit VestingScheduleInvalidated(schedule.beneficiary, scheduleId);
        return true;
    }

    function releaseTokens(address beneficiary, uint256 scheduleId) external nonReentrant returns (bool) {
        //TODO: implement this
        return true;
    }

    function calculateReleasableTokens(address beneficiary, uint256 scheduleId) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary != beneficiary) revert LilypadVesting__InvalidBeneficiary();
        if (!schedule.isActive) return 0;

        uint64 timeElapsed = uint64(block.timestamp) - schedule.startTime;
        
        // Before cliff, nothing is vested
        if (timeElapsed < schedule.cliffDuration) return 0;

        uint256 vestedAmount;
        if (timeElapsed >= schedule.vestingDuration) {
            // After vesting period, everything is vested
            vestedAmount = schedule.totalAmount;
        } else {
            // Calculate the amount vested linearly
            vestedAmount = (uint256(timeElapsed) * schedule.totalAmount) / uint256(schedule.vestingDuration);

            // or
            // uint64 timeFromCliff = uint64(block.timestamp) - schedule.cliffDuration;
            // uint64 totalVestingTime = schedule.vestingDuration; 
            // vestedAmount = (uint256(timeFromCliff) * schedule.totalAmount) / uint256(totalVestingTime);
        }

        return vestedAmount - schedule.released;
    }

    function getVestingScheduleIds(address beneficiary) external view returns (uint256[] memory) {
        return beneficiarySchedules[beneficiary];
    }

    function getVestingSchedule(uint256 scheduleId) external view returns (VestingSchedule memory) {
        return vestingSchedules[scheduleId];
    }

    function getVestingScheduleCount() external view returns (uint256) {
        return vestingScheduleCount;
    }
}
