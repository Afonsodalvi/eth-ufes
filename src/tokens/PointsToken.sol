// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/// @title PointsToken
/// @notice Token ERC20 para pontos de recompensa
/// @dev Apenas permite mint (sem burn), usado pelo PointsHook
contract PointsToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Points Token", "POINTS") Ownable(initialOwner) {}

    /// @notice Mint pontos para um endereço
    /// @param to Endereço que receberá os pontos
    /// @param amount Quantidade de pontos a mintar
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Override transfer para tornar pontos não-transferíveis (opcional)
    /// @dev Se quiser que pontos sejam não-transferíveis, descomente:
    /*
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Points are non-transferable");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Points are non-transferable");
    }
    */
}

