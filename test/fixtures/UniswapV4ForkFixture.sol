// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {SwapRouterNoChecks} from "@uniswap/v4-core/src/test/SwapRouterNoChecks.sol";
import {PoolModifyLiquidityTestNoChecks} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTestNoChecks.sol";
import {PoolDonateTest} from "@uniswap/v4-core/src/test/PoolDonateTest.sol";
import {PoolTakeTest} from "@uniswap/v4-core/src/test/PoolTakeTest.sol";
import {PoolClaimsTest} from "@uniswap/v4-core/src/test/PoolClaimsTest.sol";
import {PoolNestedActionsTest} from "@uniswap/v4-core/src/test/PoolNestedActionsTest.sol";
import {ActionsRouter} from "@uniswap/v4-core/src/test/ActionsRouter.sol";
import {PointsHook} from "../../src/hooks/PointsHook.sol";
import {PointsHookTest} from "../../src/hooks/PointsHookTest.sol";
import {PointsToken} from "../../src/tokens/PointsToken.sol";
import {MockERC20} from "../../src/tokens/MockERC20.sol";

/// @title UniswapV4ForkFixture
/// @notice Fixture para testes usando fork do Ethereum mainnet com PoolManager oficial
/// @dev Usa o PoolManager oficial do Ethereum mainnet, mas routers de teste para facilitar
contract UniswapV4ForkFixture is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Endereço oficial do PoolManager da Uniswap V4 no Ethereum mainnet
    // Fonte: https://docs.uniswap.org/contracts/v4/deployments
    address public constant POOL_MANAGER_MAINNET = 0x000000000004444c5dc75cB358380D2e3dE08A90;
    PointsHook public hook;
    PointsToken public pointsToken;
    MockERC20 public token0;
    MockERC20 public token1;

    // Pool
    PoolKey public poolKey;
    PoolId public poolId;
    uint160 public initSqrtPriceX96;

    // Usuários de teste
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    // Fork
    uint256 public mainnetFork;
    string public ETHEREUM_MAINNET_RPC;

    /// @notice Setup completo do ambiente de teste com fork
    function setUp() public virtual {
        // 1. Criar fork do Ethereum mainnet
        // IMPORTANTE: Configure ETHEREUM_MAINNET_RPC no seu .env com um RPC confiável
        // Exemplos: Infura, Alchemy, QuickNode, etc.
        ETHEREUM_MAINNET_RPC = vm.envString("ETHEREUM_MAINNET_RPC");
        mainnetFork = vm.createFork(ETHEREUM_MAINNET_RPC);
        vm.selectFork(mainnetFork);

        // 2. Usar PoolManager oficial do mainnet
        manager = IPoolManager(POOL_MANAGER_MAINNET);
        
        // 3. Deploy routers de teste (mais fácil para testes)
        // Criar routers manualmente já que estamos usando PoolManager oficial
        swapRouter = new PoolSwapTest(manager);
        swapRouterNoChecks = new SwapRouterNoChecks(manager);
        modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);
        modifyLiquidityNoChecks = new PoolModifyLiquidityTestNoChecks(manager);
        donateRouter = new PoolDonateTest(manager);
        takeRouter = new PoolTakeTest(manager);
        claimsRouter = new PoolClaimsTest(manager);
        nestedActionRouter = new PoolNestedActionsTest(manager);
        feeController = makeAddr("feeController");
        actionsRouter = new ActionsRouter(manager);
        
        // Configurar fee controller (se necessário)
        try manager.setProtocolFeeController(feeController) {} catch {}

        // 3. Calcular endereço do hook com flags corretas PRIMEIRO
        // Precisamos saber o endereço do hook antes de deployar o PointsToken
        uint160 hookFlags = Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG;
        uint160 hookPermissionCount = 14;
        uint160 clearAllHookPermissionsMask = ~uint160(0) << hookPermissionCount;
        address hookAddress = address(
            uint160(
                type(uint160).max & clearAllHookPermissionsMask 
                | Hooks.AFTER_SWAP_FLAG 
                | Hooks.AFTER_ADD_LIQUIDITY_FLAG
            )
        );

        // 4. Deploy tokens de teste
        // IMPORTANTE: Deploy PointsToken com hookAddress como owner desde o início
        // Isso evita problemas de transferência de ownership
        pointsToken = new PointsToken(hookAddress);
        token0 = new MockERC20("Token0", "TKN0");
        token1 = new MockERC20("Token1", "TKN1");

        // 5. Deploy hook no endereço correto usando vm.etch
        // Usar PointsHookTest que não valida o endereço no construtor
        PointsHookTest tempHook = new PointsHookTest(manager, pointsToken);
        bytes memory hookCode = address(tempHook).code;
        
        // Colocar código no endereço correto
        vm.etch(hookAddress, hookCode);
        hook = PointsHook(payable(hookAddress));
        
        // Verificar que o hook tem acesso ao PointsToken correto
        require(address(hook.pointsToken()) == address(pointsToken), "PointsToken mismatch");
        require(pointsToken.owner() == address(hook), "Hook should be owner of PointsToken");
        
        // Verificar se o hook tem as permissões corretas
        Hooks.Permissions memory expectedPermissions = hook.getHookPermissions();
        require(
            expectedPermissions.afterSwap && expectedPermissions.afterAddLiquidity,
            "Hook permissions incorrect"
        );

        // 6. Criar pool key para ETH/Token0
        poolKey = PoolKey({
            currency0: CurrencyLibrary.ADDRESS_ZERO, // ETH nativo
            currency1: Currency.wrap(address(token0)),
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        poolId = poolKey.toId();
        initSqrtPriceX96 = TickMath.getSqrtPriceAtTick(0); // Preço 1:1

        // 7. Inicializar pool
        manager.initialize(poolKey, initSqrtPriceX96);

        // 8. Dar tokens para usuários de teste
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        token0.mint(alice, 1000e18);
        token0.mint(bob, 1000e18);
        token1.mint(alice, 1000e18);
        token1.mint(bob, 1000e18);
    }

    /// @notice Adiciona liquidez à pool usando router de teste
    /// @param user Usuário que adiciona liquidez
    /// @param amount0 Quantidade de currency0
    /// @param amount1 Quantidade de currency1
    /// @param tickLower Tick inferior
    /// @param tickUpper Tick superior
    function addLiquidity(
        address user,
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        vm.startPrank(user);

        // Aprovar tokens se necessário
        if (Currency.unwrap(poolKey.currency0) != address(0)) {
            MockERC20(Currency.unwrap(poolKey.currency0)).approve(address(modifyLiquidityRouter), amount0);
        }
        if (Currency.unwrap(poolKey.currency1) != address(0)) {
            MockERC20(Currency.unwrap(poolKey.currency1)).approve(address(modifyLiquidityRouter), amount1);
        }

        // Calcular quanto ETH enviar (se currency0 ou currency1 for ETH)
        uint256 ethToSend = 0;
        if (Currency.unwrap(poolKey.currency0) == address(0)) {
            ethToSend = amount0;
        } else if (Currency.unwrap(poolKey.currency1) == address(0)) {
            ethToSend = amount1;
        }

        // Passar o usuário original através do hookData para o hook poder rastrear corretamente
        bytes memory hookData = abi.encode(user);

        // Adicionar liquidez usando router de teste
        // Enviar ETH se necessário (função é payable)
        modifyLiquidityRouter.modifyLiquidity{value: ethToSend}(
            poolKey,
            IPoolManager.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: 1e18,
                salt: bytes32(0)
            }),
            hookData
        );

        vm.stopPrank();
    }

    /// @notice Executa um swap usando router de teste
    /// @param user Usuário que executa o swap
    /// @param zeroForOne Se true, troca currency0 por currency1
    /// @param amountSpecified Quantidade especificada (negativo = input exato)
    function swap(address user, bool zeroForOne, int256 amountSpecified) internal {
        vm.startPrank(user);

        // Passar o usuário original através do hookData para o hook poder rastrear corretamente
        bytes memory hookData = abi.encode(user);

        if (zeroForOne) {
            // ETH → Token0
            swapRouter.swap{value: uint256(-amountSpecified)}(
                poolKey,
                IPoolManager.SwapParams({
                    zeroForOne: zeroForOne,
                    amountSpecified: amountSpecified,
                    sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
                }),
                PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                hookData
            );
        } else {
            // Token0 → ETH
            token0.approve(address(swapRouter), uint256(-amountSpecified));
            swapRouter.swap(
                poolKey,
                IPoolManager.SwapParams({
                    zeroForOne: zeroForOne,
                    amountSpecified: amountSpecified,
                    sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
                }),
                PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                hookData
            );
        }

        vm.stopPrank();
    }
}

