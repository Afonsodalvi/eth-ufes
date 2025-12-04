// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {PointsHook} from "../src/hooks/PointsHook.sol";

/// @title SwapScript
/// @notice Script para executar um swap em uma pool do Uniswap V4
contract SwapScript is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Endereços dos contratos
        address poolManagerAddress = vm.envAddress("POOL_MANAGER_ADDRESS");
        address hookAddress = vm.envAddress("HOOK_ADDRESS");
        address token0Address = vm.envAddress("TOKEN0_ADDRESS");
        address token1Address = vm.envAddress("TOKEN1_ADDRESS");

        IPoolManager poolManager = IPoolManager(poolManagerAddress);
        PoolSwapTest swapRouter = new PoolSwapTest(poolManager);
        PointsHook hook = PointsHook(payable(hookAddress));

        // Criar PoolKey
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0Address),
            currency1: Currency.wrap(token1Address),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        PoolId poolId = key.toId();

        console.log("=== Executing Swap ===");
        console.log("Pool ID:", uint256(PoolId.unwrap(poolId)));
        console.log("User:", msg.sender);

        // Verificar pontos antes do swap
        uint256 pointsBefore = hook.getPoints(msg.sender);
        console.log("Points before swap:", pointsBefore);

        // Parâmetros do swap
        bool zeroForOne = true; // Token0 → Token1
        int256 amountSpecified = -1e18; // 1 token (negativo = input exato)

        console.log("\nSwap parameters:");
        console.log("Direction (zeroForOne):", zeroForOne);
        console.log("Amount:", uint256(-amountSpecified));

        // Executar swap
        if (Currency.unwrap(key.currency0) == address(0)) {
            // ETH → Token
            swapRouter.swap{value: uint256(-amountSpecified)}(
                key,
                IPoolManager.SwapParams({
                    zeroForOne: zeroForOne,
                    amountSpecified: amountSpecified,
                    sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
                }),
                PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                ""
            );
        } else {
            // Token → Token ou Token → ETH
            // Nota: Precisa aprovar tokens antes
            console.log("\nNote: Approve tokens before running this script");
        }

        // Verificar pontos após o swap
        uint256 pointsAfter = hook.getPoints(msg.sender);
        console.log("\nPoints after swap:", pointsAfter);
        console.log("Points earned:", pointsAfter - pointsBefore);

        console.log("\n=== Swap Complete ===");

        vm.stopBroadcast();
    }
}

