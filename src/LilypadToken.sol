// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// Type declarations
// State variables
// errors
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "./interfaces/ILilypadToken.sol";
import {SharedStructs} from "./SharedStructs.sol";

contract LilypadToken is ERC20Burnable, ERC20Pausable, AccessControl {
    ////////////////////////////////
    ///////// State Variables //////
    ////////////////////////////////
    string private constant NAME = "Lilypad Token";
    string private constant SYMBOL = "LILY";

    // Max supply of 1 billion tokens
    uint256 private constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    ////////////////////////////////
    ///////// Errors ///////////////
    ////////////////////////////////
    error LilypadToken__NotEnoughBalance();
    error LilypadToken__MaxSupplyReached();
    error LilypadToken__AmountMustBeGreaterThanZero();
    error LilypadToken__InvalidAddress();
    error LilypadToken__AlreadyMinter();
    error LilypadToken__NotMinter();

    ////////////////////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert LilypadToken__AmountMustBeGreaterThanZero();
        }
        _;
    }

    ////////////////////////////////
    ///////// Functions ////////////
    ////////////////////////////////
    constructor(uint256 initialSupply) ERC20(NAME, SYMBOL) moreThanZero(initialSupply) {
        if (initialSupply > MAX_SUPPLY) {
            revert LilypadToken__MaxSupplyReached();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SharedStructs.MINTER_ROLE, msg.sender);
        _grantRole(SharedStructs.PAUSER_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (minter == address(0)) {
            revert LilypadToken__InvalidAddress();
        }
        if (hasRole(SharedStructs.MINTER_ROLE, minter)) {
            revert LilypadToken__AlreadyMinter();
        }
        _grantRole(SharedStructs.MINTER_ROLE, minter);
        return true;
    }

    function removeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (minter == address(0)) {
            revert LilypadToken__InvalidAddress();
        }
        if (!hasRole(SharedStructs.MINTER_ROLE, minter)) {
            revert LilypadToken__NotMinter();
        }
        _revokeRole(SharedStructs.MINTER_ROLE, minter);
        return true;
    }

    function mint(address to, uint256 amount) external onlyRole(SharedStructs.MINTER_ROLE) moreThanZero(amount) returns (bool) {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert LilypadToken__MaxSupplyReached();
        }

        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) public override onlyRole(SharedStructs.MINTER_ROLE) moreThanZero(amount) {

        if (amount > balanceOf(msg.sender)) {
            revert LilypadToken__NotEnoughBalance();
        }

        burn(amount);
    }

    function pause() external onlyRole(SharedStructs.PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(SharedStructs.PAUSER_ROLE) {
        _unpause();
    }

    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
