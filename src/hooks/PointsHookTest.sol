// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PointsHook} from "./PointsHook.sol";
import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PointsToken} from "../tokens/PointsToken.sol";

/// @title PointsHookTest
/// @notice Versão de teste do PointsHook que não valida o endereço no construtor
/// @dev Usado apenas em testes para permitir deploy em qualquer endereço
contract PointsHookTest is PointsHook {
    /// @notice Construtor que não valida o endereço (para testes)
    /// @param _poolManager Endereço do PoolManager
    /// @param _pointsToken Endereço do token de pontos
    constructor(IPoolManager _poolManager, PointsToken _pointsToken) PointsHook(_poolManager, _pointsToken) {}

    /// @notice Sobrescreve validateHookAddress para não validar em testes
    function validateHookAddress(BaseHook _this) internal pure override {
        // Não validar em testes - permite deploy em qualquer endereço
        // A validação será feita quando o hook for usado
    }
}

