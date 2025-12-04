// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "../src/core/PoolManager.sol";
import {PointsHook} from "../src/hooks/PointsHook.sol";
import {PointsToken} from "../src/tokens/PointsToken.sol";
import {MockERC20} from "../src/tokens/MockERC20.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

/// @title DeployScript
/// @notice Script para fazer deploy de todos os contratos do projeto Uniswap V4
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying Uniswap V4 Contracts ===");
        console.log("Deployer:", msg.sender);

        // 1. Deploy PoolManager
        console.log("\n1. Deploying PoolManager...");
        IPoolManager poolManager = new PoolManager(msg.sender);
        console.log("PoolManager deployed at:", address(poolManager));

        // 2. Deploy PointsToken
        console.log("\n2. Deploying PointsToken...");
        PointsToken pointsToken = new PointsToken(msg.sender);
        console.log("PointsToken deployed at:", address(pointsToken));

        // 3. Calcular endereço do hook com flags corretas
        console.log("\n3. Calculating hook address with flags...");
        uint160 hookPermissionCount = 14;
        uint160 clearAllHookPermissionsMask = ~uint160(0) << hookPermissionCount;
        address hookAddress = address(
            uint160(
                type(uint160).max & clearAllHookPermissionsMask 
                | Hooks.AFTER_SWAP_FLAG 
                | Hooks.AFTER_ADD_LIQUIDITY_FLAG
            )
        );
        console.log("Hook address (with flags):", hookAddress);

        // 4. Deploy PointsHook usando CREATE2 para garantir o endereço
        console.log("\n4. Deploying PointsHook...");
        // Nota: Em produção, você usaria CREATE2 para garantir o endereço
        // Por enquanto, vamos usar um salt fixo
        bytes32 salt = keccak256("UniswapV4PointsHook");
        PointsHook hook = new PointsHook{salt: salt}(poolManager, pointsToken);
        console.log("PointsHook deployed at:", address(hook));
        
        // Se o endereço não corresponder, precisaríamos usar vm.etch em testes
        // ou calcular o salt correto para CREATE2

        // 5. Deploy tokens de teste (opcional)
        console.log("\n5. Deploying test tokens...");
        MockERC20 token0 = new MockERC20("Test Token 0", "TKN0");
        MockERC20 token1 = new MockERC20("Test Token 1", "TKN1");
        console.log("Token0 deployed at:", address(token0));
        console.log("Token1 deployed at:", address(token1));

        console.log("\n=== Deployment Complete ===");
        console.log("\nContract Addresses:");
        console.log("PoolManager:", address(poolManager));
        console.log("PointsToken:", address(pointsToken));
        console.log("PointsHook:", address(hook));
        console.log("Token0:", address(token0));
        console.log("Token1:", address(token1));

        vm.stopBroadcast();
    }
}

