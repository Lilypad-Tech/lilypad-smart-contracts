// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILilypadStorage} from "./interfaces/ILilypadStorage.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadStorage
 * @dev Implementation of storage contract for Lilypad platform
 */
contract LilypadStorage is Initializable, ILilypadStorage, AccessControlUpgradeable {
    // Version
    string public version;

    // Custom Errors
    error LilypadStorage__ZeroAddressNotAllowed();

    error LilypadStorage__DealNotFound(string dealId);
    error LilypadStorage__ValidationResultNotFound(string validationResultId);
    error LilypadStorage__ResultNotFound(string resultId);

    error LilypadStorage__EmptyCID(); // For empty CID checks

    error LilypadStorage__InvalidAddress(); // For all invalid address checks
    error LilypadStorage__SameAddressNotAllowed(); // For job creator/provider check

    error LilypadStorage__EmptyResultId();
    error LilypadStorage__EmptyDealId();
    error LilypadStorage__EmptyValidationResultId();
    error LilypadStorage__InvalidJobCreatorAddress();
    error LilypadStorage__InvalidResourceProviderAddress();
    error LilypadStorage__InvalidValidatorAddress();
    error LilypadStorage__InvalidModuleCreatorAddress();
    error LilypadStorage__InvalidSolverAddress();

    // Events for important state changes
    event LilypadStorage__DealStatusChanged(string indexed dealId, SharedStructs.DealStatusEnum status);
    event LilypadStorage__ValidationResultStatusChanged(
        string indexed validationResultId, SharedStructs.ValidationResultStatusEnum status
    );
    event LilypadStorage__ResultStatusChanged(string indexed resultId, SharedStructs.ResultStatusEnum status);
    event LilypadStorage__DealSaved(
        string indexed dealId, address indexed jobCreator, address indexed resourceProvider
    );
    event LilypadStorage__ResultSaved(string indexed resultId, string dealId);
    event LilypadStorage__ValidationResultSaved(string indexed validationResultId, string resultId, address validator);

    // Mappings to store deal, validationResult, and result data
    mapping(string => SharedStructs.Deal) private deals;
    mapping(string => SharedStructs.ValidationResult) private validationResults;
    mapping(string => SharedStructs.Result) private results;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial controller
     * @notice
     * - Initializes the AccessControl contract
     * - Grants DEFAULT_ADMIN_ROLE to the deployer
     * - Grants CONTROLLER_ROLE to the deployer
     * - Sets initial version to "1.0.0"
     */
    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
        version = "1.0.0";
    }

    /**
     * @dev Returns the current version of the contract
     * @notice
     * - Returns the semantic version string of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    /**
     * @dev Changes the status of a deal object
     * @notice
     * - Only accounts with the CONTROLLER_ROLE can call this function
     * - Reverts if dealId is empty
     * - Reverts if deal does not exist
     * - Emits a LilypadStorage__DealStatusChanged event upon successful status update
     */
    function changeDealStatus(string memory dealId, SharedStructs.DealStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        SharedStructs.Deal storage deal = deals[dealId];
        if (deal.timestamp == 0) revert LilypadStorage__DealNotFound(dealId);
        deal.status = status;
        emit LilypadStorage__DealStatusChanged(dealId, status);
        return true;
    }

    /**
     * @dev Changes the status of a validation result
     * @notice
     * - Only accounts with the CONTROLLER_ROLE can call this function
     * - Reverts if validationResultId is empty
     * - Reverts if validation result does not exist
     * - Emits a LilypadStorage__ValidationResultStatusChanged event upon successful status update
     */
    function changeValidationResultStatus(
        string memory validationResultId,
        SharedStructs.ValidationResultStatusEnum status
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (bytes(validationResultId).length == 0) {
            revert LilypadStorage__EmptyValidationResultId();
        }
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];
        if (validationResult.timestamp == 0) revert LilypadStorage__ValidationResultNotFound(validationResultId);
        validationResult.status = status;
        emit LilypadStorage__ValidationResultStatusChanged(validationResultId, status);
        return true;
    }

    /**
     * @dev Changes the status of a result object
     * @notice
     * - Only accounts with the CONTROLLER_ROLE can call this function
     * - Reverts if resultId is empty
     * - Reverts if result does not exist
     * - Emits a LilypadStorage__ResultStatusChanged event upon successful status update
     */
    function changeResultStatus(string memory resultId, SharedStructs.ResultStatusEnum status)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        SharedStructs.Result storage result = results[resultId];
        if (result.timestamp == 0) revert LilypadStorage__ResultNotFound(resultId);
        result.status = status;
        emit LilypadStorage__ResultStatusChanged(resultId, status);
        return true;
    }

    /**
     * @dev Returns the Result object associated with the resultId
     * @notice
     * - View function that returns a Result struct
     * - Reverts if resultId is empty
     * - Reverts if result does not exist
     */
    function getResult(string memory resultId)
        external
        view
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (SharedStructs.Result memory)
    {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        SharedStructs.Result memory result = results[resultId];
        if (result.timestamp == 0) revert LilypadStorage__ResultNotFound(resultId);
        return result;
    }

    /**
     * @dev Saves a Result Object
     * @notice
     * - Only accounts with the CONTROLLER_ROLE can call this function
     * - Reverts if resultId is empty
     * - Reverts if result.dealId is empty
     * - Reverts if result.resultCID is empty
     * - Sets timestamp to current block timestamp
     * - Emits a LilypadStorage__ResultSaved event upon successful save
     */
    function saveResult(string memory resultId, SharedStructs.Result memory result)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        if (bytes(result.dealId).length == 0) {
            revert LilypadStorage__EmptyDealId();
        }
        if (bytes(result.resultCID).length == 0) {
            revert LilypadStorage__EmptyCID();
        }
        result.timestamp = block.timestamp;
        results[resultId] = result;
        emit LilypadStorage__ResultSaved(resultId, result.dealId);
        return true;
    }

    /**
     * @dev Returns the Deal object associated with the dealId
     * @notice
     * - View function that returns a Deal struct
     * - Reverts if dealId is empty
     * - Reverts if deal does not exist
     */
    function getDeal(string memory dealId)
        external
        view
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (SharedStructs.Deal memory)
    {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        SharedStructs.Deal memory deal = deals[dealId];
        if (deal.timestamp == 0) revert LilypadStorage__DealNotFound(dealId);
        return deal;
    }

    /**
     * @dev Saves a Deal Object with a status
     * @notice
     * - Only accounts with the CONTROLLER_ROLE can call this function
     * - Reverts if dealId is empty
     * - Reverts if jobCreator address is zero
     * - Reverts if resourceProvider address is zero
     * - Reverts if moduleCreator address is zero
     * - Reverts if solver address is zero
     * - Reverts if jobCreator and resourceProvider are the same address
     * - Sets timestamp to current block timestamp
     * - Emits a LilypadStorage__DealSaved event upon successful save
     */
    function saveDeal(string memory dealId, SharedStructs.Deal memory deal)
        external
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (bool)
    {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        if (deal.jobCreator == address(0)) revert LilypadStorage__InvalidJobCreatorAddress();
        if (deal.resourceProvider == address(0)) revert LilypadStorage__InvalidResourceProviderAddress();
        if (deal.moduleCreator == address(0)) revert LilypadStorage__InvalidModuleCreatorAddress();
        if (deal.solver == address(0)) revert LilypadStorage__InvalidSolverAddress();
        if (deal.jobCreator == deal.resourceProvider) revert LilypadStorage__SameAddressNotAllowed();

        deal.timestamp = block.timestamp;
        deals[dealId] = deal;
        emit LilypadStorage__DealSaved(dealId, deal.jobCreator, deal.resourceProvider);
        return true;
    }

    /**
     * @dev Gets a validation result object
     * @notice
     * - View function that returns a ValidationResult struct
     * - Reverts if validationResultId is empty
     * - Reverts if validation result does not exist
     */
    function getValidationResult(string memory validationResultId)
        external
        view
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (SharedStructs.ValidationResult memory)
    {
        if (bytes(validationResultId).length == 0) {
            revert LilypadStorage__EmptyValidationResultId();
        }
        SharedStructs.ValidationResult memory validationResult = validationResults[validationResultId];

        if (validationResult.timestamp == 0) revert LilypadStorage__ValidationResultNotFound(validationResultId);

        return validationResult;
    }

    /**
     * @dev Saves a validation result object with a status
     * @notice
     * - Only accounts with the CONTROLLER_ROLE can call this function
     * - Reverts if validationResultId is empty
     * - Reverts if validationResult.resultId is empty
     * - Reverts if validationResult.validationCID is empty
     * - Reverts if validator address is zero
     * - Sets timestamp to current block timestamp
     * - Emits a LilypadStorage__ValidationResultSaved event upon successful save
     */
    function saveValidationResult(
        string memory validationResultId,
        SharedStructs.ValidationResult memory validationResult
    ) external onlyRole(SharedStructs.CONTROLLER_ROLE) returns (bool) {
        if (bytes(validationResultId).length == 0) {
            revert LilypadStorage__EmptyValidationResultId();
        }
        if (bytes(validationResult.resultId).length == 0) {
            revert LilypadStorage__EmptyResultId();
        }
        if (bytes(validationResult.validationCID).length == 0) {
            revert LilypadStorage__EmptyCID();
        }
        if (validationResult.validator == address(0)) {
            revert LilypadStorage__InvalidValidatorAddress();
        }
        validationResult.timestamp = block.timestamp;
        validationResults[validationResultId] = validationResult;
        emit LilypadStorage__ValidationResultSaved(
            validationResultId, validationResult.resultId, validationResult.validator
        );
        return true;
    }

    /**
     * @dev Check the status of a deal
     * @notice
     * - View function that returns a DealStatusEnum
     * - Reverts if dealId is empty
     * - Reverts if deal does not exist
     */
    function checkDealStatus(string memory dealId)
        external
        view
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (SharedStructs.DealStatusEnum)
    {
        if (bytes(dealId).length == 0) revert LilypadStorage__EmptyDealId();
        SharedStructs.Deal storage deal = deals[dealId];
        if (deal.timestamp == 0) revert LilypadStorage__DealNotFound(dealId);
        return deal.status;
    }

    /**
     * @dev Check the status of a validation result
     * @notice
     * - View function that returns a ValidationResultStatusEnum
     * - Reverts if validationResultId is empty
     * - Reverts if validation result does not exist
     */
    function checkValidationResultStatus(string memory validationResultId)
        external
        view
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (SharedStructs.ValidationResultStatusEnum)
    {
        if (bytes(validationResultId).length == 0) {
            revert LilypadStorage__EmptyValidationResultId();
        }
        SharedStructs.ValidationResult storage validationResult = validationResults[validationResultId];

        if (validationResult.timestamp == 0) revert LilypadStorage__ValidationResultNotFound(validationResultId);

        return validationResult.status;
    }

    /**
     * @dev Check the status of a result
     * @notice
     * - View function that returns a ResultStatusEnum
     * - Reverts if resultId is empty
     * - Reverts if result does not exist
     */
    function checkResultStatus(string memory resultId)
        external
        view
        onlyRole(SharedStructs.CONTROLLER_ROLE)
        returns (SharedStructs.ResultStatusEnum)
    {
        if (bytes(resultId).length == 0) revert LilypadStorage__EmptyResultId();
        SharedStructs.Result storage result = results[resultId];
        if (result.timestamp == 0) revert LilypadStorage__ResultNotFound(resultId);
        return result.status;
    }
}
