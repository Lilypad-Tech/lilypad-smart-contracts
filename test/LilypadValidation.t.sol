// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {LilypadValidation} from "../src/LilypadValidation.sol";
import {LilypadStorage} from "../src/LilypadStorage.sol";
import {LilypadUser} from "../src/LilypadUser.sol";
import {SharedStructs} from "../src/SharedStructs.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LilypadValidationTest is Test {
    LilypadValidation public lilypadValidation;
    LilypadStorage public lilypadStorage;
    LilypadUser public lilypadUser;

    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant CHARLIE = address(0x3);
    address public constant VALIDATOR = address(0x4);
    address public constant CONTROLLER = address(0x5);

    // Events
    event ValidationRequested(string dealId, string resultId, address jobCreator);
    event ValidationProcessed(string validationResultId, SharedStructs.ValidationResultStatusEnum status);
    event StorageContractSet(address storageContract);
    event UserContractSet(address userContract);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    function setUp() public {
        // Deploy and initialize storage contract
        LilypadStorage storageImplementation = new LilypadStorage();
        bytes memory storageInitData = abi.encodeWithSelector(LilypadStorage.initialize.selector);
        ERC1967Proxy storageProxy = new ERC1967Proxy(address(storageImplementation), storageInitData);
        lilypadStorage = LilypadStorage(address(storageProxy));

        // Deploy and initialize user contract
        LilypadUser userImplementation = new LilypadUser();
        bytes memory userInitData = abi.encodeWithSelector(LilypadUser.initialize.selector);
        ERC1967Proxy userProxy = new ERC1967Proxy(address(userImplementation), userInitData);
        lilypadUser = LilypadUser(address(userProxy));

        // Deploy and initialize validation contract
        LilypadValidation implementation = new LilypadValidation();
        bytes memory validationInitData =
            abi.encodeWithSelector(LilypadValidation.initialize.selector, address(lilypadStorage), address(lilypadUser));
        ERC1967Proxy validationProxy = new ERC1967Proxy(address(implementation), validationInitData);
        lilypadValidation = LilypadValidation(address(validationProxy));

        // Grant controller roles
        lilypadValidation.grantRole(SharedStructs.CONTROLLER_ROLE, CONTROLLER);
        lilypadStorage.grantRole(SharedStructs.CONTROLLER_ROLE, address(lilypadValidation));
        lilypadUser.grantRole(SharedStructs.CONTROLLER_ROLE, address(lilypadValidation));

        // Register a validator
        vm.startPrank(address(lilypadValidation));
        lilypadUser.insertUser(
            VALIDATOR, "validatorMetadata", "https://validator.example.com", SharedStructs.UserType.Validator
        );
        vm.stopPrank();
    }

    // Version Tests
    function test_InitialVersion() public view {
        assertEq(lilypadValidation.version(), "1.0.0");
    }

    function test_GetVersion() public view {
        assertEq(lilypadValidation.getVersion(), "1.0.0");
    }

    // Contract Setup Tests
    function test_RevertWhen_InitializingWithZeroAddressStorage() public {
        LilypadValidation implementation = new LilypadValidation();
        bytes memory validationInitData =
            abi.encodeWithSelector(LilypadValidation.initialize.selector, address(0), address(0x1));
        vm.expectRevert(LilypadValidation.LilypadValidation__ZeroAddressNotAllowed.selector);
        new ERC1967Proxy(address(implementation), validationInitData);
    }

    function test_RevertWhen_InitializingWithZeroAddressUser() public {
        LilypadValidation implementation = new LilypadValidation();
        bytes memory validationInitData =
            abi.encodeWithSelector(LilypadValidation.initialize.selector, address(0x1), address(0));
        vm.expectRevert(LilypadValidation.LilypadValidation__ZeroAddressNotAllowed.selector);
        new ERC1967Proxy(address(implementation), validationInitData);
    }

    function test_InitializeWithValidAddresses() public {
        LilypadValidation implementation = new LilypadValidation();
        address testStorage = address(0x123);
        address testUser = address(0x456);

        bytes memory validationInitData =
            abi.encodeWithSelector(LilypadValidation.initialize.selector, testStorage, testUser);

        vm.expectEmit(true, true, true, true);
        emit StorageContractSet(testStorage);
        vm.expectEmit(true, true, true, true);
        emit UserContractSet(testUser);

        ERC1967Proxy validationProxy = new ERC1967Proxy(address(implementation), validationInitData);
        LilypadValidation validation = LilypadValidation(address(validationProxy));

        assertEq(address(validation.lilypadStorage()), testStorage);
        assertEq(address(validation.lilypadUser()), testUser);
    }

    // Role Management Tests
    function test_RevertWhen_NonAdminGrantsControllerRole() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        lilypadValidation.grantRole(SharedStructs.CONTROLLER_ROLE, BOB);
    }

    function test_GrantControllerRole() public {
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(SharedStructs.CONTROLLER_ROLE, ALICE, address(this));
        lilypadValidation.grantRole(SharedStructs.CONTROLLER_ROLE, ALICE);
        assertTrue(lilypadValidation.hasRole(SharedStructs.CONTROLLER_ROLE, ALICE));
    }

    // Validation Request Tests
    function test_RevertWhen_NonControllerRequestsValidation() public {
        vm.startPrank(ALICE);
        SharedStructs.Deal memory deal = _createDeal();
        SharedStructs.Result memory result = _createResult();
        SharedStructs.ValidationResult memory validation = _createValidation();

        vm.expectRevert();
        lilypadValidation.requestValidation(deal, result, validation);
    }

    function test_RevertWhen_RequestingValidationWithInvalidDeal() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.Deal memory deal = _createDeal();
        deal.dealId = "";
        SharedStructs.Result memory result = _createResult();
        SharedStructs.ValidationResult memory validation = _createValidation();

        vm.expectRevert(LilypadValidation.LilypadValidation__InvalidDeal.selector);
        lilypadValidation.requestValidation(deal, result, validation);
    }

    function test_SuccessfulValidationRequest() public {
        // First save a deal and result
        SharedStructs.Deal memory deal = _createDeal();
        SharedStructs.Result memory result = _createResult();
        SharedStructs.ValidationResult memory validation = _createValidation();

        vm.startPrank(address(lilypadValidation));
        lilypadStorage.saveDeal(deal.dealId, deal);
        lilypadStorage.saveResult(result.resultId, result);
        vm.stopPrank();

        vm.startPrank(CONTROLLER);
        vm.expectEmit(true, true, true, true);
        emit ValidationRequested(deal.dealId, result.resultId, deal.jobCreator);

        bool success = lilypadValidation.requestValidation(deal, result, validation);
        assertTrue(success);
        vm.stopPrank();
    }

    // Validation Processing Tests
    function test_RevertWhen_ProcessingInvalidValidation() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validation = _createValidation();
        validation.validationResultId = "";

        vm.expectRevert(LilypadValidation.LilypadValidation__InvalidValidation.selector);
        lilypadValidation.processValidation(validation);
    }

    function test_RevertWhen_ProcessingValidationWithNonValidator() public {
        // First register ALICE as a JobCreator (non-validator)
        vm.startPrank(address(lilypadValidation));
        lilypadUser.insertUser(ALICE, "metadata1", "http://example.com", SharedStructs.UserType.JobCreator);
        vm.stopPrank();

        // Now test validation processing
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validation = _createValidation();
        validation.validator = ALICE; // ALICE exists but is not a validator

        vm.expectRevert(LilypadValidation.LilypadValidation__NotValidator.selector);
        lilypadValidation.processValidation(validation);
        vm.stopPrank();
    }

    function test_SuccessfulValidationProcessing() public {
        vm.startPrank(CONTROLLER);
        SharedStructs.ValidationResult memory validation = _createValidation();

        vm.expectEmit(true, true, true, true);
        emit ValidationProcessed(validation.validationResultId, validation.status);

        bool success = lilypadValidation.processValidation(validation);
        assertTrue(success);
    }

    // Fuzz Tests
    function testFuzz_RequestValidation(
        string memory dealId,
        string memory resultId,
        string memory validationResultId,
        address jobCreator,
        address resourceProvider
    ) public {
        vm.assume(bytes(dealId).length > 0);
        vm.assume(bytes(resultId).length > 0);
        vm.assume(bytes(validationResultId).length > 0);
        vm.assume(jobCreator != address(0));
        vm.assume(resourceProvider != address(0));
        vm.assume(jobCreator != resourceProvider); // Ensure addresses are different

        SharedStructs.Deal memory deal = SharedStructs.Deal({
            dealId: dealId,
            jobCreator: jobCreator,
            resourceProvider: resourceProvider,
            moduleCreator: CHARLIE,
            solver: VALIDATOR,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 100,
                resourceProviderSolverFee: 100,
                networkCongestionFee: 100,
                moduleCreatorFee: 100,
                priceOfJobWithoutFees: 100
            })
        });

        SharedStructs.Result memory result = SharedStructs.Result({
            resultId: resultId,
            dealId: dealId,
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });

        SharedStructs.ValidationResult memory validation = SharedStructs.ValidationResult({
            validationResultId: validationResultId,
            resultId: resultId,
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: VALIDATOR
        });

        // First save the deal and result
        vm.startPrank(address(lilypadValidation));
        lilypadStorage.saveDeal(dealId, deal);
        lilypadStorage.saveResult(resultId, result);
        vm.stopPrank();

        // Then request validation
        vm.startPrank(CONTROLLER);
        bool success = lilypadValidation.requestValidation(deal, result, validation);
        assertTrue(success);
        vm.stopPrank();
    }

    // Helper functions
    function _createDeal() internal view returns (SharedStructs.Deal memory) {
        return SharedStructs.Deal({
            dealId: "deal1",
            jobCreator: ALICE,
            resourceProvider: BOB,
            moduleCreator: CHARLIE,
            solver: VALIDATOR,
            jobOfferCID: "jobCID1",
            resourceOfferCID: "resourceCID1",
            status: SharedStructs.DealStatusEnum.DealCreated,
            timestamp: block.timestamp,
            paymentStructure: SharedStructs.DealPaymentStructure({
                jobCreatorSolverFee: 100,
                resourceProviderSolverFee: 100,
                networkCongestionFee: 100,
                moduleCreatorFee: 100,
                priceOfJobWithoutFees: 100
            })
        });
    }

    function _createResult() internal view returns (SharedStructs.Result memory) {
        return SharedStructs.Result({
            resultId: "result1",
            dealId: "deal1",
            resultCID: "resultCID1",
            status: SharedStructs.ResultStatusEnum.ResultsAccepted,
            timestamp: block.timestamp
        });
    }

    function _createValidation() internal view returns (SharedStructs.ValidationResult memory) {
        return SharedStructs.ValidationResult({
            validationResultId: "validation1",
            resultId: "result1",
            validationCID: "validationCID1",
            status: SharedStructs.ValidationResultStatusEnum.ValidationPending,
            timestamp: block.timestamp,
            validator: VALIDATOR
        });
    }
}
