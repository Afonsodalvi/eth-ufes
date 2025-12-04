# 🧪 Guia Didático Completo: Testes do PointsHook

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [UniswapV4ForkFixture: O Setup Completo](#uniswapv4forkfixture-o-setup-completo)
3. [PointsHook.t.sol: Análise Detalhada dos Testes](#pointshooktsol-análise-detalhada-dos-testes)
4. [Fluxo Completo de um Teste](#fluxo-completo-de-um-teste)
5. [Conceitos Importantes](#conceitos-importantes)

---

## 🎯 Visão Geral

Este guia explica **passo a passo** como funcionam os testes do `PointsHook`. Os testes verificam que o hook distribui pontos corretamente para usuários que fazem swaps ou adicionam liquidez na Uniswap V4.

### Arquitetura dos Testes

```
┌─────────────────────────────────────────────────────────┐
│              PointsHookTest (Teste)                      │
│  └─ Herda de UniswapV4ForkFixture                       │
│     └─ Herda de Test + Deployers                        │
└─────────────────────────────────────────────────────────┘
                        │
                        │ usa
                        ▼
┌─────────────────────────────────────────────────────────┐
│         UniswapV4ForkFixture (Setup)                     │
│  - Cria fork da mainnet                                 │
│  - Deploy do hook                                        │
│  - Cria pool                                             │
│  - Fornece funções helper (addLiquidity, swap)          │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 UniswapV4ForkFixture: O Setup Completo

O `UniswapV4ForkFixture` é o **coração do ambiente de testes**. Ele configura tudo que precisamos para testar o hook.

### O que é um Fixture?

Um **fixture** é um contrato que prepara o ambiente de teste. Em vez de repetir o mesmo código de setup em cada teste, criamos um fixture que faz isso uma vez e todos os testes herdam dele.

### Estrutura do Fixture

```solidity
contract UniswapV4ForkFixture is Test, Deployers {
    // Variáveis que serão usadas nos testes
    PointsHook public hook;
    PointsToken public pointsToken;
    MockERC20 public token0;
    MockERC20 public token1;
    PoolKey public poolKey;
    address public alice;
    address public bob;
    
    function setUp() public virtual {
        // Todo o setup acontece aqui
    }
    
    function addLiquidity(...) internal {
        // Helper para adicionar liquidez
    }
    
    function swap(...) internal {
        // Helper para fazer swap
    }
}
```

---

## 📝 Passo a Passo: O que o `setUp()` Faz

### Passo 1: Criar Fork da Mainnet

```solidity
ETHEREUM_MAINNET_RPC = vm.envString("ETHEREUM_MAINNET_RPC");
mainnetFork = vm.createFork(ETHEREUM_MAINNET_RPC);
vm.selectFork(mainnetFork);
```

**O que faz:**
- Lê a URL do RPC do arquivo `.env`
- Cria um fork (cópia) do Ethereum mainnet
- Seleciona esse fork para usar nos testes

**Por quê?**
- Usamos o **PoolManager oficial** da Uniswap V4 que já está deployado na mainnet
- Não precisamos deployar nosso próprio PoolManager
- Testamos contra contratos reais em produção

**Analogia:**
É como fazer uma cópia de um livro para anotar nele, sem alterar o original.

### Passo 2: Usar PoolManager Oficial

```solidity
manager = IPoolManager(POOL_MANAGER_MAINNET);
// POOL_MANAGER_MAINNET = 0x000000000004444c5dc75cB358380D2e3dE08A90
```

**O que faz:**
- Define `manager` como o PoolManager oficial da Uniswap V4
- Este é o contrato real que gerencia todas as pools na mainnet

**Por quê?**
- Garante que testamos contra o código real
- Não precisamos manter nosso próprio PoolManager atualizado

### Passo 3: Deploy Routers de Teste

```solidity
swapRouter = new PoolSwapTest(manager);
modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);
// ... outros routers
```

**O que faz:**
- Cria routers de teste que facilitam as operações
- Cada router tem funções simplificadas para testes

**Por quê?**
- Os routers oficiais podem ser complexos
- Routers de teste são mais simples e diretos
- Ainda usam o PoolManager oficial

**Analogia:**
É como ter um controle remoto simplificado para uma TV complexa.

### Passo 4: Calcular Endereço do Hook com Flags

```solidity
uint160 hookPermissionCount = 14;
uint160 clearAllHookPermissionsMask = ~uint160(0) << hookPermissionCount;
address hookAddress = address(
    uint160(
        type(uint160).max & clearAllHookPermissionsMask 
        | Hooks.AFTER_SWAP_FLAG 
        | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    )
);
```

**O que faz:**
- Calcula o endereço onde o hook deve ser deployado
- Os últimos bits do endereço indicam quais hooks estão ativos
- `AFTER_SWAP_FLAG`: Hook é chamado após swaps
- `AFTER_ADD_LIQUIDITY_FLAG`: Hook é chamado após adicionar liquidez

**Por quê?**
- O Uniswap V4 usa os últimos bits do endereço para indicar permissões
- Isso permite verificar permissões sem fazer uma chamada externa
- É uma otimização de gas

**Exemplo Visual:**
```
Endereço normal:    0x1234...5678
Endereço com flags: 0x1234...567F
                                    ↑↑
                              Flags aqui!
```

### Passo 5: Deploy PointsToken com Hook como Owner

```solidity
pointsToken = new PointsToken(hookAddress);
```

**O que faz:**
- Cria o token de pontos
- Define o hook como owner desde o início

**Por quê?**
- O hook precisa ser owner para poder fazer `mint()`
- Se deployássemos depois, teríamos que transferir ownership
- Fazendo desde o início evita problemas

### Passo 6: Deploy Hook no Endereço Correto

```solidity
PointsHookTest tempHook = new PointsHookTest(manager, pointsToken);
bytes memory hookCode = address(tempHook).code;
vm.etch(hookAddress, hookCode);
hook = PointsHook(payable(hookAddress));
```

**O que faz:**
1. Deploy temporário do hook para obter o bytecode
2. Copia o bytecode para o endereço correto usando `vm.etch`
3. Cria referência ao hook no endereço correto

**Por quê `vm.etch`?**
- Precisamos que o hook esteja no endereço exato com as flags corretas
- `vm.etch` coloca código em um endereço específico sem executar o construtor
- Os valores `immutable` (manager, pointsToken) já estão no bytecode

**Por quê `PointsHookTest`?**
- `PointsHook` valida o endereço no construtor
- `PointsHookTest` não valida, permitindo deploy em qualquer endereço
- Depois de `vm.etch`, o hook funciona normalmente

### Passo 7: Verificações

```solidity
require(address(hook.pointsToken()) == address(pointsToken), "PointsToken mismatch");
require(pointsToken.owner() == address(hook), "Hook should be owner of PointsToken");
require(
    expectedPermissions.afterSwap && expectedPermissions.afterAddLiquidity,
    "Hook permissions incorrect"
);
```

**O que faz:**
- Verifica que tudo está configurado corretamente
- Garante que o hook tem acesso ao PointsToken
- Garante que o hook tem as permissões corretas

**Por quê?**
- Se algo estiver errado, o teste falha imediatamente no setup
- Melhor falhar cedo do que ter erros misteriosos depois

### Passo 8: Criar Pool Key

```solidity
poolKey = PoolKey({
    currency0: CurrencyLibrary.ADDRESS_ZERO, // ETH nativo
    currency1: Currency.wrap(address(token0)),
    fee: 3000, // 0.3%
    tickSpacing: 60,
    hooks: IHooks(address(hook))
});
```

**O que faz:**
- Define os parâmetros da pool
- `currency0`: ETH (endereço zero)
- `currency1`: Token0 (nosso token de teste)
- `fee`: 3000 = 0.3%
- `tickSpacing`: 60 (espaçamento entre ticks)
- `hooks`: Endereço do nosso hook

**O que é PoolKey?**
- É uma estrutura que identifica uma pool única
- Duas pools com a mesma PoolKey são a mesma pool
- É como um "ID" da pool

### Passo 9: Inicializar Pool

```solidity
poolId = poolKey.toId();
initSqrtPriceX96 = TickMath.getSqrtPriceAtTick(0); // Preço 1:1
manager.initialize(poolKey, initSqrtPriceX96);
```

**O que faz:**
- Calcula o `poolId` (hash da PoolKey)
- Define o preço inicial (1:1, tick 0)
- Inicializa a pool no PoolManager

**Por quê preço 1:1?**
- Facilita os testes
- 1 ETH = 1 Token0
- Mais fácil de calcular e verificar

### Passo 10: Dar Tokens para Usuários

```solidity
vm.deal(alice, 100 ether);
vm.deal(bob, 100 ether);
token0.mint(alice, 1000e18);
token0.mint(bob, 1000e18);
```

**O que faz:**
- `vm.deal`: Dá ETH para os usuários (cheatcode do Foundry)
- `mint`: Cria tokens para os usuários

**Por quê?**
- Os usuários precisam de tokens para fazer operações
- Em testes, podemos criar tokens do nada
- Isso facilita os testes

---

## 🔄 Funções Helper do Fixture

### `addLiquidity()`

```solidity
function addLiquidity(
    address user,
    uint256 amount0,
    uint256 amount1,
    int24 tickLower,
    int24 tickUpper
) internal {
    vm.startPrank(user);  // Simula que 'user' está fazendo a chamada
    
    // Aprovar tokens
    if (currency0 não é ETH) {
        token.approve(...);
    }
    
    // Calcular ETH a enviar
    uint256 ethToSend = 0;
    if (currency0 é ETH) {
        ethToSend = amount0;
    }
    
    // Passar usuário original via hookData
    bytes memory hookData = abi.encode(user);
    
    // Adicionar liquidez
    modifyLiquidityRouter.modifyLiquidity{value: ethToSend}(...);
    
    vm.stopPrank();
}
```

**O que faz:**
1. Simula que `user` está fazendo a chamada (`vm.startPrank`)
2. Aprova tokens se necessário
3. Calcula quanto ETH enviar (se a pool usa ETH)
4. **Importante:** Passa o usuário original via `hookData`
5. Chama o router para adicionar liquidez
6. Para de simular (`vm.stopPrank`)

**Por quê `hookData`?**
- O router chama o PoolManager, que chama o hook
- Sem `hookData`, o hook veria o router como `msg.sender`
- Com `hookData`, o hook sabe quem é o usuário real

### `swap()`

```solidity
function swap(address user, bool zeroForOne, int256 amountSpecified) internal {
    vm.startPrank(user);
    
    bytes memory hookData = abi.encode(user);
    
    if (zeroForOne) {
        // ETH → Token0
        swapRouter.swap{value: uint256(-amountSpecified)}(...);
    } else {
        // Token0 → ETH
        token0.approve(...);
        swapRouter.swap(...);
    }
    
    vm.stopPrank();
}
```

**O que faz:**
1. Simula que `user` está fazendo a chamada
2. Passa o usuário via `hookData`
3. Se `zeroForOne = true`: ETH → Token0 (envia ETH)
4. Se `zeroForOne = false`: Token0 → ETH (aprova token)
5. Chama o router para fazer swap

**Por quê `-amountSpecified`?**
- Valores negativos = input exato (quanto você quer enviar)
- Valores positivos = output exato (quanto você quer receber)
- Usamos negativo para especificar quanto queremos enviar

---

## 🧪 PointsHook.t.sol: Análise Detalhada dos Testes

Agora vamos analisar **cada teste** passo a passo.

### Estrutura de um Teste

```solidity
function test_NomeDoTeste() public {
    // 1. Preparação (Arrange)
    // 2. Ação (Act)
    // 3. Verificação (Assert)
}
```

Este é o padrão **AAA (Arrange-Act-Assert)**.

---

### Teste 1: `test_HookDeployment`

```solidity
function test_HookDeployment() public view {
    assertEq(address(hook.poolManager()), address(manager));
    assertEq(address(hook.pointsToken()), address(pointsToken));
}
```

**O que testa:**
- Verifica se o hook foi deployado corretamente
- Verifica se o hook tem referência ao PoolManager correto
- Verifica se o hook tem referência ao PointsToken correto

**Por quê?**
- Se o hook não foi deployado corretamente, nada vai funcionar
- Este é um teste básico de "smoke test"

**Resultado esperado:**
- ✅ Hook tem referência ao manager correto
- ✅ Hook tem referência ao pointsToken correto

---

### Teste 2: `test_PointsAfterSwap`

```solidity
function test_PointsAfterSwap() public {
    // 1. Preparação
    addLiquidity(alice, 10 ether, 10e18, ...);
    
    // 2. Verificar estado inicial
    uint256 pointsBefore = hook.getPoints(bob);
    assertEq(pointsBefore, 0);
    
    // 3. Ação: Bob faz swap
    uint256 swapAmount = 1 ether;
    swap(bob, true, -int256(swapAmount));
    
    // 4. Verificação
    uint256 pointsAfter = hook.getPoints(bob);
    assertEq(pointsAfter, swapAmount, "Bob should receive points equal to swap amount");
    assertEq(pointsToken.balanceOf(bob), swapAmount, "Points token balance should match");
}
```

**Passo a Passo:**

1. **Preparação:**
   - Alice adiciona liquidez (10 ETH + 10 Token0)
   - Isso cria a pool e permite que swaps aconteçam

2. **Estado Inicial:**
   - Verifica que Bob tem 0 pontos
   - Garante que começamos do zero

3. **Ação:**
   - Bob faz swap de 1 ETH → Token0
   - `swap(bob, true, -int256(1 ether))`
   - `true` = zeroForOne (ETH → Token0)
   - `-int256(1 ether)` = enviar exatamente 1 ETH

4. **Verificação:**
   - Bob deve ter recebido 1 ETH em pontos
   - O saldo do token de pontos deve ser 1 ETH

**Fluxo Completo:**
```
Bob → swapRouter.swap(1 ETH) 
    → PoolManager.modifyLiquidity()
    → Hook.afterSwap()
    → Hook calcula pontos (1 ETH = 1 ponto)
    → Hook.mint(bob, 1 ETH)
    → Bob recebe 1 ETH em pontos! ✅
```

**Resultado esperado:**
- ✅ Bob tem 1 ETH em pontos
- ✅ Bob tem 1 ETH no saldo do token

---

### Teste 3: `test_PointsAfterAddLiquidity`

```solidity
function test_PointsAfterAddLiquidity() public {
    // 1. Estado inicial
    uint256 pointsBefore = hook.getPoints(alice);
    assertEq(pointsBefore, 0);
    
    // 2. Ação: Alice adiciona liquidez
    addLiquidity(alice, 5 ether, 5e18, ...);
    
    // 3. Verificação
    uint256 pointsAfter = hook.getPoints(alice);
    assertGt(pointsAfter, 0, "Alice should receive points for adding liquidity");
    assertEq(pointsToken.balanceOf(alice), pointsAfter, "Points token balance should match");
}
```

**Passo a Passo:**

1. **Estado Inicial:**
   - Alice tem 0 pontos

2. **Ação:**
   - Alice adiciona 5 ETH + 5 Token0 de liquidez
   - O hook é chamado após adicionar liquidez

3. **Verificação:**
   - Alice deve ter recebido pontos
   - Os pontos devem ser maiores que 0
   - O saldo do token deve corresponder aos pontos

**Por quê `assertGt` (greater than)?**
- Não sabemos exatamente quantos pontos Alice recebe
- Depende de como o hook calcula pontos para liquidez
- Só verificamos que recebeu algo

**Resultado esperado:**
- ✅ Alice tem pontos > 0
- ✅ Saldo do token = pontos

---

### Teste 4: `test_MultipleSwapsAccumulatePoints`

```solidity
function test_MultipleSwapsAccumulatePoints() public {
    // 1. Preparação
    addLiquidity(alice, 10 ether, 10e18, ...);
    
    // 2. Primeiro swap
    swap(bob, true, -int256(1 ether));
    uint256 pointsAfterFirst = hook.getPoints(bob);
    assertEq(pointsAfterFirst, 1 ether);
    
    // 3. Segundo swap
    swap(bob, true, -int256(2 ether));
    uint256 pointsAfterSecond = hook.getPoints(bob);
    assertEq(pointsAfterSecond, 3 ether, "Points should accumulate");
    
    // 4. Terceiro swap
    swap(bob, true, -int256(0.5 ether));
    uint256 pointsAfterThird = hook.getPoints(bob);
    assertEq(pointsAfterThird, 3.5 ether, "Points should continue accumulating");
}
```

**Passo a Passo:**

1. **Preparação:**
   - Alice adiciona liquidez

2. **Primeiro Swap:**
   - Bob faz swap de 1 ETH
   - Verifica: Bob tem 1 ETH em pontos

3. **Segundo Swap:**
   - Bob faz swap de 2 ETH
   - Verifica: Bob tem 3 ETH em pontos (1 + 2)

4. **Terceiro Swap:**
   - Bob faz swap de 0.5 ETH
   - Verifica: Bob tem 3.5 ETH em pontos (1 + 2 + 0.5)

**O que testa:**
- Pontos são **acumulativos**
- Cada swap adiciona pontos aos existentes
- Não substitui, soma!

**Resultado esperado:**
- ✅ Após 1º swap: 1 ETH
- ✅ Após 2º swap: 3 ETH
- ✅ Após 3º swap: 3.5 ETH

---

### Teste 5: `test_DifferentUsersGetSeparatePoints`

```solidity
function test_DifferentUsersGetSeparatePoints() public {
    // 1. Alice adiciona liquidez (recebe pontos)
    addLiquidity(alice, 20 ether, 20e18, ...);
    uint256 aliceLiquidityPoints = hook.getPoints(alice);
    assertGt(aliceLiquidityPoints, 0);
    
    // 2. Alice faz swap (recebe mais pontos)
    swap(alice, true, -int256(2 ether));
    uint256 alicePoints = hook.getPoints(alice);
    assertGt(alicePoints, aliceLiquidityPoints);
    assertGe(alicePoints, 2 ether);
    
    // 3. Bob faz swap (Bob não tem pontos de liquidez)
    uint256 bobPointsBefore = hook.getPoints(bob);
    assertEq(bobPointsBefore, 0);
    
    swap(bob, true, -int256(3 ether));
    uint256 bobPoints = hook.getPoints(bob);
    assertEq(bobPoints, 3 ether);
    
    // 4. Verificar independência
    assertEq(hook.getPoints(alice), alicePoints);
    assertEq(hook.getPoints(bob), 3 ether);
}
```

**Passo a Passo:**

1. **Alice adiciona liquidez:**
   - Alice recebe pontos pela liquidez
   - Verifica que recebeu algo

2. **Alice faz swap:**
   - Alice recebe mais pontos (2 ETH)
   - Total de Alice = pontos de liquidez + 2 ETH
   - Verifica que tem pelo menos 2 ETH (do swap)

3. **Bob faz swap:**
   - Bob começa com 0 pontos
   - Bob faz swap de 3 ETH
   - Bob recebe 3 ETH em pontos

4. **Verificar independência:**
   - Os pontos de Alice não mudaram
   - Os pontos de Bob são independentes

**O que testa:**
- Cada usuário tem seu próprio contador de pontos
- Os pontos não se misturam
- É como contas bancárias separadas

**Resultado esperado:**
- ✅ Alice tem pontos (liquidez + swap)
- ✅ Bob tem 3 ETH em pontos
- ✅ Pontos são independentes

---

### Teste 6: `test_PoolVolumeTracking`

```solidity
function test_PoolVolumeTracking() public {
    // 1. Preparação
    addLiquidity(alice, 10 ether, 10e18, ...);
    
    // 2. Volume inicial
    uint256 volumeBefore = hook.getPoolVolume(poolId);
    assertEq(volumeBefore, 0);
    
    // 3. Primeiro swap
    swap(bob, true, -int256(1 ether));
    uint256 volumeAfterFirst = hook.getPoolVolume(poolId);
    assertGt(volumeAfterFirst, 0);
    
    // 4. Segundo swap
    swap(bob, true, -int256(2 ether));
    uint256 volumeAfterSecond = hook.getPoolVolume(poolId);
    assertGt(volumeAfterSecond, volumeAfterFirst);
}
```

**Passo a Passo:**

1. **Preparação:**
   - Alice adiciona liquidez

2. **Volume Inicial:**
   - Volume da pool = 0

3. **Primeiro Swap:**
   - Bob faz swap de 1 ETH
   - Volume aumenta

4. **Segundo Swap:**
   - Bob faz swap de 2 ETH
   - Volume aumenta mais

**O que testa:**
- O hook rastreia o volume total da pool
- Cada swap adiciona ao volume
- Volume é acumulativo

**Resultado esperado:**
- ✅ Volume inicial = 0
- ✅ Após 1º swap: volume > 0
- ✅ Após 2º swap: volume > volume anterior

---

### Teste 7: `test_ReverseSwap`

```solidity
function test_ReverseSwap() public {
    // 1. Preparação
    addLiquidity(alice, 10 ether, 10e18, ...);
    
    // 2. Swap ETH → Token0
    swap(bob, true, -int256(1 ether));
    uint256 pointsAfterFirst = hook.getPoints(bob);
    assertGt(pointsAfterFirst, 0);
    
    // 3. Swap reverso Token0 → ETH
    vm.startPrank(bob);
    token0.approve(address(swapRouter), 1e18);
    bytes memory hookData = abi.encode(bob);
    swapRouter.swap(
        poolKey,
        IPoolManager.SwapParams({
            zeroForOne: false,  // Token0 → ETH
            amountSpecified: -int256(1e18),
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        }),
        PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
        hookData  // IMPORTANTE: Passar hookData
    );
    vm.stopPrank();
    
    // 4. Verificar que pontos aumentaram
    uint256 pointsAfterSecond = hook.getPoints(bob);
    assertGt(pointsAfterSecond, pointsAfterFirst);
}
```

**Passo a Passo:**

1. **Preparação:**
   - Alice adiciona liquidez

2. **Primeiro Swap (ETH → Token0):**
   - Bob troca 1 ETH por Token0
   - Bob recebe pontos

3. **Swap Reverso (Token0 → ETH):**
   - Bob troca Token0 de volta para ETH
   - **Importante:** Passa `hookData` com `bob`
   - Isso garante que o hook sabe que Bob é o usuário real

4. **Verificação:**
   - Bob deve ter mais pontos agora
   - Pontos aumentaram com o swap reverso

**Por quê passar `hookData` manualmente?**
- A função `swap()` do fixture já faz isso
- Mas neste teste, fazemos manualmente para mostrar como funciona
- Sem `hookData`, o hook veria o router como usuário

**Resultado esperado:**
- ✅ Após 1º swap: Bob tem pontos
- ✅ Após swap reverso: Bob tem mais pontos

---

### Teste 8: `test_EventsEmitted`

```solidity
function test_EventsEmitted() public {
    // 1. Preparação
    addLiquidity(alice, 10 ether, 10e18, ...);
    
    // 2. Esperar evento
    vm.expectEmit(true, false, false, true);
    emit PointsHook.PointsAwarded(bob, 1 ether, "swap");
    
    // 3. Ação que deve emitir o evento
    swap(bob, true, -int256(1 ether));
}
```

**Passo a Passo:**

1. **Preparação:**
   - Alice adiciona liquidez

2. **Esperar Evento:**
   - `vm.expectEmit` diz ao Foundry para verificar se o evento será emitido
   - Parâmetros: `(checkTopic1, checkTopic2, checkTopic3, checkData)`
   - `true` = verificar, `false` = ignorar

3. **Ação:**
   - Bob faz swap
   - O hook deve emitir o evento `PointsAwarded`

**O que testa:**
- O hook emite eventos corretamente
- Eventos são importantes para frontends e indexadores

**Resultado esperado:**
- ✅ Evento `PointsAwarded` é emitido
- ✅ Evento tem os parâmetros corretos

---

### Teste 9: `test_NoPointsForNonETHSwaps`

```solidity
function test_NoPointsForNonETHSwaps() public {
    // 1. Criar pool Token0/Token1 (sem ETH)
    PoolKey memory tokenPoolKey = PoolKey({
        currency0: Currency.wrap(address(token0)),
        currency1: Currency.wrap(address(token1)),
        fee: 3000,
        tickSpacing: 60,
        hooks: IHooks(address(hook))
    });
    
    // 2. Inicializar pool
    manager.initialize(tokenPoolKey, TickMath.getSqrtPriceAtTick(0));
    
    // 3. Adicionar liquidez
    vm.startPrank(alice);
    token0.approve(...);
    token1.approve(...);
    modifyLiquidityRouter.modifyLiquidity(...);
    vm.stopPrank();
    
    // 4. Fazer swap Token0 → Token1
    uint256 pointsBefore = hook.getPoints(bob);
    vm.startPrank(bob);
    token0.approve(...);
    swapRouter.swap(...);
    vm.stopPrank();
    
    // 5. Verificar que não houve pontos
    uint256 pointsAfter = hook.getPoints(bob);
    assertEq(pointsAfter, pointsBefore);
}
```

**Passo a Passo:**

1. **Criar Nova Pool:**
   - Pool Token0/Token1 (sem ETH)
   - Mesmo hook, mas pool diferente

2. **Inicializar e Adicionar Liquidez:**
   - Cria a pool
   - Alice adiciona liquidez

3. **Fazer Swap:**
   - Bob troca Token0 por Token1
   - Nenhum token é ETH

4. **Verificação:**
   - Bob não deve receber pontos
   - O hook só distribui pontos para swaps com ETH

**O que testa:**
- O hook só funciona com ETH
- Swaps sem ETH não geram pontos
- Isso é o comportamento esperado

**Resultado esperado:**
- ✅ Bob não recebe pontos
- ✅ Pontos antes = pontos depois

---

## 🔄 Fluxo Completo de um Teste

Vamos ver o fluxo completo de `test_PointsAfterSwap`:

```
┌─────────────────────────────────────────────────────────┐
│              test_PointsAfterSwap()                     │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  1. setUp() (chamado automaticamente)                   │
│     - Cria fork da mainnet                              │
│     - Deploy hook                                       │
│     - Cria pool                                         │
│     - Dá tokens para usuários                           │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  2. addLiquidity(alice, 10 ETH, 10 Token0)              │
│     - Alice aprova tokens                               │
│     - Alice envia ETH                                    │
│     - Router chama PoolManager                          │
│     - PoolManager chama Hook.afterAddLiquidity()        │
│     - Hook distribui pontos para Alice                   │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  3. Verificar pontos iniciais de Bob                    │
│     - hook.getPoints(bob) = 0                            │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  4. swap(bob, true, -1 ETH)                             │
│     - Bob envia 1 ETH                                    │
│     - Router chama PoolManager.swap()                   │
│     - PoolManager chama Hook.afterSwap()                │
│     - Hook calcula pontos (1 ETH = 1 ponto)              │
│     - Hook.mint(bob, 1 ETH)                             │
│     - Bob recebe 1 ETH em pontos!                       │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  5. Verificar resultado                                 │
│     - hook.getPoints(bob) = 1 ETH ✅                    │
│     - pointsToken.balanceOf(bob) = 1 ETH ✅              │
└─────────────────────────────────────────────────────────┘
```

---

## 🎓 Conceitos Importantes

### 1. Fork da Mainnet

**O que é:**
- Uma cópia do estado atual da Ethereum mainnet
- Permite testar contra contratos reais

**Por quê usar:**
- Testa contra código real em produção
- Não precisa manter nosso próprio PoolManager
- Mais confiável que mocks

**Como funciona:**
```solidity
mainnetFork = vm.createFork(RPC_URL);
vm.selectFork(mainnetFork);
manager = IPoolManager(POOL_MANAGER_MAINNET);
```

### 2. Hook Flags e Endereços

**O que são:**
- Os últimos bits do endereço do hook indicam permissões
- `AFTER_SWAP_FLAG`: Hook é chamado após swaps
- `AFTER_ADD_LIQUIDITY_FLAG`: Hook é chamado após adicionar liquidez

**Por quê:**
- Otimização de gas
- Verifica permissões sem chamada externa
- Permite verificar se hook tem permissão apenas olhando o endereço

**Como calcular:**
```solidity
address hookAddress = address(
    uint160(
        type(uint160).max & clearAllHookPermissionsMask 
        | Hooks.AFTER_SWAP_FLAG 
        | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    )
);
```

### 3. vm.etch

**O que é:**
- Cheatcode do Foundry que coloca código em um endereço específico
- Não executa o construtor

**Por quê usar:**
- Precisamos que o hook esteja no endereço exato com flags
- O bytecode já tem os valores `immutable` (manager, pointsToken)

**Como usar:**
```solidity
PointsHookTest tempHook = new PointsHookTest(manager, pointsToken);
bytes memory hookCode = address(tempHook).code;
vm.etch(hookAddress, hookCode);
hook = PointsHook(payable(hookAddress));
```

### 4. hookData

**O que é:**
- Dados passados do router para o hook
- Permite passar informações adicionais

**Por quê usar:**
- O router chama o PoolManager, que chama o hook
- Sem `hookData`, o hook veria o router como `msg.sender`
- Com `hookData`, podemos passar o usuário real

**Como usar:**
```solidity
bytes memory hookData = abi.encode(user);
swapRouter.swap(..., hookData);

// No hook:
address originalSender = abi.decode(hookData, (address));
```

### 5. vm.startPrank / vm.stopPrank

**O que são:**
- Cheatcodes do Foundry para simular chamadas
- `vm.startPrank(user)`: Próximas chamadas serão como se fossem de `user`
- `vm.stopPrank()`: Para de simular

**Por quê usar:**
- Em testes, queremos simular que diferentes usuários fazem chamadas
- Permite testar permissões e comportamentos diferentes

**Como usar:**
```solidity
vm.startPrank(bob);
token.approve(...);
swapRouter.swap(...);
vm.stopPrank();
```

### 6. Assertions

**Tipos de assertions:**
- `assertEq(a, b)`: `a` deve ser igual a `b`
- `assertGt(a, b)`: `a` deve ser maior que `b`
- `assertGe(a, b)`: `a` deve ser maior ou igual a `b`
- `assertLt(a, b)`: `a` deve ser menor que `b`
- `assertLe(a, b)`: `a` deve ser menor ou igual a `b`

**Por quê usar:**
- Verificam que o código funciona como esperado
- Se uma assertion falha, o teste falha
- Mensagens de erro ajudam a debugar

---

## 📊 Resumo dos Testes

| Teste | O que testa | Resultado Esperado |
|-------|-------------|-------------------|
| `test_HookDeployment` | Hook foi deployado corretamente | Hook tem referências corretas |
| `test_PointsAfterSwap` | Pontos após swap | Usuário recebe pontos = valor do swap |
| `test_PointsAfterAddLiquidity` | Pontos após adicionar liquidez | Usuário recebe pontos > 0 |
| `test_MultipleSwapsAccumulatePoints` | Múltiplos swaps acumulam | Pontos somam: 1 + 2 + 0.5 = 3.5 |
| `test_DifferentUsersGetSeparatePoints` | Usuários têm pontos separados | Alice e Bob têm pontos independentes |
| `test_PoolVolumeTracking` | Volume da pool é rastreado | Volume aumenta com cada swap |
| `test_ReverseSwap` | Swap na direção oposta funciona | Pontos aumentam em ambas direções |
| `test_EventsEmitted` | Eventos são emitidos | Evento `PointsAwarded` é emitido |
| `test_NoPointsForNonETHSwaps` | Swaps sem ETH não geram pontos | Nenhum ponto para swaps Token/Token |

---

## 🎯 Como Executar os Testes

### Comando Básico

```bash
forge test
```

### Comando com Verbose

```bash
forge test -vvv
```

### Comando para Teste Específico

```bash
forge test --match-test test_PointsAfterSwap -vvv
```

### Configurar RPC

No arquivo `.env`:
```
ETHEREUM_MAINNET_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
```

---

## 🔍 Dicas para Entender os Testes

### 1. Leia na Ordem

Os testes estão organizados do mais simples para o mais complexo:
1. `test_HookDeployment` - Mais simples
2. `test_PointsAfterSwap` - Básico
3. `test_MultipleSwapsAccumulatePoints` - Acumulação
4. `test_DifferentUsersGetSeparatePoints` - Múltiplos usuários
5. `test_NoPointsForNonETHSwaps` - Caso especial

### 2. Entenda o Fixture Primeiro

Antes de entender os testes, entenda o `UniswapV4ForkFixture`:
- O que ele faz no `setUp()`
- Como funciona `addLiquidity()`
- Como funciona `swap()`

### 3. Use Debugging

Se um teste falhar:
- Use `-vvv` para ver logs detalhados
- Adicione `console.log` para debugar
- Verifique se o RPC está configurado

### 4. Visualize o Fluxo

Para cada teste, desenhe o fluxo:
- Quem chama o quê
- Quais contratos são envolvidos
- Onde os pontos são distribuídos

---

## 📚 Próximos Passos

Depois de entender os testes, você pode:

1. **Adicionar novos testes:**
   - Testar casos extremos
   - Testar edge cases
   - Testar erros

2. **Modificar o hook:**
   - Adicionar novas funcionalidades
   - Mudar a lógica de pontos
   - Adicionar validações

3. **Explorar mais:**
   - Ver outros hooks da Uniswap V4
   - Entender outros tipos de testes
   - Aprender mais sobre Foundry

---

**Bons estudos! 🎓**

