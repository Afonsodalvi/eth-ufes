// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UniswapV4ForkFixture} from "../fixtures/UniswapV4ForkFixture.sol";
import {PointsHook} from "../../src/hooks/PointsHook.sol";
import {PointsToken} from "../../src/tokens/PointsToken.sol";
import {MockERC20} from "../../src/tokens/MockERC20.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {console} from "forge-std/console.sol";

/// @title PointsHookTest
/// @notice Testes completos para o PointsHook
contract PointsHookTest is UniswapV4ForkFixture {
    using CurrencyLibrary for Currency;

    function setUp() public override {
        super.setUp();
    }

    /// @notice Testa se o hook foi deployado corretamente
    function test_HookDeployment() public view {
        assertEq(address(hook.poolManager()), address(manager));
        assertEq(address(hook.pointsToken()), address(pointsToken));
    }

    /// @notice Testa se pontos são distribuídos após um swap
    function test_PointsAfterSwap() public {
        // 1. Adicionar liquidez inicial
        addLiquidity(alice, 10 ether, 10e18, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));

        // 2. Verificar pontos iniciais
        uint256 pointsBefore = hook.getPoints(bob);
        assertEq(pointsBefore, 0);

        // 3. Bob faz swap de 1 ETH → Token0
        uint256 swapAmount = 1 ether;
        swap(bob, true, -int256(swapAmount));

        // 4. Verificar se pontos foram distribuídos
        uint256 pointsAfter = hook.getPoints(bob);
        console.log("pointsAfter", pointsAfter);
        console.log("swapAmount", swapAmount);
        assertEq(pointsAfter, swapAmount, "Bob should receive points equal to swap amount");
        assertEq(pointsToken.balanceOf(bob), swapAmount, "Points token balance should match");
    }

    /// @notice Testa se pontos são distribuídos após adicionar liquidez
    function test_PointsAfterAddLiquidity() public {
        // 1. Verificar pontos iniciais
        uint256 pointsBefore = hook.getPoints(alice);
        assertEq(pointsBefore, 0);

        // 2. Alice adiciona liquidez
        uint256 ethAmount = 5 ether;
        uint256 tokenAmount = 5e18;
        addLiquidity(alice, ethAmount, tokenAmount, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));

        // 3. Verificar se pontos foram distribuídos
        uint256 pointsAfter = hook.getPoints(alice);
        assertGt(pointsAfter, 0, "Alice should receive points for adding liquidity");
        assertEq(pointsToken.balanceOf(alice), pointsAfter, "Points token balance should match");
    }

    /// @notice Testa múltiplos swaps acumulam pontos
    function test_MultipleSwapsAccumulatePoints() public {
        // 1. Adicionar liquidez
        addLiquidity(alice, 10 ether, 10e18, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));

        // 2. Bob faz primeiro swap
        swap(bob, true, -int256(1 ether));
        uint256 pointsAfterFirst = hook.getPoints(bob);
        assertEq(pointsAfterFirst, 1 ether);

        // 3. Bob faz segundo swap
        swap(bob, true, -int256(2 ether));
        uint256 pointsAfterSecond = hook.getPoints(bob);
        assertEq(pointsAfterSecond, 3 ether, "Points should accumulate");

        // 4. Bob faz terceiro swap
        swap(bob, true, -int256(0.5 ether));
        uint256 pointsAfterThird = hook.getPoints(bob);
        assertEq(pointsAfterThird, 3.5 ether, "Points should continue accumulating");
    }

    /// @notice Testa que diferentes usuários recebem pontos separadamente
    function test_DifferentUsersGetSeparatePoints() public {
        // 1. Adicionar liquidez (Alice receberá pontos da liquidez)
        addLiquidity(alice, 20 ether, 20e18, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));
        uint256 aliceLiquidityPoints = hook.getPoints(alice);
        assertGt(aliceLiquidityPoints, 0, "Alice should receive points for adding liquidity");

        // 2. Alice faz swap
        swap(alice, true, -int256(2 ether));
        uint256 alicePoints = hook.getPoints(alice);
        // Alice tem pontos da liquidez + pontos do swap
        assertGt(alicePoints, aliceLiquidityPoints, "Alice should have more points after swap");
        assertGe(alicePoints, 2 ether, "Alice should have at least 2 ether in points from swap");

        // 3. Bob faz swap (Bob não tem pontos de liquidez)
        uint256 bobPointsBefore = hook.getPoints(bob);
        assertEq(bobPointsBefore, 0, "Bob should have no points initially");
        
        swap(bob, true, -int256(3 ether));
        uint256 bobPoints = hook.getPoints(bob);
        assertEq(bobPoints, 3 ether, "Bob should receive 3 ether in points from swap");

        // 4. Verificar que pontos são independentes
        assertEq(hook.getPoints(alice), alicePoints, "Alice points should remain unchanged");
        assertEq(hook.getPoints(bob), 3 ether, "Bob points should remain unchanged");
    }

    /// @notice Testa volume da pool
    function test_PoolVolumeTracking() public {
        // 1. Adicionar liquidez
        addLiquidity(alice, 10 ether, 10e18, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));

        // 2. Verificar volume inicial
        uint256 volumeBefore = hook.getPoolVolume(poolId);
        assertEq(volumeBefore, 0);

        // 3. Fazer swaps
        swap(bob, true, -int256(1 ether));
        uint256 volumeAfterFirst = hook.getPoolVolume(poolId);
        assertGt(volumeAfterFirst, 0, "Volume should increase after swap");

        swap(bob, true, -int256(2 ether));
        uint256 volumeAfterSecond = hook.getPoolVolume(poolId);
        assertGt(volumeAfterSecond, volumeAfterFirst, "Volume should continue increasing");
    }

    /// @notice Testa swap na direção oposta (Token0 → ETH)
    function test_ReverseSwap() public {
        // 1. Adicionar liquidez
        addLiquidity(alice, 10 ether, 10e18, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));

        // 2. Bob faz swap ETH → Token0
        swap(bob, true, -int256(1 ether));
        uint256 pointsAfterFirst = hook.getPoints(bob);
        assertGt(pointsAfterFirst, 0);

        // 3. Bob faz swap reverso Token0 → ETH
        // IMPORTANTE: Passar hookData com bob para o hook rastrear corretamente
        vm.startPrank(bob);
        token0.approve(address(swapRouter), 1e18);
        bytes memory hookData = abi.encode(bob);
        swapRouter.swap(
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: -int256(1e18),
                sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            hookData
        );
        vm.stopPrank();

        // 4. Verificar que pontos aumentaram
        uint256 pointsAfterSecond = hook.getPoints(bob);
        assertGt(pointsAfterSecond, pointsAfterFirst, "Points should increase after reverse swap");
    }

    /// @notice Testa eventos emitidos
    function test_EventsEmitted() public {
        // 1. Adicionar liquidez
        addLiquidity(alice, 10 ether, 10e18, TickMath.minUsableTick(60), TickMath.maxUsableTick(60));

        // 2. Verificar evento de pontos após swap
        vm.expectEmit(true, false, false, true);
        emit PointsHook.PointsAwarded(bob, 1 ether, "swap");

        swap(bob, true, -int256(1 ether));
    }

    /// @notice Testa que hook não distribui pontos para swaps sem ETH
    function test_NoPointsForNonETHSwaps() public {
        // Criar pool Token0/Token1 (sem ETH)
        PoolKey memory tokenPoolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        // Inicializar pool
        manager.initialize(tokenPoolKey, TickMath.getSqrtPriceAtTick(0));

        // Adicionar liquidez
        vm.startPrank(alice);
        token0.approve(address(modifyLiquidityRouter), 10e18);
        token1.approve(address(modifyLiquidityRouter), 10e18);
        modifyLiquidityRouter.modifyLiquidity(
            tokenPoolKey,
            IPoolManager.ModifyLiquidityParams({
                tickLower: TickMath.minUsableTick(60),
                tickUpper: TickMath.maxUsableTick(60),
                liquidityDelta: 1e18,
                salt: 0
            }),
            ""
        );
        vm.stopPrank();

        // Fazer swap Token0 → Token1
        uint256 pointsBefore = hook.getPoints(bob);
        vm.startPrank(bob);
        token0.approve(address(swapRouter), 1e18);
        swapRouter.swap(
            tokenPoolKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -int256(1e18),
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ""
        );
        vm.stopPrank();

        // Verificar que não houve pontos (nenhum token é ETH)
        uint256 pointsAfter = hook.getPoints(bob);
        assertEq(pointsAfter, pointsBefore, "No points should be awarded for non-ETH swaps");
    }
}

