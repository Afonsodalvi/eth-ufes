// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/types/PoolOperation.sol";
import {PointsToken} from "../tokens/PointsToken.sol";

/// @title PointsHook
/// @notice Hook que recompensa usuários com pontos por swaps e adição de liquidez
/// @dev Implementa afterSwap e afterAddLiquidity para distribuir pontos
contract PointsHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    /// @notice Token de pontos usado para recompensas
    PointsToken public immutable pointsToken;

    /// @notice Mapeamento de usuário para total de pontos acumulados
    mapping(address => uint256) public userPoints;

    /// @notice Mapeamento de pool para total de volume (para estatísticas)
    mapping(PoolId => uint256) public poolVolume;

    /// @notice Taxa de conversão: 1 ETH = 1 ponto (ajustável)
    uint256 public constant POINTS_PER_ETH = 1e18;

    /// @notice Evento emitido quando pontos são distribuídos
    event PointsAwarded(address indexed user, uint256 points, string reason);

    /// @notice Evento emitido quando volume é registrado
    event VolumeRecorded(PoolId indexed poolId, uint256 volume);

    /// @param _poolManager Endereço do PoolManager do Uniswap V4
    /// @param _pointsToken Endereço do token de pontos
    constructor(IPoolManager _poolManager, PointsToken _pointsToken) BaseHook(_poolManager) {
        pointsToken = _pointsToken;
    }

    /// @notice Retorna as permissões do hook
    /// @dev Este hook implementa afterSwap e afterAddLiquidity
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true, // ✅ Implementamos este hook
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true, // ✅ Implementamos este hook
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Hook chamado após um swap ser executado
    /// @param sender Endereço que executou o swap
    /// @param key PoolKey da pool onde o swap ocorreu
    /// @param params Parâmetros do swap
    /// @param delta Mudança de saldo resultante do swap
    /// @param hookData Dados adicionais do hook (não usado neste caso)
    /// @return selector Selector da função para validação
    /// @return int128 Valor adicional de delta (0 neste caso)
    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        // Calcular valor do swap em ETH
        uint256 swapValue = _calculateSwapValue(key, delta);

        // Atualizar volume da pool
        PoolId poolId = key.toId();
        poolVolume[poolId] += swapValue;

        // Calcular pontos baseado no valor do swap
        uint256 points = _calculatePoints(swapValue);

        // Distribuir pontos
        // Se hookData contém um endereço (para testes), usar esse endereço
        // Caso contrário, usar sender (router em produção)
        address recipient = sender;
        if (hookData.length == 32) {
            // Tentar decodificar como endereço (20 bytes + padding)
            address dataAddress = abi.decode(hookData, (address));
            if (dataAddress != address(0)) {
                recipient = dataAddress;
            }
        }

        if (points > 0) {
            userPoints[recipient] += points;
            pointsToken.mint(recipient, points);
            emit PointsAwarded(recipient, points, "swap");
        }

        emit VolumeRecorded(poolId, swapValue);

        return (IHooks.afterSwap.selector, 0);
    }

    /// @notice Hook chamado após liquidez ser adicionada
    /// @param sender Endereço que adicionou liquidez
    /// @param key PoolKey da pool
    /// @param params Parâmetros da modificação de liquidez
    /// @param delta Mudança de saldo resultante
    /// @param feesAccrued Taxas acumuladas (não usado)
    /// @param hookData Dados adicionais do hook
    /// @return selector Selector da função
    /// @return BalanceDelta Delta adicional (0 neste caso)
    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        // Calcular valor da liquidez adicionada em ETH
        uint256 liquidityValue = _calculateLiquidityValue(key, delta);

        // Calcular pontos baseado no valor da liquidez
        uint256 points = _calculatePoints(liquidityValue);

        // Distribuir pontos
        // Se hookData contém um endereço (para testes), usar esse endereço
        // Caso contrário, usar sender (router em produção)
        address recipient = sender;
        if (hookData.length == 32) {
            // Tentar decodificar como endereço (20 bytes + padding)
            address dataAddress = abi.decode(hookData, (address));
            if (dataAddress != address(0)) {
                recipient = dataAddress;
            }
        }

        if (points > 0) {
            userPoints[recipient] += points;
            pointsToken.mint(recipient, points);
            emit PointsAwarded(recipient, points, "liquidity");
        }

        return (IHooks.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    /// @notice Calcula o valor de um swap em ETH
    /// @param key PoolKey da pool
    /// @param delta Mudança de saldo do swap
    /// @return value Valor em wei (ETH)
    function _calculateSwapValue(PoolKey calldata key, BalanceDelta delta) internal view returns (uint256) {
        // Pegar o valor absoluto da mudança de saldo
        // Se currency0 é ETH, delta.amount0() é a mudança em ETH
        // Se currency1 é ETH, delta.amount1() é a mudança em ETH

        int128 amount0 = delta.amount0();
        int128 amount1 = delta.amount1();

        // Se currency0 é ETH (address(0))
        if (Currency.unwrap(key.currency0) == address(0)) {
            // amount0 negativo = ETH saiu, amount0 positivo = ETH entrou
            // Pegamos o valor absoluto
            return uint256(uint128(amount0 < 0 ? -amount0 : amount0));
        }

        // Se currency1 é ETH
        if (Currency.unwrap(key.currency1) == address(0)) {
            return uint256(uint128(amount1 < 0 ? -amount1 : amount1));
        }

        // Se nenhum dos tokens é ETH, retornamos 0 (não recompensamos)
        // Em uma implementação mais avançada, poderíamos converter para ETH usando um oráculo
        return 0;
    }

    /// @notice Calcula o valor da liquidez adicionada em ETH
    /// @param key PoolKey da pool
    /// @param delta Mudança de saldo da liquidez
    /// @return value Valor em wei (ETH)
    function _calculateLiquidityValue(PoolKey calldata key, BalanceDelta delta) internal view returns (uint256) {
        // Similar ao swap, mas para liquidez
        int128 amount0 = delta.amount0();
        int128 amount1 = delta.amount1();

        // Se currency0 é ETH
        if (Currency.unwrap(key.currency0) == address(0)) {
            return uint256(uint128(amount0 < 0 ? -amount0 : amount0));
        }

        // Se currency1 é ETH
        if (Currency.unwrap(key.currency1) == address(0)) {
            return uint256(uint128(amount1 < 0 ? -amount1 : amount1));
        }

        return 0;
    }

    /// @notice Calcula pontos baseado no valor em ETH
    /// @param value Valor em wei (ETH)
    /// @return points Quantidade de pontos
    function _calculatePoints(uint256 value) internal pure returns (uint256) {
        // 1 ETH = 1 ponto (POINTS_PER_ETH = 1e18)
        // Então points = value (já está em wei)
        return value;
    }

    /// @notice Retorna o total de pontos de um usuário
    /// @param user Endereço do usuário
    /// @return Total de pontos acumulados
    function getPoints(address user) external view returns (uint256) {
        return userPoints[user];
    }

    /// @notice Retorna o volume total de uma pool
    /// @param poolId ID da pool
    /// @return Volume total em wei (ETH)
    function getPoolVolume(PoolId poolId) external view returns (uint256) {
        return poolVolume[poolId];
    }
}

