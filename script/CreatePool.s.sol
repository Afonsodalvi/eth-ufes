// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

/// @title CreatePoolScript
/// @notice Script para criar uma pool no Uniswap V4
contract CreatePoolScript is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Endereços dos contratos (preencha após deploy)
        address poolManagerAddress = vm.envAddress("POOL_MANAGER_ADDRESS");
        address hookAddress = vm.envAddress("HOOK_ADDRESS");
        address token0Address = vm.envAddress("TOKEN0_ADDRESS"); // Use address(0) para ETH
        address token1Address = vm.envAddress("TOKEN1_ADDRESS");

        IPoolManager poolManager = IPoolManager(poolManagerAddress);

        console.log("=== Creating Uniswap V4 Pool ===");
        console.log("PoolManager:", address(poolManager));
        console.log("Hook:", hookAddress);
        console.log("Token0:", token0Address);
        console.log("Token1:", token1Address);

        // Criar PoolKey
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0Address),
            currency1: Currency.wrap(token1Address),
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        PoolId poolId = key.toId();
        console.log("\nPool ID:", uint256(PoolId.unwrap(poolId)));

        // Calcular preço inicial (1:1)
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(0);
        console.log("Initial sqrtPriceX96:", sqrtPriceX96);

        // Inicializar pool
        console.log("\nInitializing pool...");
        poolManager.initialize(key, sqrtPriceX96);

        console.log("\n=== Pool Created Successfully ===");
        console.log("Pool ID:", uint256(PoolId.unwrap(poolId)));

        vm.stopBroadcast();
    }
}

