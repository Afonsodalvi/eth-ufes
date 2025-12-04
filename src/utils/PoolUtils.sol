// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";

/// @title PoolUtils
/// @notice Utilitários para trabalhar com pools do Uniswap V4
library PoolUtils {
    using PoolIdLibrary for PoolKey;

    /// @notice Calcula quantidades de tokens para uma quantidade de liquidez
    /// @param sqrtPriceX96 Preço atual (sqrt price)
    /// @param tickLower Tick inferior
    /// @param tickUpper Tick superior
    /// @param liquidity Quantidade de liquidez
    /// @return amount0 Quantidade de token0
    /// @return amount1 Quantidade de token1
    function calculateLiquidityAmounts(
        uint160 sqrtPriceX96,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        return LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidity
        );
    }

    /// @notice Obtém o preço atual de uma pool
    /// @param sqrtPriceX96 Preço atual (sqrt price)
    /// @return price Preço (token1/token0)
    function getPrice(uint160 sqrtPriceX96) internal pure returns (uint256 price) {
        // price = (sqrtPriceX96 / 2^96)^2
        return (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> 96;
    }

    /// @notice Converte sqrtPriceX96 para tick
    /// @param sqrtPriceX96 Preço atual (sqrt price)
    /// @return tick Tick correspondente
    function sqrtPriceX96ToTick(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        return TickMath.getTickAtSqrtPrice(sqrtPriceX96);
    }

    /// @notice Converte tick para sqrtPriceX96
    /// @param tick Tick
    /// @return sqrtPriceX96 Preço correspondente
    function tickToSqrtPriceX96(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        return TickMath.getSqrtPriceAtTick(tick);
    }
}

