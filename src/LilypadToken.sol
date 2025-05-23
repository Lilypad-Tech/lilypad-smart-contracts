// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {SharedStructs} from "./SharedStructs.sol";

/**
 * @title LilypadToken
 * @author Lilypad
 * This is the token contract for the Lilypad Protocol
 */
contract LilypadToken is ERC20Burnable, ERC20Pausable, AccessControl {
    ////////////////////////////////
    ///////// State Variables //////
    ////////////////////////////////
    string private constant NAME = "Lilypad Token";
    string private constant SYMBOL = "LILY";

    // Max supply of 1 billion tokens
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    //The multipler for future stimulants of token
    uint256 public alpha;

    ////////////////////////////////
    ///////// Events ///////////////
    ////////////////////////////////
    event LilypadToken__AlphaUpdated(uint256 _alpha);

    ////////////////////////////////
    ///////// Errors ///////////////
    ////////////////////////////////
    error LilypadToken__NotEnoughBalance();
    error LilypadToken__MaxSupplyReached();
    error LilypadToken__AmountMustBeGreaterThanZero();
    error LilypadToken__InvalidAddress();

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

    /**
     * @notice Sets the alpha parameter ()
     * @param _alpha New alpha value
     */
    function setAlpha(uint256 _alpha) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alpha = _alpha;
        emit LilypadToken__AlphaUpdated(_alpha);
    }

    function mint(address to, uint256 amount)
        external
        onlyRole(SharedStructs.MINTER_ROLE)
        moreThanZero(amount)
        returns (bool)
    {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert LilypadToken__MaxSupplyReached();
        }

        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) public override moreThanZero(amount) {
        if (amount > balanceOf(msg.sender)) {
            revert LilypadToken__NotEnoughBalance();
        }

        super.burn(amount);
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
