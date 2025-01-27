// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface ILilypadVesting {
   /**
     * @dev Creates a vesting schedule for a specified beneficiary.
     * @param beneficiary The address of the recipient of the vested tokens.
     * @param amount The total amount of tokens to be vested.
     * @param startTime The start time (as a timestamp) for the vesting schedule.
     * @param cliffDuration The duration of the cliff period (in seconds) after which tokens start vesting.
     * @param vestingDuration The duration of the vesting period (in seconds).
     * @return Returns true if the vesting schedule is successfully created.
     * @notice This function is restricted to the controller role.
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint64 startTime,
        uint64 cliffDuration,
        uint64 vestingDuration
    ) external returns (bool);

    /**
     * @dev Releases the tokens that have been vested up to the current time for all eligible beneficiaries.
     * The function calculates and transfers releasable tokens based on the defined vesting schedule.
     * @param beneficiary The address of the beneficiary whose tokens are being released.
     * @param scheduleId The ID of the vesting schedule to be released.
     * @return Returns true if the token release operation is successful.
     */
    function releaseTokens(address beneficiary, uint256 scheduleId) external returns (bool);

    /**
     * @dev Calculates the number of tokens that are releasable for a specific beneficiary.
     * The calculation is based on the vesting schedule and the current timestamp.
     * @param beneficiary The address of the beneficiary whose releasable tokens are being calculated.
     * @param scheduleId The ID of the vesting schedule to be calculated.
     * @return The amount of tokens that are currently releasable for the beneficiary.
     */
    function calculateReleasableTokens(address beneficiary, uint256 scheduleId) external view returns (uint256);

    /**
     * @dev Invalidates a vesting schedule for a specific beneficiary.
     * @param scheduleId The ID of the vesting schedule to be invalidated.
     * @return Returns true if the vesting schedule is successfully invalidated.
     */
    function invalidateVestingSchedule(uint256 scheduleId) external returns (bool);
}