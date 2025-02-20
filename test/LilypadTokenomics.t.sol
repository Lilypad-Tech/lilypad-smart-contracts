// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {LilypadTokenomics} from "../src/LilypadTokenomics.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LilypadTokenomicsTest is Test {
    LilypadTokenomics lilypadTokenomics;
    address public constant ALICE = address(0x1);
    address public constant CONTROLLER = address(0x3);

    event LilypadTokenomics__TokenomicsParameterUpdated(string indexed parameter, uint256 value);

    function setUp() public {
        lilypadTokenomics = new LilypadTokenomics();
        bytes memory tokenomicsInitData = abi.encodeWithSelector(LilypadTokenomics.initialize.selector);
        ERC1967Proxy tokenomicsProxy = new ERC1967Proxy(address(lilypadTokenomics), tokenomicsInitData);
        lilypadTokenomics = LilypadTokenomics(address(tokenomicsProxy));
    }

    // Parameter Update Tests
    function test_UpdateTokenomicsParameters() public {
        vm.startPrank(address(this)); // Default admin role
        lilypadTokenomics.setPvalues(0, 5000, 5000);
        lilypadTokenomics.setM(200); // 2%
        lilypadTokenomics.setVValues(2, 1); // 2x, 1.5x
        lilypadTokenomics.setResourceProviderActiveEscrowScaler(10000);
        assertTrue(lilypadTokenomics.hasRole(lilypadTokenomics.DEFAULT_ADMIN_ROLE(), address(this)));
        assertEq(lilypadTokenomics.p1(), 0);
        assertEq(lilypadTokenomics.p2(), 5000);
        assertEq(lilypadTokenomics.p3(), 5000);
        assertEq(lilypadTokenomics.p(), 0);
        assertEq(lilypadTokenomics.m(), 200);
        assertEq(lilypadTokenomics.v1(), 2);
        assertEq(lilypadTokenomics.v2(), 1);
        assertEq(lilypadTokenomics.resourceProviderActiveEscrowScaler(), 10000);
        vm.stopPrank();
    }

    function test_RevertWhen_NonAdminUpdatesParameters() public {
        vm.startPrank(ALICE);

        vm.expectRevert();
        lilypadTokenomics.setM(5000);

        vm.expectRevert();
        lilypadTokenomics.setPvalues(5000, 5000, 5000);

        vm.stopPrank();
    }

    function test_SetPvalues() public {
        vm.startPrank(address(this));

        uint256 _newP1 = 2000;
        uint256 _newP2 = 4000;
        uint256 _newP3 = 4000;

        // Set p1 to complete the 10000 total
        lilypadTokenomics.setPvalues(_newP1, _newP2, _newP3);

        assertEq(lilypadTokenomics.p1(), _newP1);
        assertEq(lilypadTokenomics.p2(), _newP2);
        assertEq(lilypadTokenomics.p3(), _newP3);
        vm.stopPrank();
    }

    function test_SetPvalues_Reverts_WhenNotAdmin() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        lilypadTokenomics.setPvalues(1000, 1000, 1000);
        vm.stopPrank();
    }

    function test_SetPValues_Reverts_WhenSumNotTenThousand() public {
        vm.startPrank(address(this));
        // Try to set p1 to value that would make sum > 10000
        vm.expectRevert(LilypadTokenomics.LilypadTokenomics__ParametersMustSumToTenThousand.selector);
        lilypadTokenomics.setPvalues(20000, 1000, 1000); // Would make sum > 10000
        vm.stopPrank();
    }

    function test_SetP() public {
        vm.startPrank(address(this));

        vm.expectEmit(true, true, true, true);
        emit LilypadTokenomics__TokenomicsParameterUpdated("p", 2000);

        lilypadTokenomics.setP(2000);
        assertEq(lilypadTokenomics.p(), 2000);
        vm.stopPrank();
    }

    function test_SetP_Reverts_WhenNotAdmin() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        lilypadTokenomics.setP(2000);
        vm.stopPrank();
    }

    function test_SetP_Reverts_WhenPValueTooLarge() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadTokenomics.LilypadTokenomics__PValueTooLarge.selector);
        lilypadTokenomics.setP(10001);
        vm.stopPrank();
    }

    function test_SetM() public {
        vm.startPrank(address(this));
        vm.expectEmit(true, true, true, true);
        emit LilypadTokenomics__TokenomicsParameterUpdated("m", 2000);
        lilypadTokenomics.setM(2000);
        assertEq(lilypadTokenomics.m(), 2000);
        vm.stopPrank();
    }

    function test_SetM_Reverts_WhenMValueTooLarge() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadTokenomics.LilypadTokenomics__MValueTooLarge.selector);
        lilypadTokenomics.setM(10001);
        vm.stopPrank();
    }

    function test_SetVValues() public {
        vm.startPrank(address(this));
        // First set v2 to a lower value
        vm.expectEmit(true, true, true, true);
        emit LilypadTokenomics__TokenomicsParameterUpdated("v1", 3);

        vm.expectEmit(true, true, true, true);
        emit LilypadTokenomics__TokenomicsParameterUpdated("v2", 2);

        lilypadTokenomics.setVValues(3, 2);
        assertEq(lilypadTokenomics.v1(), 3);
        assertEq(lilypadTokenomics.v2(), 2);
        vm.stopPrank();
    }

    function test_SetVValues_Reverts_WhenNotAdmin() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        lilypadTokenomics.setVValues(200, 100);
        vm.stopPrank();
    }

    function test_SetV1_Reverts_WhenNotGreaterThanV2() public {
        vm.startPrank(address(this));
        vm.expectRevert(LilypadTokenomics.LilypadTokenomics__V1MustBeGreaterThanV2.selector);
        lilypadTokenomics.setVValues(99, 100); // v2 defaults to 1, so v1 must be > 1
        vm.stopPrank();
    }

    function test_SetV2() public {
        vm.startPrank(address(this));
        // v2 must be less than v1, and v1 defaults to 2
        lilypadTokenomics.setVValues(2, 1);
        assertEq(lilypadTokenomics.v2(), 1);
        vm.stopPrank();
    }

    function test_SetV2_Reverts_WhenNotAdmin() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        lilypadTokenomics.setVValues(2, 1);
        vm.stopPrank();
    }
}
