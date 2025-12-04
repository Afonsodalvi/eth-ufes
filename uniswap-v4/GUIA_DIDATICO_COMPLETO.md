# 📚 Guia Didático Completo - Uniswap V4 Points Hook

## 🎯 Objetivo

Este guia explica de forma didática e visual como funciona o sistema de pontos (Points Hook) no Uniswap V4, desde a configuração até a execução dos testes.

---

## 📋 Índice

1. [Visão Geral do Sistema](#visão-geral-do-sistema)
2. [Fluxo Completo de Setup](#fluxo-completo-de-setup)
3. [Fluxo de Adição de Liquidez](#fluxo-de-adição-de-liquidez)
4. [Fluxo de Swap](#fluxo-de-swap)
5. [Estrutura dos Arquivos](#estrutura-dos-arquivos)
6. [Guia Passo a Passo para Remix IDE](#guia-passo-a-passo-para-remix-ide)

---

## 🎨 Visão Geral do Sistema

### Diagrama de Alto Nível

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA DE PONTOS UNISWAP V4                 │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
    │   Usuário    │         │   PoolManager│         │ Points Hook  │
    │   (Alice)    │         │   (Mainnet)  │         │  (Custom)    │
    └──────┬───────┘         └──────┬───────┘         └──────┬───────┘
           │                        │                        │
           │ 1. Adiciona Liquidez  │                        │
           ├───────────────────────>│                        │
           │                        │                        │
           │                        │ 2. Chama Hook         │
           │                        ├───────────────────────>│
           │                        │                        │
           │                        │                        │ 3. Calcula Pontos
           │                        │                        │    e Distribui
           │                        │                        │
           │                        │ 4. Retorna            │
           │                        │<───────────────────────┤
           │                        │                        │
           │ 5. Confirma            │                        │
           │<───────────────────────┤                        │
           │                        │                        │
           │                        │                        │
           │ 6. Faz Swap            │                        │
           ├───────────────────────>│                        │
           │                        │                        │
           │                        │ 7. Chama Hook         │
           │                        ├───────────────────────>│
           │                        │                        │
           │                        │                        │ 8. Calcula Pontos
           │                        │                        │    e Distribui
           │                        │                        │
           │                        │ 9. Retorna            │
           │                        │<───────────────────────┤
           │                        │                        │
           │ 10. Confirma           │                        │
           │<───────────────────────┤                        │
           │                        │                        │
           │                        │                        │
           └────────────────────────┴────────────────────────┘
                    │                        │
                    │                        │
           ┌────────▼────────┐      ┌────────▼────────┐
           │  Points Token   │      │  Pool Volume    │
           │  (ERC20)        │      │  (Tracking)     │
           └─────────────────┘      └─────────────────┘
```

### Componentes Principais

1. **PoolManager** (Mainnet): Contrato oficial da Uniswap V4 que gerencia todas as pools
2. **PointsHook**: Nosso hook customizado que distribui pontos
3. **PointsToken**: Token ERC20 que representa os pontos
4. **Test Routers**: Contratos auxiliares para facilitar testes

---

## 🔄 Fluxo Completo de Setup

### Diagrama do setUp()

```
┌─────────────────────────────────────────────────────────────────┐
│                    setUp() - Configuração Inicial                │
└─────────────────────────────────────────────────────────────────┘

1. CRIAR FORK DO MAINNET
   ┌─────────────────────────────────────┐
   │ vm.createFork(ETHEREUM_MAINNET_RPC) │
   │ vm.selectFork(mainnetFork)           │
   └──────────────┬──────────────────────┘
                  │
                  ▼
2. CONFIGURAR POOL MANAGER
   ┌─────────────────────────────────────┐
   │ manager = IPoolManager(             │
   │   0x000000000004444c5dc75cB358...   │
   │ )                                   │
   └──────────────┬──────────────────────┘
                  │
                  ▼
3. DEPLOY ROUTERS DE TESTE
   ┌─────────────────────────────────────┐
   │ swapRouter = new PoolSwapTest()     │
   │ modifyLiquidityRouter = new ...     │
   │ (outros routers)                    │
   └──────────────┬──────────────────────┘
                  │
                  ▼
4. CALCULAR ENDEREÇO DO HOOK
   ┌─────────────────────────────────────┐
   │ hookAddress = address com flags:   │
   │   - AFTER_SWAP_FLAG                │
   │   - AFTER_ADD_LIQUIDITY_FLAG        │
   └──────────────┬──────────────────────┘
                  │
                  ▼
5. DEPLOY POINTS TOKEN
   ┌─────────────────────────────────────┐
   │ pointsToken = new PointsToken(      │
   │   hookAddress  // Owner = Hook      │
   │ )                                   │
   └──────────────┬──────────────────────┘
                  │
                  ▼
6. DEPLOY HOOK
   ┌─────────────────────────────────────┐
   │ tempHook = new PointsHookTest()      │
   │ hookCode = address(tempHook).code    │
   │ vm.etch(hookAddress, hookCode)       │
   │ hook = PointsHook(hookAddress)       │
   └──────────────┬──────────────────────┘
                  │
                  ▼
7. VERIFICAR CONFIGURAÇÃO
   ┌─────────────────────────────────────┐
   │ require(hook.pointsToken() == ...)  │
   │ require(pointsToken.owner() == ...) │
   │ require(permissions correct)       │
   └──────────────┬──────────────────────┘
                  │
                  ▼
8. CRIAR POOL KEY
   ┌─────────────────────────────────────┐
   │ poolKey = PoolKey({                  │
   │   currency0: ETH (address(0))       │
   │   currency1: Token0                  │
   │   fee: 3000 (0.3%)                  │
   │   tickSpacing: 60                   │
   │   hooks: hook                        │
   │ })                                   │
   └──────────────┬──────────────────────┘
                  │
                  ▼
9. INICIALIZAR POOL
   ┌─────────────────────────────────────┐
   │ manager.initialize(poolKey,          │
   │   initSqrtPriceX96)                 │
   └──────────────┬──────────────────────┘
                  │
                  ▼
10. PREPARAR USUÁRIOS DE TESTE
   ┌─────────────────────────────────────┐
   │ vm.deal(alice, 100 ether)           │
   │ vm.deal(bob, 100 ether)             │
   │ token0.mint(alice, 1000e18)         │
   │ token0.mint(bob, 1000e18)           │
   └─────────────────────────────────────┘
```

### Explicação Detalhada do Setup

#### 1. Fork do Mainnet
```solidity
ETHEREUM_MAINNET_RPC = vm.envString("ETHEREUM_MAINNET_RPC");
mainnetFork = vm.createFork(ETHEREUM_MAINNET_RPC);
vm.selectFork(mainnetFork);
```

**Por quê?**
- Usamos o PoolManager oficial do mainnet
- Não precisamos deployar nosso próprio PoolManager
- Testamos com contratos reais da Uniswap

#### 2. Endereço do Hook com Flags
```solidity
address hookAddress = address(
    uint160(
        type(uint160).max & clearAllHookPermissionsMask 
        | Hooks.AFTER_SWAP_FLAG 
        | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    )
);
```

**Como funciona?**
- Os últimos bits do endereço indicam quais hooks estão ativos
- `AFTER_SWAP_FLAG`: Hook é chamado após swaps
- `AFTER_ADD_LIQUIDITY_FLAG`: Hook é chamado após adicionar liquidez
- O PoolManager verifica esses flags antes de chamar o hook

#### 3. Deploy do Hook com vm.etch
```solidity
PointsHookTest tempHook = new PointsHookTest(manager, pointsToken);
bytes memory hookCode = address(tempHook).code;
vm.etch(hookAddress, hookCode);
hook = PointsHook(payable(hookAddress));
```

**Por quê vm.etch?**
- Precisamos que o hook esteja no endereço exato com as flags corretas
- `vm.etch` coloca código em um endereço específico
- Os valores `immutable` (poolManager, pointsToken) já estão no bytecode

---

## 💧 Fluxo de Adição de Liquidez

### Diagrama Completo

```
┌─────────────────────────────────────────────────────────────────┐
│              addLiquidity() - Adicionar Liquidez               │
└─────────────────────────────────────────────────────────────────┘

USUÁRIO (Alice)                    ROUTER                    POOL MANAGER                    HOOK
     │                              │                            │                            │
     │ 1. approve(token0)           │                            │                            │
     ├─────────────────────────────>│                            │                            │
     │                              │                            │                            │
     │ 2. modifyLiquidity{value: ETH}│                            │                            │
     ├──────────────────────────────>│                            │                            │
     │                              │                            │                            │
     │                              │ 3. unlock()                │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │ 4. unlockCallback()        │                            │
     │                              │<───────────────────────────┤                            │
     │                              │                            │                            │
     │                              │ 5. modifyLiquidity()      │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │                            │ 6. afterAddLiquidity()    │
     │                              │                            ├───────────────────────────>│
     │                              │                            │                            │
     │                              │                            │                            │ 7. Calcular pontos
     │                              │                            │                            │    - Pegar delta
     │                              │                            │                            │    - Calcular valor em ETH
     │                              │                            │                            │    - Calcular pontos
     │                              │                            │                            │
     │                              │                            │                            │ 8. Distribuir pontos
     │                              │                            │                            │    - userPoints[user] += points
     │                              │                            │                            │    - pointsToken.mint(user, points)
     │                              │                            │                            │    - emit PointsAwarded()
     │                              │                            │                            │
     │                              │                            │ 9. Retorna (selector, delta)│
     │                              │                            │<───────────────────────────┤
     │                              │                            │                            │
     │                              │ 10. settle() (ETH)         │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │ 11. Retorna                │                            │
     │                              │<───────────────────────────┤                            │
     │                              │                            │                            │
     │ 12. Confirma                 │                            │                            │
     │<─────────────────────────────┤                            │                            │
     │                              │                            │                            │
```

### Código Passo a Passo

#### Passo 1: Usuário aprova tokens
```solidity
if (Currency.unwrap(poolKey.currency0) != address(0)) {
    MockERC20(Currency.unwrap(poolKey.currency0)).approve(
        address(modifyLiquidityRouter), 
        amount0
    );
}
```

#### Passo 2: Calcular ETH necessário
```solidity
uint256 ethToSend = 0;
if (Currency.unwrap(poolKey.currency0) == address(0)) {
    ethToSend = amount0;  // currency0 é ETH
}
```

#### Passo 3: Preparar hookData
```solidity
bytes memory hookData = abi.encode(user);
// Passa o usuário original para o hook rastrear corretamente
```

#### Passo 4: Chamar modifyLiquidity
```solidity
modifyLiquidityRouter.modifyLiquidity{value: ethToSend}(
    poolKey,
    IPoolManager.ModifyLiquidityParams({...}),
    hookData
);
```

#### Passo 5: Hook processa (dentro do PointsHook)
```solidity
function _afterAddLiquidity(...) {
    // 1. Calcular valor em ETH
    uint256 liquidityValue = _calculateLiquidityValue(key, delta);
    
    // 2. Calcular pontos (1 ETH = 1 ponto)
    uint256 points = _calculatePoints(liquidityValue);
    
    // 3. Extrair usuário do hookData
    address recipient = sender;
    if (hookData.length == 32) {
        recipient = abi.decode(hookData, (address));
    }
    
    // 4. Distribuir pontos
    userPoints[recipient] += points;
    pointsToken.mint(recipient, points);
    emit PointsAwarded(recipient, points, "liquidity");
}
```

---

## 🔄 Fluxo de Swap

### Diagrama Completo

```
┌─────────────────────────────────────────────────────────────────┐
│                      swap() - Executar Swap                     │
└─────────────────────────────────────────────────────────────────┘

USUÁRIO (Bob)                      ROUTER                    POOL MANAGER                    HOOK
     │                              │                            │                            │
     │ 1. swap{value: ETH}          │                            │                            │
     ├──────────────────────────────>│                            │                            │
     │                              │                            │                            │
     │                              │ 2. unlock()                │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │ 3. unlockCallback()        │                            │
     │                              │<───────────────────────────┤                            │
     │                              │                            │                            │
     │                              │ 4. swap()                  │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │                            │ 5. afterSwap()             │
     │                              │                            ├───────────────────────────>│
     │                              │                            │                            │
     │                              │                            │                            │ 6. Calcular valor
     │                              │                            │                            │    - Pegar delta
     │                              │                            │                            │    - Verificar qual currency é ETH
     │                              │                            │                            │    - Calcular valor absoluto
     │                              │                            │                            │
     │                              │                            │                            │ 7. Atualizar volume
     │                              │                            │                            │    - poolVolume[poolId] += value
     │                              │                            │                            │
     │                              │                            │                            │ 8. Calcular pontos
     │                              │                            │                            │    - points = value (1:1)
     │                              │                            │                            │
     │                              │                            │                            │ 9. Distribuir pontos
     │                              │                            │                            │    - userPoints[user] += points
     │                              │                            │                            │    - pointsToken.mint(user, points)
     │                              │                            │                            │    - emit PointsAwarded()
     │                              │                            │                            │    - emit VolumeRecorded()
     │                              │                            │                            │
     │                              │                            │ 10. Retorna (selector, 0)  │
     │                              │                            │<───────────────────────────┤
     │                              │                            │                            │
     │                              │ 11. settle() (ETH)         │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │ 12. take() (Token0)        │                            │
     │                              ├───────────────────────────>│                            │
     │                              │                            │                            │
     │                              │ 13. Retorna                │                            │
     │                              │<───────────────────────────┤                            │
     │                              │                            │                            │
     │ 14. Confirma                 │                            │                            │
     │<─────────────────────────────┤                            │                            │
     │                              │                            │                            │
```

### Código Passo a Passo

#### Passo 1: Preparar hookData
```solidity
bytes memory hookData = abi.encode(user);
// Passa o usuário original para o hook
```

#### Passo 2: Executar swap
```solidity
if (zeroForOne) {
    // ETH → Token0
    swapRouter.swap{value: uint256(-amountSpecified)}(
        poolKey,
        IPoolManager.SwapParams({...}),
        settings,
        hookData
    );
}
```

#### Passo 3: Hook processa (dentro do PointsHook)
```solidity
function _afterSwap(...) {
    // 1. Calcular valor do swap em ETH
    uint256 swapValue = _calculateSwapValue(key, delta);
    // Se currency0 é ETH, pega amount0
    // Se currency1 é ETH, pega amount1
    
    // 2. Atualizar volume
    PoolId poolId = key.toId();
    poolVolume[poolId] += swapValue;
    
    // 3. Calcular pontos (1 ETH = 1 ponto)
    uint256 points = swapValue;
    
    // 4. Extrair usuário do hookData
    address recipient = sender;
    if (hookData.length == 32) {
        recipient = abi.decode(hookData, (address));
    }
    
    // 5. Distribuir pontos
    userPoints[recipient] += points;
    pointsToken.mint(recipient, points);
    emit PointsAwarded(recipient, points, "swap");
    emit VolumeRecorded(poolId, swapValue);
}
```

---

## 📁 Estrutura dos Arquivos

### UniswapV4ForkFixture.sol

```
UniswapV4ForkFixture
│
├── Constantes
│   └── POOL_MANAGER_MAINNET: Endereço oficial
│
├── Variáveis de Estado
│   ├── hook: Nosso hook customizado
│   ├── pointsToken: Token de pontos
│   ├── token0, token1: Tokens de teste
│   ├── poolKey: Configuração da pool
│   ├── poolId: ID único da pool
│   └── alice, bob: Usuários de teste
│
├── setUp()
│   └── Configura tudo necessário para os testes
│
├── addLiquidity()
│   └── Adiciona liquidez à pool
│
└── swap()
    └── Executa um swap na pool
```

### PointsHook.t.sol

```
PointsHookTest
│
├── setUp()
│   └── Chama super.setUp() do fixture
│
├── test_HookDeployment()
│   └── Verifica se hook foi deployado corretamente
│
├── test_PointsAfterSwap()
│   └── Testa distribuição de pontos após swap
│
├── test_PointsAfterAddLiquidity()
│   └── Testa distribuição de pontos após adicionar liquidez
│
├── test_MultipleSwapsAccumulatePoints()
│   └── Testa que múltiplos swaps acumulam pontos
│
├── test_DifferentUsersGetSeparatePoints()
│   └── Testa que diferentes usuários têm pontos separados
│
├── test_PoolVolumeTracking()
│   └── Testa rastreamento de volume da pool
│
├── test_ReverseSwap()
│   └── Testa swap na direção oposta
│
├── test_EventsEmitted()
│   └── Testa eventos emitidos
│
└── test_NoPointsForNonETHSwaps()
    └── Testa que swaps sem ETH não geram pontos
```

---

## 🎓 Conceitos Importantes

### 1. Hooks no Uniswap V4

**O que são?**
- Contratos que são chamados automaticamente pelo PoolManager em momentos específicos
- Permitem adicionar lógica customizada ao ciclo de vida das operações

**Quando são chamados?**
- `beforeSwap`: Antes de um swap
- `afterSwap`: Depois de um swap
- `beforeAddLiquidity`: Antes de adicionar liquidez
- `afterAddLiquidity`: Depois de adicionar liquidez
- E outros...

**Como funcionam?**
- O endereço do hook tem flags nos últimos bits
- O PoolManager verifica essas flags antes de chamar
- Se a flag estiver ativa, o hook é chamado

### 2. Flash Accounting (EIP-1153)

**O que é?**
- Sistema de contabilidade temporária durante operações
- Permite que o PoolManager "empreste" tokens durante uma operação
- No final, tudo é "settled" (acertado)

**Por quê?**
- Permite operações complexas sem precisar transferir tokens múltiplas vezes
- Mais eficiente em gas

### 3. BalanceDelta

**O que é?**
- Representa mudanças de saldo durante uma operação
- Pode ser positivo (entrada) ou negativo (saída)

**Exemplo:**
```solidity
BalanceDelta delta = -1 ether;  // 1 ETH saiu
int128 amount0 = delta.amount0();  // -1 ether
```

### 4. Fork Testing

**O que é?**
- Criar uma cópia do estado do blockchain em um ponto específico
- Permite testar com contratos reais sem gastar gas real

**Vantagens:**
- Testa com contratos oficiais
- Não precisa deployar tudo
- Mais rápido e barato

---

## 🔍 Detalhes Técnicos Importantes

### Por que usar hookData?

**Problema:**
- O `sender` recebido pelo hook é o router, não o usuário final
- Precisamos rastrear o usuário real para distribuir pontos corretamente

**Solução:**
- Passamos o usuário original através do `hookData`
- O hook extrai o usuário do `hookData` se disponível
- Caso contrário, usa o `sender` (comportamento padrão)

### Por que vm.etch?

**Problema:**
- O hook precisa estar em um endereço específico com flags corretas
- Não podemos simplesmente fazer `new PointsHook()` porque o endereço seria aleatório

**Solução:**
- Calculamos o endereço correto com as flags
- Deployamos o hook em um endereço temporário
- Copiamos o bytecode para o endereço correto com `vm.etch`
- Os valores `immutable` já estão no bytecode, então funcionam

### Por que PointsToken precisa ter hook como owner?

**Problema:**
- O hook precisa fazer `mint()` no PointsToken
- O PointsToken usa `onlyOwner` para `mint()`

**Solução:**
- Deployamos PointsToken com o hook como owner desde o início
- Assim, quando o hook chama `mint()`, ele já é o owner

---

## 📊 Resumo Visual do Fluxo Completo

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO COMPLETO                           │
└─────────────────────────────────────────────────────────────┘

SETUP
  │
  ├─> Fork Mainnet
  ├─> Configurar PoolManager
  ├─> Deploy Routers
  ├─> Calcular Hook Address
  ├─> Deploy PointsToken (hook como owner)
  ├─> Deploy Hook (vm.etch)
  ├─> Criar Pool
  └─> Preparar Usuários

ADICIONAR LIQUIDEZ
  │
  ├─> Usuário aprova tokens
  ├─> Usuário chama modifyLiquidity (com ETH se necessário)
  ├─> Router → PoolManager
  ├─> PoolManager → Hook (afterAddLiquidity)
  ├─> Hook calcula pontos
  ├─> Hook distribui pontos
  └─> PoolManager faz settle

SWAP
  │
  ├─> Usuário chama swap (com ETH se necessário)
  ├─> Router → PoolManager
  ├─> PoolManager → Hook (afterSwap)
  ├─> Hook calcula valor em ETH
  ├─> Hook atualiza volume
  ├─> Hook calcula pontos
  ├─> Hook distribui pontos
  └─> PoolManager faz settle/take
```

---

## 🎯 Próximos Passos

1. **Ler o código**: Entender cada linha dos arquivos principais
2. **Executar testes**: Ver os testes em ação
3. **Modificar**: Tentar adicionar novas funcionalidades
4. **Deploy**: Preparar para deploy em testnet/mainnet

---

## 📚 Recursos Adicionais

- [Documentação Uniswap V4](https://docs.uniswap.org/contracts/v4/overview)
- [Guia de Hooks](https://docs.uniswap.org/contracts/v4/guides/hooks/your-first-hook)
- [Foundry Book](https://book.getfoundry.sh/)

---

**Criado com ❤️ para ensino e aprendizado**

