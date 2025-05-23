// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

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
     * @param scheduleId The ID of the vesting schedule to be released.
     * @return Returns true if the token release operation is successful.
     */
    function releaseTokens(uint256 scheduleId) external returns (bool);

    /**
     * @dev Calculates the amount of tokens that can be released for a given vesting schedule.
     * @param beneficiary The address of the beneficiary.
     * @param scheduleId The ID of the vesting schedule.
     * @return The amount of tokens that can be released.
     */
    function calculateReleasableTokens(address beneficiary, uint256 scheduleId) external view returns (uint256);

    /**
     * @dev Withdraws the specified amount of tokens from the vesting contract.
     * @param amount The amount of tokens to be withdrawn.
     * @return Returns true if the withdrawal operation is successful.
     * @notice This function is meant to be used by the controller to withdraw tokens on a special needs basis.
     */
    function withdraw(uint256 amount) external returns (bool);
}
