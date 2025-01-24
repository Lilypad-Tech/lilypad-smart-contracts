// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface ILilypadVesting {
   /**
     * @dev Creates a vesting schedule for a specified beneficiary.
     * @param beneficiary The address of the recipient of the vested tokens.
     * @param totalAmount The total amount of tokens to be vested.
     * @param startTime The start time (as a timestamp) for the vesting schedule.
     * @param cliffDuration The duration of the cliff period (in seconds) after which tokens start vesting.
     * @param epochDuration The duration of each vesting epoch (in seconds).
     * @return Returns true if the vesting schedule is successfully created.
     * @notice This function is restricted to the controller role.
     */
    function CreateVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 epochDuration
    ) external returns (bool);

    /**
     * @dev Releases the tokens that have been vested up to the current time for all eligible beneficiaries.
     * The function calculates and transfers releasable tokens based on the defined vesting schedule.
     * @return Returns true if the token release operation is successful.
     */
    function ReleaseTokens() external returns (bool);

    /**
     * @dev Calculates the number of tokens that are releasable for a specific beneficiary.
     * The calculation is based on the vesting schedule and the current timestamp.
     * @param beneficiary The address of the beneficiary whose releasable tokens are being calculated.
     * @return The amount of tokens that are currently releasable for the beneficiary.
     */
    function CalculateReleasableTokens(address beneficiary) external view returns (uint256);
}