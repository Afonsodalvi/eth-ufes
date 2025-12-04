# 🎨 Diagramas Visuais - Sistema de Pontos Uniswap V4

## 📐 Diagrama de Arquitetura Completa

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ARQUITETURA DO SISTEMA                         │
└─────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │   Ethereum Mainnet   │
                    │  (Fork para Testes)  │
                    └──────────┬───────────┘
                               │
                               │ Usa contrato oficial
                               ▼
                    ┌──────────────────────┐
                    │    PoolManager       │
                    │  (Uniswap V4 Core)   │
                    │  0x000000000004...   │
                    └──────────┬───────────┘
                               │
                               │ Chama hooks automaticamente
                               ▼
                    ┌──────────────────────┐
                    │    Points Hook       │
                    │   (Nosso Contrato)   │
                    │  Com flags nos bits  │
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │ Points Token  │ │ User Points   │ │ Pool Volume   │
    │   (ERC20)     │ │  (Mapping)    │ │  (Mapping)    │
    └───────────────┘ └───────────────┘ └───────────────┘
```

---

## 🔄 Fluxo de Setup Detalhado

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUXO DE SETUP (setUp)                       │
└─────────────────────────────────────────────────────────────────┘

INÍCIO
  │
  ├─┐
  │ │ 1. CRIAR FORK
  │ │    ┌────────────────────────────┐
  │ │    │ vm.createFork(RPC_URL)     │
  │ │    │ vm.selectFork(forkId)      │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ │                 ▼
  │ │    ┌────────────────────────────┐
  │ │    │ Estado do Mainnet copiado  │
  │ │    │ PoolManager disponível     │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 2. CONFIGURAR POOL MANAGER
  │ │    ┌────────────────────────────┐
  │ │    │ manager = IPoolManager(    │
  │ │    │   0x000000000004444...     │
  │ │    │ )                          │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 3. DEPLOY ROUTERS
  │ │    ┌────────────────────────────┐
  │ │    │ swapRouter                 │
  │ │    │ modifyLiquidityRouter      │
  │ │    │ (outros routers...)        │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 4. CALCULAR HOOK ADDRESS
  │ │    ┌────────────────────────────┐
  │ │    │ hookAddress =               │
  │ │    │   address com flags:       │
  │ │    │   - AFTER_SWAP_FLAG        │
  │ │    │   - AFTER_ADD_LIQUIDITY    │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ │                 ▼
  │ │    ┌────────────────────────────┐
  │ │    │ Exemplo:                   │
  │ │    │ 0xfFfFFfffFFFFF...c440      │
  │ │    │ (últimos bits = flags)     │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 5. DEPLOY POINTS TOKEN
  │ │    ┌────────────────────────────┐
  │ │    │ pointsToken =               │
  │ │    │   new PointsToken(          │
  │ │    │     hookAddress  // Owner  │
  │ │    │   )                         │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 6. DEPLOY HOOK
  │ │    ┌────────────────────────────┐
  │ │    │ tempHook =                 │
  │ │    │   new PointsHookTest(...)  │
  │ │    │ hookCode =                 │
  │ │    │   address(tempHook).code   │
  │ │    │ vm.etch(                   │
  │ │    │   hookAddress,             │
  │ │    │   hookCode                 │
  │ │    │ )                          │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ │                 ▼
  │ │    ┌────────────────────────────┐
  │ │    │ Hook agora está no         │
  │ │    │ endereço correto com flags │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 7. VERIFICAR CONFIGURAÇÃO
  │ │    ┌────────────────────────────┐
  │ │    │ require(                   │
  │ │    │   hook.pointsToken() ==     │
  │ │    │   pointsToken              │
  │ │    │ )                          │
  │ │    │ require(                   │
  │ │    │   pointsToken.owner() ==   │
  │ │    │   hook                     │
  │ │    │ )                          │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  ├─┐
  │ │ 8. CRIAR POOL
  │ │    ┌────────────────────────────┐
  │ │    │ poolKey = {                │
  │ │    │   currency0: ETH            │
  │ │    │   currency1: Token0         │
  │ │    │   fee: 3000                │
  │ │    │   hooks: hook              │
  │ │    │ }                          │
  │ │    │ manager.initialize(...)    │
  │ │    └────────────┬───────────────┘
  │ │                 │
  │ └─────────────────┘
  │
  └─> FIM (Setup completo)
```

---

## 💧 Fluxo de Adição de Liquidez (Sequência Temporal)

```
TEMPO ───────────────────────────────────────────────────────────>

USUÁRIO          ROUTER          POOL MANAGER        HOOK
  │                │                  │                │
  │ approve()      │                  │                │
  ├───────────────>│                  │                │
  │                │                  │                │
  │ modifyLiquidity│                  │                │
  │ {value: ETH}   │                  │                │
  ├───────────────>│                  │                │
  │                │                  │                │
  │                │ unlock()         │                │
  │                ├─────────────────>│                │
  │                │                  │                │
  │                │ unlockCallback()  │                │
  │                │<─────────────────┤                │
  │                │                  │                │
  │                │ modifyLiquidity()│                │
  │                ├─────────────────>│                │
  │                │                  │                │
  │                │                  │ afterAddLiquidity()
  │                │                  ├────────────────>│
  │                │                  │                │
  │                │                  │                │ ┌─────────┐
  │                │                  │                │ │ Calcular│
  │                │                  │                │ │ Pontos  │
  │                │                  │                │ └────┬────┘
  │                │                  │                │      │
  │                │                  │                │ ┌────▼────┐
  │                │                  │                │ │ Distrib.│
  │                │                  │                │ │ Pontos  │
  │                │                  │                │ └────┬────┘
  │                │                  │                │      │
  │                │                  │ (selector, 0) │      │
  │                │                  │<──────────────┤      │
  │                │                  │                │      │
  │                │ settle(ETH)     │                │      │
  │                ├─────────────────>│                │      │
  │                │                  │                │      │
  │ Confirma        │                  │                │      │
  │<───────────────┤                  │                │      │
  │                │                  │                │      │
```

---

## 🔄 Fluxo de Swap (Sequência Temporal)

```
TEMPO ───────────────────────────────────────────────────────────>

USUÁRIO          ROUTER          POOL MANAGER        HOOK
  │                │                  │                │
  │ swap()         │                  │                │
  │ {value: ETH}   │                  │                │
  ├───────────────>│                  │                │
  │                │                  │                │
  │                │ unlock()         │                │
  │                ├─────────────────>│                │
  │                │                  │                │
  │                │ unlockCallback() │                │
  │                │<─────────────────┤                │
  │                │                  │                │
  │                │ swap()           │                │
  │                ├─────────────────>│                │
  │                │                  │                │
  │                │                  │ afterSwap()    │
  │                │                  ├────────────────>│
  │                │                  │                │
  │                │                  │                │ ┌─────────┐
  │                │                  │                │ │ Calcular│
  │                │                  │                │ │ Valor   │
  │                │                  │                │ └────┬────┘
  │                │                  │                │      │
  │                │                  │                │ ┌────▼────┐
  │                │                  │                │ │ Atualizar│
  │                │                  │                │ │ Volume   │
  │                │                  │                │ └────┬────┘
  │                │                  │                │      │
  │                │                  │                │ ┌────▼────┐
  │                │                  │                │ │ Calcular│
  │                │                  │                │ │ Pontos  │
  │                │                  │                │ └────┬────┘
  │                │                  │                │      │
  │                │                  │                │ ┌────▼────┐
  │                │                  │                │ │ Distrib.│
  │                │                  │                │ │ Pontos  │
  │                │                  │                │ └────┬────┘
  │                │                  │                │      │
  │                │                  │ (selector, 0) │      │
  │                │                  │<──────────────┤      │
  │                │                  │                │      │
  │                │ settle(ETH)     │                │      │
  │                ├─────────────────>│                │      │
  │                │                  │                │      │
  │                │ take(Token0)     │                │      │
  │                ├─────────────────>│                │      │
  │                │                  │                │      │
  │ Confirma        │                  │                │      │
  │<───────────────┤                  │                │      │
  │                │                  │                │      │
```

---

## 🎯 Diagrama de Estados

### Estado do Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    ESTADOS DO SISTEMA                   │
└─────────────────────────────────────────────────────────┘

INICIAL
  │
  │ setUp() executado
  │
  ▼
┌─────────────────┐
│  CONFIGURADO    │
│                 │
│ - Pool criada   │
│ - Hook ativo    │
│ - Tokens prontos│
└────────┬────────┘
         │
         │ Usuário faz operação
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌──────────────┐   ┌──────────────┐
│ ADICIONANDO  │   │   SWAPPING   │
│  LIQUIDEZ    │   │              │
│              │   │              │
│ - Aprova     │   │ - Envia ETH  │
│ - Envia ETH  │   │ - Recebe TKN │
│ - Hook chama │   │ - Hook chama │
└──────┬───────┘   └──────┬───────┘
       │                  │
       │                  │
       └────────┬──────────┘
                │
                │ Hook processa
                │
                ▼
┌─────────────────┐
│ DISTRIBUINDO    │
│    PONTOS       │
│                 │
│ - Calcula       │
│ - Atualiza      │
│ - Emite evento  │
└────────┬────────┘
         │
         │ Pontos distribuídos
         │
         ▼
┌─────────────────┐
│   CONCLUÍDO     │
│                 │
│ - Pontos dados  │
│ - Volume atual. │
│ - Pronto próx.  │
└─────────────────┘
```

---

## 📊 Diagrama de Dados

### Fluxo de Dados

```
┌─────────────────────────────────────────────────────────┐
│                  FLUXO DE DADOS                         │
└─────────────────────────────────────────────────────────┘

INPUT (Usuário)
  │
  │ amount: 1 ETH
  │ user: 0xAb...
  │ operation: swap
  │
  ▼
┌─────────────────┐
│   Router        │
│                 │
│ - Recebe ETH    │
│ - Prepara params│
│ - Chama Manager │
└────────┬────────┘
         │
         │ SwapParams {
         │   zeroForOne: true
         │   amountSpecified: -1e18
         │   ...
         │ }
         │
         ▼
┌─────────────────┐
│  PoolManager    │
│                 │
│ - Executa swap  │
│ - Calcula delta │
│ - Chama hook    │
└────────┬────────┘
         │
         │ BalanceDelta {
         │   amount0: -1e18
         │   amount1: +0.5e18
         │ }
         │
         ▼
┌─────────────────┐
│  Points Hook    │
│                 │
│ - Recebe delta  │
│ - Calcula valor │
│ - Calcula pontos│
└────────┬────────┘
         │
         │ points: 1e18
         │ user: 0xAb...
         │
         ▼
┌─────────────────┐
│  Points Token   │
│                 │
│ - Mint 1e18     │
│ - Para 0xAb...  │
└────────┬────────┘
         │
         │ Transfer event
         │
         ▼
OUTPUT (Usuário)
  │
  │ - Recebe 1e18 pontos
  │ - Saldo atualizado
  │ - Evento emitido
  │
```

---

## 🔐 Diagrama de Permissões

```
┌─────────────────────────────────────────────────────────┐
│                  PERMISSÕES E ACESSOS                   │
└─────────────────────────────────────────────────────────┘

┌──────────────┐
│   Usuário    │
│  (Alice/Bob) │
└──────┬───────┘
       │
       │ Pode:
       │ - Fazer swap
       │ - Adicionar liquidez
       │ - Consultar pontos
       │
       │ Não pode:
       │ - Mint pontos diretamente
       │ - Modificar hook
       │
       ▼
┌──────────────┐
│   Router     │
│  (Teste)     │
└──────┬───────┘
       │
       │ Pode:
       │ - Chamar PoolManager
       │ - Receber callbacks
       │
       │ Não pode:
       │ - Modificar estado do hook
       │
       ▼
┌──────────────┐
│ PoolManager  │
│  (Mainnet)   │
└──────┬───────┘
       │
       │ Pode:
       │ - Chamar hooks
       │ - Gerenciar pools
       │
       │ Não pode:
       │ - Modificar hooks
       │
       ▼
┌──────────────┐
│ Points Hook  │
│  (Custom)    │
└──────┬───────┘
       │
       │ Pode:
       │ - Mint PointsToken
       │ - Atualizar userPoints
       │ - Atualizar poolVolume
       │
       │ Não pode:
       │ - Modificar PoolManager
       │
       ▼
┌──────────────┐
│Points Token  │
│  (ERC20)     │
└──────────────┘
       │
       │ Owner: Points Hook
       │
       │ Apenas owner pode:
       │ - Mint tokens
       │
```

---

## 🎨 Diagrama de Endereços e Flags

```
┌─────────────────────────────────────────────────────────┐
│            ENDEREÇO DO HOOK COM FLAGS                   │
└─────────────────────────────────────────────────────────┘

Endereço do Hook (160 bits)
┌─────────────────────────────────────────────────────────┐
│                                                          │
│  Bits 159-14: Endereço base (146 bits)                  │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 0xfFfFFfffFFFFFfffffffFFffFFFffFfffFfFc440       │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  Bits 13-0: Flags de Permissão (14 bits)                 │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Bit 0:  beforeInitialize                         │   │
│  │ Bit 1:  afterInitialize                          │   │
│  │ Bit 2:  beforeAddLiquidity                       │   │
│  │ Bit 3:  afterAddLiquidity  ← ATIVO                │   │
│  │ Bit 4:  beforeRemoveLiquidity                     │   │
│  │ Bit 5:  afterRemoveLiquidity                     │   │
│  │ Bit 6:  beforeSwap                                │   │
│  │ Bit 7:  afterSwap  ← ATIVO                        │   │
│  │ Bit 8:  beforeDonate                              │   │
│  │ Bit 9:  afterDonate                                │   │
│  │ Bit 10: beforeSwapReturnDelta                     │   │
│  │ Bit 11: afterSwapReturnDelta                      │   │
│  │ Bit 12: afterAddLiquidityReturnDelta              │   │
│  │ Bit 13: afterRemoveLiquidityReturnDelta           │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘

Exemplo:
0xfFfFFfffFFFFFfffffffFFffFFFffFfffFfFc440
                    ↑↑
                    Bits 3 e 7 ativos
                    = AFTER_SWAP + AFTER_ADD_LIQUIDITY
```

---

## 📈 Diagrama de Acumulação de Pontos

```
┌─────────────────────────────────────────────────────────┐
│            ACUMULAÇÃO DE PONTOS AO LONGO DO TEMPO       │
└─────────────────────────────────────────────────────────┘

Pontos
│
│ 5 ETH ┤                                    ╭─
│       │                                    │
│ 4 ETH ┤                            ╭───────┤
│       │                            │       │
│ 3 ETH ┤                    ╭───────┤       │
│       │                    │       │       │
│ 2 ETH ┤            ╭───────┤       │       │
│       │            │       │       │       │
│ 1 ETH ┤    ╭───────┤       │       │       │
│       │    │       │       │       │       │
│  0    ┼────┼───────┼───────┼───────┼───────┼─────> Tempo
│       │    │       │       │       │       │
│       Swap Swap  Liquidity Swap   Swap   Swap
│       1    2      1        3       4      5
│
│ Eventos:
│ - Swap 1: +1 ETH pontos
│ - Swap 2: +2 ETH pontos (total: 3 ETH)
│ - Liquidez 1: +1 ETH pontos (total: 4 ETH)
│ - Swap 3: +1 ETH pontos (total: 5 ETH)
│ - ...
```

---

## 🔍 Diagrama de Verificação de Hook

```
┌─────────────────────────────────────────────────────────┐
│            VERIFICAÇÃO DE HOOK PELO POOL MANAGER       │
└─────────────────────────────────────────────────────────┘

PoolManager recebe chamada
  │
  │ PoolKey {
  │   hooks: 0xfFfFFfffFFFFF...c440
  │ }
  │
  ▼
┌─────────────────┐
│ Extrair flags   │
│ do endereço     │
└────────┬────────┘
         │
         │ flags = address & 0x3FFF
         │
         ▼
┌─────────────────┐
│ Verificar flags │
└────────┬────────┘
         │
         ├─ afterSwap flag ativo?
         │  │
         │  ├─ SIM ──> Chama hook.afterSwap()
         │  │
         │  └─ NÃO ──> Pula hook
         │
         ├─ afterAddLiquidity flag ativo?
         │  │
         │  ├─ SIM ──> Chama hook.afterAddLiquidity()
         │  │
         │  └─ NÃO ──> Pula hook
         │
         └─ Continua operação normal
```

---

## 📚 Legenda dos Símbolos

```
┌─────┐  = Processo/Contrato
│     │
└─────┘

  │     = Fluxo de dados/controle
  │
  ▼     = Direção do fluxo

  ├─    = Ramificação
  │
  └─>   = Resultado final

[Texto] = Estado ou condição

{Texto} = Estrutura de dados
```

---

**Diagramas criados para facilitar o entendimento visual do sistema! 🎨**

