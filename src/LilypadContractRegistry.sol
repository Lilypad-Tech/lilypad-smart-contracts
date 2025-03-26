// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Lilypad Contract Registry
 * @notice This contract is used to register and set the addresses of the Lilypad contracts
 */
contract LilypadContractRegistry is Initializable, AccessControlUpgradeable {
    // Version
    string public version;

    // Addresses
    // NOTE: unless otherwise specified, all addresses are proxy addresses deployed on the L2 Network

    // The l1 token address of the Lilypad Token deployed on L1 Mainnet.  When you retrieve this address, you must look it up on the corresponding L1 Network block explorer.
    address public l1LilypadTokenAddress;

    // The l2 token address of the Lilypad Token
    address public l2LilypadTokenAddress;

    // The lilypad user address
    address public lilypadUserAddress;

    // The lilypad module directory address
    address public lilypadModuleDirectoryAddress;

    // The lilypad storage address
    address public lilypadStorageAddress;

    // The lilypad payment engine address
    address public lilypadPaymentEngineAddress;

    // The lilypad proxy address
    address public lilypadProxyAddress;

    // The lilypad vesting address
    address public lilypadVestingAddress;

    // Events
    event LilypadContractRegistry__ContractAddressSet(string name, address indexed contractAddress);

    // Custom Errors
    error LilpadContractRegistry__NoZeroAddress();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initialize
    function initialize(
        address _l1LilypadTokenAddress,
        address _l2LilypadTokenAddress,
        address _lilypadUserAddress,
        address _lilypadModuleDirectoryAddress,
        address _lilypadStorageAddress,
        address _lilypadPaymentEngineAddress,
        address _lilypadProxyAddress,
        address _lilypadVestingAddress
    ) public initializer {
        if (_l1LilypadTokenAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_l2LilypadTokenAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_lilypadUserAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_lilypadModuleDirectoryAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_lilypadStorageAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_lilypadPaymentEngineAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_lilypadProxyAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();
        if (_lilypadVestingAddress == address(0)) revert LilpadContractRegistry__NoZeroAddress();

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        l1LilypadTokenAddress = _l1LilypadTokenAddress;
        l2LilypadTokenAddress = _l2LilypadTokenAddress;
        lilypadUserAddress = _lilypadUserAddress;
        lilypadModuleDirectoryAddress = _lilypadModuleDirectoryAddress;
        lilypadStorageAddress = _lilypadStorageAddress;
        lilypadPaymentEngineAddress = _lilypadPaymentEngineAddress;
        lilypadProxyAddress = _lilypadProxyAddress;
        lilypadVestingAddress = _lilypadVestingAddress;

        version = "1.0.0";
    }

    /**
     * @dev Sets the L2 Lilypad Token Address
     * @param _l2LilypadTokenAddress The proxy address of the L2 Lilypad Token
     */
    function setL2LilypadTokenAddress(address _l2LilypadTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        l2LilypadTokenAddress = _l2LilypadTokenAddress;
        emit LilypadContractRegistry__ContractAddressSet("L2 Lilypad Token", _l2LilypadTokenAddress);
    }

    /**
     * @dev Sets the Lilypad User Address
     * @param _lilypadUserAddress The proxy address of the Lilypad User
     */
    function setLilypadUserAddress(address _lilypadUserAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lilypadUserAddress = _lilypadUserAddress;
        emit LilypadContractRegistry__ContractAddressSet("Lilypad User", _lilypadUserAddress);
    }

    /**
     * @dev Sets the Lilypad Module Directory Address
     * @param _lilypadModuleDirectoryAddress The proxy address of the Lilypad Module Directory
     */
    function setLilypadModuleDirectoryAddress(address _lilypadModuleDirectoryAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lilypadModuleDirectoryAddress = _lilypadModuleDirectoryAddress;
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Module Directory", _lilypadModuleDirectoryAddress);
    }

    /**
     * @dev Sets the Lilypad Storage Address
     * @param _lilypadStorageAddress The proxy address of the Lilypad Storage
     */
    function setLilypadStorageAddress(address _lilypadStorageAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lilypadStorageAddress = _lilypadStorageAddress;
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Storage", _lilypadStorageAddress);
    }

    /**
     * @dev Sets the Lilypad Payment Engine Address
     * @param _lilypadPaymentEngineAddress The proxy address of the Lilypad Payment Engine
     */
    function setLilypadPaymentEngineAddress(address _lilypadPaymentEngineAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lilypadPaymentEngineAddress = _lilypadPaymentEngineAddress;
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Payment Engine", _lilypadPaymentEngineAddress);
    }

    /**
     * @dev Sets the Lilypad Proxy Address
     * @param _lilypadProxyAddress The proxy address of the Lilypad Proxy
     */
    function setLilypadProxyAddress(address _lilypadProxyAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lilypadProxyAddress = _lilypadProxyAddress;
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Proxy", _lilypadProxyAddress);
    }

    /**
     * @dev Sets the Lilypad Vesting Address
     * @param _lilypadVestingAddress The proxy address of the Lilypad Vesting
     */
    function setLilypadVestingAddress(address _lilypadVestingAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lilypadVestingAddress = _lilypadVestingAddress;
        emit LilypadContractRegistry__ContractAddressSet("Lilypad Vesting", _lilypadVestingAddress);
    }
}
