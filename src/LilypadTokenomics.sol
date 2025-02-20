// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract LilypadTokenomics is Initializable, AccessControlUpgradeable {
    // The version of the contract
    string public version;

    /**
     * These are the parameters described in the Lilypad tokenomics paper
     *     src: _add_link_here_
     *
     *     p: The percentage of total fees that go towads the protocol
     *     (1-p): The percentage of total fees that go towards the value based rewards
     *
     *     p1: Percentage of P allocated to burn token
     *     p2: Percentage of P allocated to go to grants and airdrops
     *     p3: Percentage of P allocated to the validation pool
     *     Note:  p1 + p2 + p3 must equal 10000 (100%)
     *
     *     m: The percentage of module creator fees that go towards protocol revenue
     *
     *     v1: The scaling factor for determining value based rewards for RPs based on total fees geenrated by the RP
     *     v2: The scaling factor for determining value based rewards for RPs based on total average collateral locked up
     *     Note: v1 > v2 to scaoe the importance of fees over collateral
     */
    uint256 public p;
    uint256 public p1;
    uint256 public p2;
    uint256 public p3;

    uint256 public m;

    uint256 public v1;
    uint256 public v2;

    // This is the scaler for the resource provider's active escrow
    uint256 public resourceProviderActiveEscrowScaler;

    event LilypadTokenomics__TokenomicsParameterUpdated(string indexed parameter, uint256 value);

    error LilypadTokenomics__PValueTooLarge();
    error LilypadTokenomics__MValueTooLarge();
    error LilypadTokenomics__ParametersMustSumToTenThousand();
    error LilypadTokenomics__V1MustBeGreaterThanV2();
    error LilypadTokenomics__V2MustBeLessThanV1();
    error LilypadTokenomics__ZeroAddressNotAllowed();

    function initialize() external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //_grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);

        // Protocol Revenue, P, represented as a basis point
        p = 0;

        // P is further broken down into 3 parts represented as a basis points (each of which should sum to 10000 representing 100% of P)

        // Burn amount represented as a basis point
        p1 = 0;

        // Grants and airdrops represented as a basis point
        p2 = 5000;

        // Validation pool represented as a basis point
        p3 = 5000;

        // Module Creator Fee percentage to be paid to treasury represented as a basis point
        m = 200;

        // expoential weight for scaling fees
        v1 = 2;

        // exponential weight for scaling collateral
        v2 = 1;

        // Set to 11000 (representing 110% in basis points, or a 10% increase)
        resourceProviderActiveEscrowScaler = 11000;
    }

    /**
     * @notice Sets the p1 parameter (burn amount)
     * @param _p1 New p1 value
     * @dev The sum of p1, p2, and p3 must equal 10000 basis points (100%)
     */
    function setPvalues(uint256 _p1, uint256 _p2, uint256 _p3) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_p1 + _p2 + _p3 != 10000) revert LilypadTokenomics__ParametersMustSumToTenThousand();
        p1 = _p1;
        p2 = _p2;
        p3 = _p3;
        emit LilypadTokenomics__TokenomicsParameterUpdated("p1", _p1);
        emit LilypadTokenomics__TokenomicsParameterUpdated("p2", _p2);
        emit LilypadTokenomics__TokenomicsParameterUpdated("p3", _p3);
    }

    /**
     * @notice Sets the p parameter (the amount of fees to be paid to the treasury)
     * @param _p New p value
     */
    function setP(uint256 _p) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_p > 10000) revert LilypadTokenomics__PValueTooLarge();
        p = _p;
        emit LilypadTokenomics__TokenomicsParameterUpdated("p", _p);
    }

    /**
     * @notice Sets the m parameter (The module creator fee)
     * @param _m New m value
     */
    function setM(uint256 _m) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_m > 10000) revert LilypadTokenomics__MValueTooLarge();
        m = _m;
        emit LilypadTokenomics__TokenomicsParameterUpdated("m", _m);
    }

    function setVValues(uint256 _v1, uint256 _v2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_v1 <= _v2) revert LilypadTokenomics__V1MustBeGreaterThanV2();
        if (_v2 >= _v1) revert LilypadTokenomics__V2MustBeLessThanV1();
        v1 = _v1;
        v2 = _v2;
        emit LilypadTokenomics__TokenomicsParameterUpdated("v1", _v1);
        emit LilypadTokenomics__TokenomicsParameterUpdated("v2", _v2);
    }

    /**
     * @notice Sets the resource provider active escrow scaler
     * @param _resourceProviderActiveEscrowScaler New resource provider active escrow scaler
     */
    function setResourceProviderActiveEscrowScaler(uint256 _resourceProviderActiveEscrowScaler)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        resourceProviderActiveEscrowScaler = _resourceProviderActiveEscrowScaler;
        emit LilypadTokenomics__TokenomicsParameterUpdated(
            "resourceProviderActiveEscrowScaler", _resourceProviderActiveEscrowScaler
        );
    }
}
