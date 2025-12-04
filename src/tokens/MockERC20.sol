// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

/// @title MockERC20
/// @notice Token ERC20 simples para testes
/// @dev Permite mint e burn para facilitar testes
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @notice Mint tokens para um endereço (apenas para testes)
    /// @param to Endereço que receberá os tokens
    /// @param amount Quantidade de tokens a mintar
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Burn tokens de um endereço (apenas para testes)
    /// @param from Endereço de onde os tokens serão queimados
    /// @param amount Quantidade de tokens a queimar
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

