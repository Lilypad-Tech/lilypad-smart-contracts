// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {ILilypadModuleDirectory} from "./interfaces/ILilypadModuleDirectory.sol";
import {LilypadUser} from "./LilypadUser.sol";
import {SharedStructs} from "./SharedStructs.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LilypadModuleDirectory is ILilypadModuleDirectory, Initializable, AccessControlUpgradeable {
    // Version
    string public version;

    LilypadUser public lilypadUser;

    // Custom Errors
    error LilypadModuleDirectory__NotController();
    error LilypadModuleDirectory__ModuleNotFound();
    error LilypadModuleDirectory__NotModuleOwner();
    error LilypadModuleDirectory__InvalidAddress();
    error LilypadModuleDirectory__EmptyModuleName();
    error LilypadModuleDirectory__ModuleAlreadyExists();
    error LilypadModuleDirectory__SameOwnerAddress();
    error LilypadModuleDirectory__TransferNotApproved();
    error LilypadModuleDirectory__EmptyModuleUrl();
    error LilypadModuleDirectory__ZeroAddressNotAllowed();
    error LilypadModuleDirectory__RoleAlreadyAssigned();
    error LilypadModuleDirectory__RoleNotFound();
    error LilypadModuleDirectory__CannotRevokeOwnRole();
    error LilypadModuleDirectory__InvalidAddressForLilypadUser();
    error LilypadModuleDirectory__ModuleCreatorAlreadyExists(address moduleCreator);

    // Events
    event LilypadModuleDirectory__ModuleRegistered(address indexed owner, string moduleName, string moduleUrl);

    event LilypadModuleDirectory__ModuleNameUpdated(address indexed owner, string oldModuleName, string newModuleName);

    event LilypadModuleDirectory__ModuleUrlUpdated(address indexed owner, string moduleName, string newModuleUrl);

    event LilypadModuleDirectory__ModuleTransferApproved(
        address indexed owner, address indexed purchaser, string moduleName, string moduleUrl
    );

    event LilypadModuleDirectory__ModuleTransferred(
        address indexed newOwner, address indexed previousOwner, string moduleName, string moduleUrl
    );

    event LilypadModuleDirectory__ModuleTransferRevoked(
        address indexed owner, address indexed revokedFrom, string moduleName
    );

    event LilypadModuleDirectory__ControllerRoleGranted(address indexed account, address indexed sender);

    event LilypadModuleDirectory__ControllerRoleRevoked(address indexed account, address indexed sender);

    event LilypadModuleDirectory__ModuleCreatorRegistered(address indexed moduleCreator);

    // Mapping from owner address to array of modules
    mapping(address => SharedStructs.Module[]) private _ownedModules;

    // Mapping to track module name existence for an owner
    mapping(address => mapping(string => bool)) private _moduleExists;

    // Mapping for transfer approvals (owner => moduleName => approved address)
    mapping(address => mapping(string => address)) private _transferApprovals;

    // Mapping to track module indices for O(1) lookups
    mapping(address => mapping(string => uint256)) private _moduleIndices;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lilypadUser) public initializer {
        __AccessControl_init();
        if (_lilypadUser == address(0)) {
            revert LilypadModuleDirectory__InvalidAddressForLilypadUser();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.CONTROLLER_ROLE, msg.sender);
        version = "1.0.0";
        lilypadUser = LilypadUser(_lilypadUser);
    }

    /**
     * @dev Returns the current version of the contract
     * @notice
     * - Returns the semantic version string of the contract
     */
    function getVersion() external view returns (string memory) {
        return version;
    }

    modifier onlyController() {
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, msg.sender)) {
            revert LilypadModuleDirectory__NotController();
        }
        _;
    }

    modifier moduleOwnerOnly(address moduleOwner, string memory moduleName) {
        if (!_moduleExists[moduleOwner][moduleName]) {
            revert LilypadModuleDirectory__ModuleNotFound();
        }
        if (msg.sender != moduleOwner) {
            revert LilypadModuleDirectory__NotModuleOwner();
        }
        _;
    }

    /**
     * @dev Registers a module creator
     * @notice
     * - The caller of this function must have the controller role
     */
    function registerModuleCreator(address moduleCreator) external override onlyController returns (bool) {
        if (moduleCreator == address(0)) {
            revert LilypadModuleDirectory__InvalidAddress();
        }
        // check if the user exists in the lilypadUser contract
        bool success = _checkAndInsertModuleCreator(moduleCreator);
        if (!success) {
            revert LilypadModuleDirectory__ModuleCreatorAlreadyExists(moduleCreator);
        }

        return true;
    }

    /**
     * @dev Registers a module for a module creator
     * @notice
     * - The caller of this function must have the controller role
     */
    function registerModuleForCreator(address moduleOwner, string memory moduleName, string memory moduleUrl)
        external
        override
        onlyController
        returns (bool)
    {
        if (moduleOwner == address(0)) {
            revert LilypadModuleDirectory__InvalidAddress();
        }
        if (bytes(moduleName).length == 0) {
            revert LilypadModuleDirectory__EmptyModuleName();
        }
        if (bytes(moduleUrl).length == 0) {
            revert LilypadModuleDirectory__EmptyModuleUrl();
        }
        if (_moduleExists[moduleOwner][moduleName]) {
            revert LilypadModuleDirectory__ModuleAlreadyExists();
        }

        // Check if the module owner already exists, if not, create a new user and register them as a module creator
        _checkAndInsertModuleCreator(moduleOwner);

        SharedStructs.Module memory newModule =
            SharedStructs.Module({moduleOwner: moduleOwner, moduleName: moduleName, moduleUrl: moduleUrl});

        uint256 newIndex = _ownedModules[moduleOwner].length;
        _ownedModules[moduleOwner].push(newModule);
        _moduleExists[moduleOwner][moduleName] = true;
        _moduleIndices[moduleOwner][moduleName] = newIndex;

        emit LilypadModuleDirectory__ModuleRegistered(moduleOwner, moduleName, moduleUrl);

        return true;
    }

    /**
     * @dev Updates the name of a module
     * @notice
     * - The caller of this function must be the owner of the module
     */
    function updateModuleName(address moduleOwner, string memory moduleName, string memory newModuleName)
        external
        override
        moduleOwnerOnly(moduleOwner, moduleName)
        returns (bool)
    {
        if (bytes(newModuleName).length == 0) {
            revert LilypadModuleDirectory__EmptyModuleName();
        }
        if (_moduleExists[moduleOwner][newModuleName]) {
            revert LilypadModuleDirectory__ModuleAlreadyExists();
        }

        uint256 moduleIndex = _moduleIndices[moduleOwner][moduleName];
        SharedStructs.Module[] storage modules = _ownedModules[moduleOwner];

        _moduleExists[moduleOwner][moduleName] = false;
        _moduleExists[moduleOwner][newModuleName] = true;
        delete _moduleIndices[moduleOwner][moduleName];
        _moduleIndices[moduleOwner][newModuleName] = moduleIndex;
        modules[moduleIndex].moduleName = newModuleName;

        emit LilypadModuleDirectory__ModuleNameUpdated(moduleOwner, moduleName, newModuleName);
        return true;
    }

    /**
     * @dev Updates the URL of a module
     * @notice
     * - The caller of this function must be the owner of the module
     */
    function updateModuleUrl(address moduleOwner, string memory moduleName, string memory newModuleUrl)
        external
        override
        moduleOwnerOnly(moduleOwner, moduleName)
        returns (bool)
    {
        if (bytes(newModuleUrl).length == 0) {
            revert LilypadModuleDirectory__EmptyModuleUrl();
        }
        uint256 moduleIndex = _moduleIndices[moduleOwner][moduleName];
        SharedStructs.Module[] storage modules = _ownedModules[moduleOwner];
        modules[moduleIndex].moduleUrl = newModuleUrl;
        emit LilypadModuleDirectory__ModuleUrlUpdated(moduleOwner, moduleName, newModuleUrl);
        return true;
    }

    /**
     * @dev Returns the modules owned by a module owner
     * @notice
     * - The caller of this function must be the owner of the module
     */
    function getOwnedModules(address moduleOwner) external view override returns (SharedStructs.Module[] memory) {
        return _ownedModules[moduleOwner];
    }

    function approveTransfer(address moduleOwner, address newOwner, string memory moduleName, string memory moduleUrl)
        external
        override
        moduleOwnerOnly(moduleOwner, moduleName)
        returns (bool)
    {
        if (newOwner == address(0)) {
            revert LilypadModuleDirectory__InvalidAddress();
        }
        if (newOwner == moduleOwner) {
            revert LilypadModuleDirectory__SameOwnerAddress();
        }
        if (_moduleExists[newOwner][moduleName]) {
            revert LilypadModuleDirectory__ModuleAlreadyExists();
        }

        _transferApprovals[moduleOwner][moduleName] = newOwner;
        emit LilypadModuleDirectory__ModuleTransferApproved(moduleOwner, newOwner, moduleName, moduleUrl);
        return true;
    }

    /**
     * @dev Transfers the ownership of a module
     * @notice
     * - The caller of this function must be the owner of the module
     * - The onwer of this module must have called the approveTransfer function
     */
    function transferModuleOwnership(
        address moduleOwner,
        address newOwner,
        string memory moduleName,
        string memory moduleUrl
    ) external override returns (bool) {
        if (!_moduleExists[moduleOwner][moduleName]) {
            revert LilypadModuleDirectory__ModuleNotFound();
        }
        if (_transferApprovals[moduleOwner][moduleName] != newOwner) {
            revert LilypadModuleDirectory__TransferNotApproved();
        }
        if (_moduleExists[newOwner][moduleName]) {
            revert LilypadModuleDirectory__ModuleAlreadyExists();
        }

        // Get module index and array
        uint256 moduleIndex = _moduleIndices[moduleOwner][moduleName];
        SharedStructs.Module[] storage currentOwnerModules = _ownedModules[moduleOwner];

        // If not the last element, update the index of the swapped module
        if (moduleIndex != currentOwnerModules.length - 1) {
            string memory lastModuleName = currentOwnerModules[currentOwnerModules.length - 1].moduleName;
            _moduleIndices[moduleOwner][lastModuleName] = moduleIndex;
        }

        // Remove module from current owner's array using swap and pop
        currentOwnerModules[moduleIndex] = currentOwnerModules[currentOwnerModules.length - 1];
        currentOwnerModules.pop();

        // Clean up old owner's mappings
        _moduleExists[moduleOwner][moduleName] = false;
        delete _moduleIndices[moduleOwner][moduleName];

        // Add module to new owner
        uint256 newIndex = _ownedModules[newOwner].length;
        SharedStructs.Module memory transferredModule =
            SharedStructs.Module({moduleOwner: newOwner, moduleName: moduleName, moduleUrl: moduleUrl});
        _ownedModules[newOwner].push(transferredModule);
        _moduleExists[newOwner][moduleName] = true;
        _moduleIndices[newOwner][moduleName] = newIndex;

        // Clear transfer approval
        delete _transferApprovals[moduleOwner][moduleName];

        emit LilypadModuleDirectory__ModuleTransferred(newOwner, moduleOwner, moduleName, moduleUrl);
        return true;
    }

    /**
     * @dev Revokes a previously approved transfer for a module
     * @notice
     * - The caller of this function must be the owner of the module
     */
    function revokeTransferApproval(address moduleOwner, string memory moduleName)
        external
        moduleOwnerOnly(moduleOwner, moduleName)
        returns (bool)
    {
        address approvedAddress = _transferApprovals[moduleOwner][moduleName];
        delete _transferApprovals[moduleOwner][moduleName];
        emit LilypadModuleDirectory__ModuleTransferRevoked(moduleOwner, approvedAddress, moduleName);
        return true;
    }

    /**
     * @dev Checks if a transfer is approved for a specific module and purchaser
     * @notice
     * - The caller of this function must be the owner of the module
     */
    function isTransferApproved(address moduleOwner, string memory moduleName, address purchaser)
        external
        view
        override
        returns (bool)
    {
        return _transferApprovals[moduleOwner][moduleName] == purchaser;
    }

    /**
     * @dev Grants the controller role to an account
     * @notice
     * - The caller of this function must have the DEFAULT_ADMIN_ROLE
     */
    function grantControllerRole(address account) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) {
            revert LilypadModuleDirectory__ZeroAddressNotAllowed();
        }
        if (hasRole(SharedStructs.CONTROLLER_ROLE, account)) {
            revert LilypadModuleDirectory__RoleAlreadyAssigned();
        }
        _grantRole(SharedStructs.CONTROLLER_ROLE, account);
        emit LilypadModuleDirectory__ControllerRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revokes the controller role from an account
     * @notice
     * - The caller of this function must have the DEFAULT_ADMIN_ROLE
     */
    function revokeControllerRole(address account) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (account == address(0)) {
            revert LilypadModuleDirectory__ZeroAddressNotAllowed();
        }
        if (!hasRole(SharedStructs.CONTROLLER_ROLE, account)) {
            revert LilypadModuleDirectory__RoleNotFound();
        }
        if (account == msg.sender) revert LilypadModuleDirectory__CannotRevokeOwnRole();

        _revokeRole(SharedStructs.CONTROLLER_ROLE, account);
        emit LilypadModuleDirectory__ControllerRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Checks if an account has the controller role
     * @notice
     * - The caller of this function must be the controller role
     */
    function hasControllerRole(address account) external view override returns (bool) {
        return hasRole(SharedStructs.CONTROLLER_ROLE, account);
    }

    /**
     * @dev Checks if a user exists and if they do, it checks if they hold the ModuleCreator role, if they do not, it assigns it.  If the user does not exist, it creates a new user and registers them as a module creator.
     * @notice
     * - The caller of this function must be the controller role
     */
    function _checkAndInsertModuleCreator(address moduleCreator) private onlyController returns (bool) {
        try lilypadUser.getUser(moduleCreator) {
            // if the user exists and already has the module creator role, return false
            if (lilypadUser.hasRole(moduleCreator, SharedStructs.UserType.ModuleCreator)) {
                return false;
            } else {
                // The user exists but does not hold the ModuleCreator role, so we need to assign it
                lilypadUser.addRole(moduleCreator, SharedStructs.UserType.ModuleCreator);
            }
        } catch {
            // if the user does not exist, create a new user and register them as a module creator, the metadataID and url are purposesly left blank at the outset
            lilypadUser.insertUser(moduleCreator, "", "", SharedStructs.UserType.ModuleCreator);
        }

        emit LilypadModuleDirectory__ModuleCreatorRegistered(moduleCreator);
        return true;
    }
}
