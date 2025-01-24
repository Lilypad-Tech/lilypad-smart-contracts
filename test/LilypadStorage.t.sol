// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LilypadStorage.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LilypadStorageTest is Test {
    LilypadStorage public lilypadStorage;
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant CHARLIE = address(0x3);
    address public constant DAVE = address(0x4);
    address public constant CONTROLLER = address(0x3);

    // Events
    event DealStatusChanged(string indexed dealId, SharedStructs.DealStatusEnum status);
    event ValidationResultStatusChanged(
        string indexed validationResultId, SharedStructs.ValidationResultStatusEnum status
    );
    event ResultStatusChanged(string indexed resultId, SharedStructs.ResultStatusEnum status);
    event DealSaved(string indexed dealId, address jobCreator, address resourceProvider);
    event ResultSaved(string indexed resultId, string dealId);
    event ValidationResultSaved(string indexed validationResultId, string resultId, address validator);
    event ControllerRoleGranted(address indexed newController, address indexed controller);
    event ControllerRoleRevoked(address indexed revokedController, address indexed controller);

    function setUp() public {
        // Deploy implementation
        LilypadStorage implementation = new LilypadStorage();

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(LilypadStorage.initialize.selector);

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to LilypadStorage
        lilypadStorage = LilypadStorage(address(proxy));

        // Grant controller role to CONTROLLER address
        lilypadStorage.grantRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER);
    }

    // Version Tests
    function test_InitialVersion() public view {
        assertEq(lilypadStorage.version(), "1.0.0");
    }

    function test_GetVersion() public view {
        assertEq(lilypadStorage.getVersion(), "1.0.0");
    }

    // Deal Tests
    function test_RevertWhen_NonControllerSavesDeal() public {
        vm.startPrank(ALICE);

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, ALICE, SharedStructs.CONTROLLER_ROLE
            )
        );
        lilypadStorage.saveDeal("deal1", deal);
    }

    function test_SaveAndGetDeal() public {
        vm.startPrank(CONTROLLER);

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });

        vm.expectEmit(true, true, true, true);
        emit DealSaved("deal1", ALICE, BOB);

        bool success = lilypadStorage.saveDeal("deal1", deal);
        assertTrue(success);

        SharedStructs.Deal memory retrievedDeal = lilypadStorage.getDeal("deal1");
        assertEq(retrievedDeal.dealId, deal.dealId);
        assertEq(retrievedDeal.jobCreator, deal.jobCreator);
        assertEq(retrievedDeal.resourceProvider, deal.resourceProvider);
        assertEq(retrievedDeal.moduleCreator, deal.moduleCreator);
        assertEq(retrievedDeal.solver, deal.solver);
        assertEq(retrievedDeal.jobOfferCID, deal.jobOfferCID);
        assertEq(retrievedDeal.resourceOfferCID, deal.resourceOfferCID);
        assertEq(uint256(retrievedDeal.status), uint256(deal.status));
        assertEq(retrievedDeal.timestamp, deal.timestamp);
    }

    function test_ChangeDealStatus() public {
        // First save a deal
        vm.startPrank(CONTROLLER);

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });

        lilypadStorage.saveDeal("deal1", deal);

        // Change status
        vm.expectEmit(true, true, true, true);
        emit DealStatusChanged("deal1", SharedStructs.DealStatusEnum.DealCompleted);

        bool success = lilypadStorage.changeDealStatus("deal1", SharedStructs.DealStatusEnum.DealCompleted);
        assertTrue(success);

        SharedStructs.Deal memory updatedDeal = lilypadStorage.getDeal("deal1");
        assertEq(uint256(updatedDeal.status), uint256(SharedStructs.DealStatusEnum.DealCompleted));
    }

    // Result Tests
    function test_SaveAndGetResult() public {
        vm.startPrank(CONTROLLER);

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        vm.expectEmit(true, true, true, true);
        emit ResultSaved("result1", "deal1");

        bool success = lilypadStorage.saveResult("result1", result);
        assertTrue(success);

        SharedStructs.Result memory retrievedResult = lilypadStorage.getResult("result1");
        assertEq(retrievedResult.resultId, result.resultId);
        assertEq(retrievedResult.dealId, result.dealId);
        assertEq(retrievedResult.resultCID, result.resultCID);
        assertEq(uint256(retrievedResult.status), uint256(result.status));
        assertEq(retrievedResult.timestamp, result.timestamp);
    }

    function test_ChangeResultStatus() public {
        vm.startPrank(CONTROLLER);

        // First save a result
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        lilypadStorage.saveResult("result1", result);

        // Change status
        vm.expectEmit(true, true, true, true);
        emit ResultStatusChanged("result1", SharedStructs.ResultStatusEnum.ResultsRejected);

        bool success = lilypadStorage.changeResultStatus("result1", SharedStructs.ResultStatusEnum.ResultsRejected);
        assertTrue(success);

        SharedStructs.Result memory updatedResult = lilypadStorage.getResult("result1");
        assertEq(uint256(updatedResult.status), uint256(SharedStructs.ResultStatusEnum.ResultsRejected));
    }

    // Validation Result Tests
    function test_SaveAndGetValidationResult() public {
        vm.startPrank(CONTROLLER);

        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: BOB
        });

        vm.expectEmit(true, true, true, true);
        emit ValidationResultSaved("validation1", "result1", BOB);

        bool success = lilypadStorage.saveValidationResult("validation1", validationResult);
        assertTrue(success);

        SharedStructs.ValidationResult memory retrievedValidation = lilypadStorage.getValidationResult("validation1");
        assertEq(retrievedValidation.validationResultId, validationResult.validationResultId);
        assertEq(retrievedValidation.resultId, validationResult.resultId);
        assertEq(retrievedValidation.validationCID, validationResult.validationCID);
        assertEq(uint256(retrievedValidation.status), uint256(validationResult.status));
        assertEq(retrievedValidation.timestamp, validationResult.timestamp);
        assertEq(retrievedValidation.validator, validationResult.validator);
    }

    function test_ChangeValidationResultStatus() public {
        vm.startPrank(CONTROLLER);

        // First save a validation result
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: BOB
        });

        lilypadStorage.saveValidationResult("validation1", validationResult);

        // Change status
        vm.expectEmit(true, true, true, true);
        emit ValidationResultStatusChanged("validation1", SharedStructs.ValidationResultStatusEnum.ValidationAccepted);

        bool success = lilypadStorage.changeValidationResultStatus(
            "validation1", SharedStructs.ValidationResultStatusEnum.ValidationAccepted
        );
        assertTrue(success);

        SharedStructs.ValidationResult memory updatedValidation = lilypadStorage.getValidationResult("validation1");
        assertEq(
            uint256(updatedValidation.status), uint256(SharedStructs.ValidationResultStatusEnum.ValidationAccepted)
        );
    }

    // Error Tests
    function test_RevertWhen_GettingNonexistentDeal() public {
        vm.expectRevert(abi.encodeWithSignature("LilypadStorage__DealNotFound(string)", "nonexistent"));
        lilypadStorage.getDeal("nonexistent");
    }

    function test_RevertWhen_GettingNonexistentResult() public {
        vm.expectRevert(abi.encodeWithSignature("LilypadStorage__ResultNotFound(string)", "nonexistent"));
        lilypadStorage.getResult("nonexistent");
    }

    function test_RevertWhen_GettingNonexistentValidation() public {
        vm.expectRevert(abi.encodeWithSignature("LilypadStorage__ValidationResultNotFound(string)", "nonexistent"));
        lilypadStorage.getValidationResult("nonexistent");
    }

    function test_RevertWhen_SavingDealWithEmptyID() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyDealId.selector);
        lilypadStorage.saveDeal("", deal);
    }

    function test_RevertWhen_SavingDealWithZeroAddresses() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: address(0),
            resourceProvider: address(0),
            moduleCreator: address(0),
            solver: address(0),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__InvalidJobCreatorAddress.selector);
        lilypadStorage.saveDeal("deal1", deal);
    }

    // Controller Role Tests
    function test_GrantControllerRole() public {
        address newController = address(0x4);

        vm.expectEmit(true, true, true, true);
        emit ControllerRoleGranted(newController, address(this));

        lilypadStorage.grantControllerRole(newController);
        assertTrue(lilypadStorage.hasControllerRole(newController));
    }

    function test_RevokeControllerRole() public {
        address newController = address(0x4);
        lilypadStorage.grantControllerRole(newController);

        vm.expectEmit(true, true, true, true);
        emit ControllerRoleRevoked(newController, address(this));

        lilypadStorage.revokeControllerRole(newController);
        assertFalse(lilypadStorage.hasControllerRole(newController));
    }

    function test_RevertWhen_GrantingControllerRoleToZeroAddress() public {
        vm.expectRevert(LilypadStorage.LilypadStorage__ZeroAddressNotAllowed.selector);
        lilypadStorage.grantControllerRole(address(0));
    }

    function test_RevertWhen_RevokingControllerRoleFromZeroAddress() public {
        vm.expectRevert(LilypadStorage.LilypadStorage__ZeroAddressNotAllowed.selector);
        lilypadStorage.revokeControllerRole(address(0));
    }

    function test_RevertWhen_RevokingNonExistentControllerRole() public {
        vm.expectRevert(LilypadStorage.LilypadStorage__RoleNotFound.selector);
        lilypadStorage.revokeControllerRole(address(0x4));
    }

    function test_RevertWhen_RevokingOwnControllerRole() public {
        vm.expectRevert(LilypadStorage.LilypadStorage__CannotRevokeOwnRole.selector);
        lilypadStorage.revokeControllerRole(address(this));
    }

    // Status Check Tests
    function test_CheckDealStatus() public {
        vm.startPrank(CONTROLLER);

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });

        lilypadStorage.saveDeal("deal1", deal);
        assertEq(uint256(lilypadStorage.checkDealStatus("deal1")), uint256(SharedStructs.DealStatusEnum.DealAgreed));
    }

    function test_CheckValidationStatus() public {
        vm.startPrank(CONTROLLER);

        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: BOB
        });

        lilypadStorage.saveValidationResult("validation1", validationResult);
        assertEq(
            uint256(lilypadStorage.checkValidationResultStatus("validation1")),
            uint256(SharedStructs.ValidationResultStatusEnum.ValidationPending)
        );
    }

    function test_CheckResultStatus() public {
        vm.startPrank(CONTROLLER);

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        lilypadStorage.saveResult("result1", result);
        assertEq(
            uint256(lilypadStorage.checkResultStatus("result1")),
            uint256(SharedStructs.ResultStatusEnum.ResultsAccepted)
        );
    }

    // Additional Error Cases
    function test_RevertWhen_NonControllerChangesResultStatus() public {
        vm.startPrank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, ALICE, SharedStructs.CONTROLLER_ROLE
            )
        );
        lilypadStorage.changeResultStatus("result1", SharedStructs.ResultStatusEnum.ResultsRejected);
    }

    function test_RevertWhen_NonControllerChangesValidationResultStatus() public {
        vm.startPrank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, ALICE, SharedStructs.CONTROLLER_ROLE
            )
        );
        lilypadStorage.changeValidationResultStatus(
            "validation1", SharedStructs.ValidationResultStatusEnum.ValidationAccepted
        );
    }

    function test_RevertWhen_NonControllerChangesDealStatus() public {
        vm.startPrank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, ALICE, SharedStructs.CONTROLLER_ROLE
            )
        );
        lilypadStorage.changeDealStatus("deal1", SharedStructs.DealStatusEnum.DealCompleted);
    }

    function test_RevertWhen_SavingResultWithEmptyDealId() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyDealId.selector);
        lilypadStorage.saveResult("result1", result);
    }

    function test_RevertWhen_SavingResultWithEmptyResultCID() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyCID.selector);
        lilypadStorage.saveResult("result1", result);
    }

    function test_RevertWhen_SavingValidationWithEmptyResultId() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: BOB
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyResultId.selector);
        lilypadStorage.saveValidationResult("validation1", validationResult);
    }

    function test_RevertWhen_SavingValidationWithEmptyValidationCID() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: BOB
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyCID.selector);
        lilypadStorage.saveValidationResult("validation1", validationResult);
    }

    function test_RevertWhen_SavingValidationWithZeroValidator() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: address(0)
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__InvalidValidatorAddress.selector);
        lilypadStorage.saveValidationResult("validation1", validationResult);
    }

    function test_RevertWhen_SavingDealWithSameJobCreatorAndResourceProvider() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: ALICE,
            moduleCreator: CHARLIE,
            solver: DAVE,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__SameAddressNotAllowed.selector);
        lilypadStorage.saveDeal("deal1", deal);
    }

    // Add these fuzz tests after the existing tests

    function testFuzz_SaveAndGetDeal(
        uint8 dealIdSeed,
        address jobCreator,
        address resourceProvider,
        address moduleCreator,
        address solver,
        uint8 jobOfferSeed,
        uint8 resourceOfferSeed
    ) public {
        // Create simple string IDs using ASCII characters
        string memory dealId = string(abi.encodePacked("deal_", uint8(dealIdSeed % 26 + 65)));
        string memory jobOfferCID = string(abi.encodePacked("job_", uint8(jobOfferSeed % 26 + 65)));
        string memory resourceOfferCID = string(abi.encodePacked("res_", uint8(resourceOfferSeed % 26 + 65)));

        // Ensure valid addresses
        vm.assume(jobCreator != address(0));
        vm.assume(resourceProvider != address(0));
        vm.assume(jobCreator != resourceProvider);
        vm.assume(moduleCreator != address(0));
        vm.assume(solver != address(0));

        vm.startPrank(CONTROLLER);

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: jobCreator,
            resourceProvider: resourceProvider,
            moduleCreator: moduleCreator,
            solver: solver,
            jobOfferCID: jobOfferCID,
            resourceOfferCID: resourceOfferCID,
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: 0, // Will be set by the contract
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });

        vm.expectEmit(true, true, true, true);
        emit DealSaved(dealId, jobCreator, resourceProvider);

        lilypadStorage.saveDeal(dealId, deal);
        SharedStructs.Deal memory retrievedDeal = lilypadStorage.getDeal(dealId);

        assertEq(retrievedDeal.dealId, deal.dealId);
        assertEq(retrievedDeal.jobCreator, deal.jobCreator);
        assertEq(retrievedDeal.resourceProvider, deal.resourceProvider);
        assertEq(retrievedDeal.moduleCreator, deal.moduleCreator);
        assertEq(retrievedDeal.solver, deal.solver);
        assertEq(retrievedDeal.jobOfferCID, deal.jobOfferCID);
        assertEq(retrievedDeal.resourceOfferCID, deal.resourceOfferCID);
        assertEq(retrievedDeal.timestamp, block.timestamp);
        assertEq(retrievedDeal.paymentStructure.jobCreatorSolverFee, deal.paymentStructure.jobCreatorSolverFee);
        assertEq(
            retrievedDeal.paymentStructure.resourceProviderSolverFee, deal.paymentStructure.resourceProviderSolverFee
        );
        assertEq(retrievedDeal.paymentStructure.networkCongestionFee, deal.paymentStructure.networkCongestionFee);
        assertEq(retrievedDeal.paymentStructure.moduleCreatorFee, deal.paymentStructure.moduleCreatorFee);
        assertEq(retrievedDeal.paymentStructure.priceOfJobWithoutFees, deal.paymentStructure.priceOfJobWithoutFees);
    }

    function testFuzz_SaveAndGetResult(uint8 resultIdSeed, uint8 dealIdSeed, uint8 resultCIDSeed) public {
        string memory resultId = string(abi.encodePacked("result_", uint8(resultIdSeed % 26 + 65)));
        string memory dealId = string(abi.encodePacked("deal_", uint8(dealIdSeed % 26 + 65)));
        string memory resultCID = string(abi.encodePacked("cid_", uint8(resultCIDSeed % 26 + 65)));

        vm.startPrank(CONTROLLER);

        // Create prerequisite deal
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: address(0x1),
            resourceProvider: address(0x2),
            moduleCreator: address(0x3),
            solver: address(0x4),
            jobOfferCID: "jobOfferCID",
            resourceOfferCID: "resourceOfferCID",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: 0, // Will be set by the contract
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });
        lilypadStorage.saveDeal(dealId, deal);

        // Create and save result
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: resultCID,
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: 0 // Will be set by the contract
        });

        lilypadStorage.saveResult(resultId, result);
        SharedStructs.Result memory retrievedResult = lilypadStorage.getResult(resultId);

        assertEq(retrievedResult.resultId, result.resultId);
        assertEq(retrievedResult.dealId, result.dealId);
        assertEq(retrievedResult.resultCID, result.resultCID);
        assertEq(retrievedResult.timestamp, block.timestamp);
    }

    function testFuzz_SaveAndGetValidationResult(
        uint8 validationResultIdSeed,
        uint8 resultIdSeed,
        uint8 validationCIDSeed,
        address validator
    ) public {
        vm.assume(validator != address(0));

        string memory validationResultId =
            string(abi.encodePacked("validation_", uint8(validationResultIdSeed % 26 + 65)));
        string memory resultId = string(abi.encodePacked("result_", uint8(resultIdSeed % 26 + 65)));
        string memory validationCID = string(abi.encodePacked("cid_", uint8(validationCIDSeed % 26 + 65)));

        vm.startPrank(CONTROLLER);

        // Create prerequisite deal
        string memory dealId = "deal_A"; // Fixed ID for prerequisite
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: address(0x1),
            resourceProvider: address(0x2),
            moduleCreator: address(0x3),
            solver: address(0x4),
            jobOfferCID: "job_A",
            resourceOfferCID: "res_A",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: 0, // Will be set by the contract
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });
        lilypadStorage.saveDeal(dealId, deal);

        // Create prerequisite result
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: "cid_A",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: 0 // Will be set by the contract
        });
        lilypadStorage.saveResult(resultId, result);

        // Create validation result
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: validationResultId,
            resultId: resultId,
            validationCID: validationCID,
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: 0, // Will be set by the contract
            validator: validator
        });

        lilypadStorage.saveValidationResult(validationResultId, validationResult);
        SharedStructs.ValidationResult memory retrievedValidation =
            lilypadStorage.getValidationResult(validationResultId);

        assertEq(retrievedValidation.validationResultId, validationResult.validationResultId);
        assertEq(retrievedValidation.resultId, validationResult.resultId);
        assertEq(retrievedValidation.validationCID, validationResult.validationCID);
        assertEq(retrievedValidation.validator, validationResult.validator);
        assertEq(retrievedValidation.timestamp, block.timestamp);
    }

    function test_RevertWhen_SavingResultWithEmptyResultId() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyResultId.selector);
        lilypadStorage.saveResult("", result);
    }

    function test_RevertWhen_SavingValidationWithEmptyValidationId() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validationResult = SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: BOB
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__EmptyValidationResultId.selector);
        lilypadStorage.saveValidationResult("", validationResult);
    }

    function test_RevertWhen_SavingDealWithZeroResourceProvider() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: address(0),
            moduleCreator: address(0x3),
            solver: address(0x4),
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealAgreed,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 0,
                resourceProviderSolverFee: 0,
                networkCongestionFee: 0,
                moduleCreatorFee: 0,
                priceOfJobWithoutFees: 0
            })
        });
        vm.expectRevert(LilypadStorage.LilypadStorage__InvalidResourceProviderAddress.selector);
        lilypadStorage.saveDeal("deal1", deal);
    }
}
