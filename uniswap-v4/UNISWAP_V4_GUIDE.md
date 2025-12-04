# 🦄 Guia Completo: Uniswap V4 - Conceitos e Implementação

## 📚 Índice
1. [Visão Geral do Uniswap V4](#visão-geral)
2. [Conceitos Fundamentais](#conceitos-fundamentais)
3. [Arquitetura e Componentes](#arquitetura)
4. [Hooks: O Coração do V4](#hooks)
5. [Estrutura do Projeto Proposto](#estrutura-projeto)
6. [Fluxo de Trabalho](#fluxo-trabalho)

---

## 🎯 Visão Geral do Uniswap V4

### O que é o Uniswap V4?

O Uniswap V4 é a próxima evolução do protocolo de exchange descentralizada (DEX) mais popular do Ethereum. Ele mantém todas as melhorias de eficiência de capital do V3, mas adiciona **flexibilidade extrema** através de **hooks** e **otimizações de gas** revolucionárias.

### Principais Inovações

| Inovação | Descrição | Benefício |
|----------|-----------|-----------|
| **Hooks** | Lógica customizada no ciclo de vida das pools | Funcionalidades ilimitadas |
| **Singleton Design** | Um único contrato gerencia todas as pools | Economia massiva de gas |
| **Flash Accounting** | Usa EIP-1153 Transient Storage | Reduz transferências intermediárias |
| **Native ETH** | Suporte direto a ETH (sem WETH) | UX melhorada |
| **Dynamic Fees** | Taxas ajustáveis dinamicamente | Otimização de receitas |
| **Custom Accounting** | Modificar valores de swaps/liquidez | Curvas customizadas |

---

## 🔑 Conceitos Fundamentais

### 1. Singleton Design (Arquitetura Única)

**Antes (V2/V3):**
- Cada pool = um contrato separado
- Criar pool = deploy de novo contrato (~2M gas)
- Swap entre pools = múltiplas transferências de token

**Agora (V4):**
- Todas as pools = um único contrato (`PoolManager`)
- Criar pool = apenas atualização de estado (~50k gas)
- Swaps entre pools = netting automático (sem transferências intermediárias)

**Exemplo:**
```solidity
// V3: Criar pool = deploy novo contrato
UniswapV3Pool newPool = new UniswapV3Pool(...); // ~2M gas

// V4: Criar pool = atualizar estado
poolManager.initialize(poolKey, sqrtPriceX96); // ~50k gas
```

### 2. Flash Accounting (Contabilidade Flash)

**O que é:**
- Usa EIP-1153 Transient Storage (armazenamento temporário)
- Registra mudanças de saldo durante a execução
- Netting automático no final

**Como funciona:**
```
Swap ETH → USDC → DAI:

1. ETH sai: -1 ETH
2. USDC entra: +1000 USDC
3. USDC sai: -1000 USDC
4. DAI entra: +900 DAI

Resultado final: -1 ETH, +900 DAI
(USDC nunca é transferido fisicamente!)
```

**Benefício:**
- Reduz gas em swaps multi-hop
- Elimina necessidade de aprovações intermediárias
- Mais eficiente para arbitragem

### 3. Native ETH Support

**Antes:**
```
Usuário → Wraps ETH → WETH → Swap → Unwrap → ETH
```

**Agora:**
```
Usuário → ETH direto → Swap → ETH direto
```

**Benefício:**
- Melhor UX (sem wrap/unwrap)
- Menos transações
- Menos gas

---

## 🏗️ Arquitetura e Componentes

### Componentes Principais

```
┌─────────────────────────────────────────┐
│         PoolManager (Singleton)         │
│  - Gerencia TODAS as pools              │
│  - Executa swaps, liquidez, etc        │
│  - Chama hooks quando necessário       │
└─────────────────────────────────────────┘
                    │
                    │ chama
                    ▼
┌─────────────────────────────────────────┐
│           Hook Contract                 │
│  - Lógica customizada                   │
│  - beforeSwap, afterSwap, etc          │
│  - Pode modificar comportamento        │
└─────────────────────────────────────────┘
                    │
                    │ usa
                    ▼
┌─────────────────────────────────────────┐
│      Position Manager (Periphery)       │
│  - Interface amigável para usuários    │
│  - Gerencia posições NFT               │
│  - Facilita interações                 │
└─────────────────────────────────────────┘
```

### PoolKey (Identificador de Pool)

Cada pool é identificada por uma `PoolKey`:

```solidity
struct PoolKey {
    Currency currency0;      // Token 0 (ex: ETH)
    Currency currency1;      // Token 1 (ex: USDC)
    uint24 fee;              // Taxa (ex: 3000 = 0.3%)
    int24 tickSpacing;       // Espaçamento de ticks
    IHooks hooks;            // Endereço do hook (ou zero)
}
```

**Exemplo:**
```solidity
PoolKey memory key = PoolKey({
    currency0: Currency.wrap(address(0)), // ETH nativo
    currency1: Currency.wrap(address(USDC)),
    fee: 3000,                             // 0.3%
    tickSpacing: 60,
    hooks: IHooks(address(myHook))        // Hook customizado
});
```

### PoolId (Hash da PoolKey)

```solidity
PoolId poolId = key.toId(); // Hash único da pool
```

---

## 🎣 Hooks: O Coração do V4

### O que são Hooks?

**Hooks são contratos externos** que podem interceptar e modificar o comportamento das pools em pontos específicos do ciclo de vida.

### Pontos de Interceptação (Hook Points)

| Hook | Quando é Chamado | Uso Comum |
|------|------------------|-----------|
| `beforeInitialize` | Antes de criar pool | Validações, configurações |
| `afterInitialize` | Depois de criar pool | Setup inicial |
| `beforeAddLiquidity` | Antes de adicionar liquidez | Validações, taxas |
| `afterAddLiquidity` | Depois de adicionar liquidez | Recompensas, tracking |
| `beforeRemoveLiquidity` | Antes de remover liquidez | Taxas de saída |
| `afterRemoveLiquidity` | Depois de remover liquidez | Limpeza, eventos |
| `beforeSwap` | Antes do swap | Validações, limites |
| `afterSwap` | Depois do swap | Recompensas, oráculos |
| `beforeDonate` | Antes de doação | Validações |
| `afterDonate` | Depois de doação | Tracking |

### Permissões de Hooks

Cada hook deve declarar quais funções implementa através de **flags de permissão**:

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: true,  // ✅ Implementa este hook
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: false,
        afterSwap: true,          // ✅ Implementa este hook
        beforeDonate: false,
        afterDonate: false,
        // ... outros
    });
}
```

### Hook Flags (Endereço com Flags)

**IMPORTANTE:** O endereço do hook deve ter flags específicas nos últimos bits para indicar quais hooks ele implementa.

```solidity
// Exemplo: Hook que implementa afterSwap e afterAddLiquidity
address hookAddress = address(
    uint160(
        Hooks.AFTER_SWAP_FLAG | 
        Hooks.AFTER_ADD_LIQUIDITY_FLAG
    ) ^ (0x4444 << 144) // Namespace para evitar colisões
);
```

**Por quê?**
- Permite validação rápida (sem chamada externa)
- Reduz gas (verificação em storage)
- Garante segurança (impossível usar hook errado)

### Exemplo: Points Hook

Hook que recompensa usuários com pontos:

```solidity
contract PointsHook is BaseHook {
    ERC20 public pointsToken;
    
    mapping(address => uint256) public points;
    
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        // Recompensar com pontos baseado no swap
        uint256 pointsEarned = calculatePoints(delta);
        points[sender] += pointsEarned;
        pointsToken.mint(sender, pointsEarned);
        
        return this.afterSwap.selector;
    }
}
```

---

## 📁 Estrutura do Projeto Proposto

### Organização de Diretórios

```
uniswap-v4/
├── README.md                    # Documentação principal
├── UNISWAP_V4_GUIDE.md         # Este guia
├── foundry.toml                 # Configuração Foundry
├── .env.example                 # Variáveis de ambiente
│
├── lib/                         # Dependências
│   ├── v4-core/                 # Contratos core do Uniswap V4
│   └── v4-periphery/            # Contratos periphery (Position Manager, etc)
│
├── src/
│   ├── hooks/                   # Hooks customizados
│   │   ├── PointsHook.sol       # Hook de pontos (exemplo básico)
│   │   ├── LimitOrderHook.sol   # Hook de ordens limitadas
│   │   ├── DynamicFeeHook.sol   # Hook de taxas dinâmicas
│   │   └── OracleHook.sol       # Hook de oráculo customizado
│   │
│   ├── tokens/                  # Tokens de teste
│   │   ├── MockERC20.sol        # Token ERC20 mock
│   │   └── PointsToken.sol      # Token de pontos
│   │
│   ├── utils/                   # Utilitários
│   │   ├── PoolUtils.sol        # Funções helper para pools
│   │   └── HookUtils.sol        # Funções helper para hooks
│   │
│   └── interfaces/              # Interfaces customizadas
│       └── IHookExample.sol    # Interface de exemplo
│
├── test/
│   ├── fixtures/                # Fixtures de teste
│   │   └── UniswapV4Fixture.sol # Setup completo do V4
│   │
│   ├── hooks/
│   │   ├── PointsHook.t.sol     # Testes do PointsHook
│   │   ├── LimitOrderHook.t.sol # Testes do LimitOrderHook
│   │   └── DynamicFeeHook.t.sol # Testes do DynamicFeeHook
│   │
│   ├── integration/
│   │   ├── PoolCreation.t.sol   # Testes de criação de pool
│   │   ├── Swap.t.sol           # Testes de swap
│   │   ├── Liquidity.t.sol      # Testes de liquidez
│   │   └── MultiPool.t.sol      # Testes multi-pool
│   │
│   └── utils/
│       └── TestUtils.sol        # Utilitários de teste
│
├── script/
│   ├── Deploy.s.sol             # Script de deploy
│   ├── CreatePool.s.sol         # Script para criar pool
│   ├── AddLiquidity.s.sol       # Script para adicionar liquidez
│   └── Swap.s.sol               # Script para fazer swap
│
└── docs/
    ├── HOOKS.md                 # Documentação de hooks
    ├── POOLS.md                 # Documentação de pools
    └── EXAMPLES.md              # Exemplos práticos
```

---

## 🔄 Fluxo de Trabalho

### 1. Setup Inicial

```bash
# 1. Instalar dependências do Uniswap V4
forge install Uniswap/v4-core --no-commit
forge install Uniswap/v4-periphery --no-commit

# 2. Build
forge build

# 3. Testes
forge test
```

### 2. Criar um Hook

```solidity
// 1. Criar contrato que herda BaseHook
// 2. Implementar getHookPermissions()
// 3. Implementar funções de hook desejadas
// 4. Deploy com endereço que tem flags corretas
```

### 3. Criar uma Pool

```solidity
// 1. Definir PoolKey
// 2. Calcular sqrtPrice inicial
// 3. Chamar poolManager.initialize()
```

### 4. Adicionar Liquidez

```solidity
// 1. Usar PositionManager
// 2. Definir range (tickLower, tickUpper)
// 3. Calcular quantidades
// 4. Chamar mint()
```

### 5. Fazer Swap

```solidity
// 1. Preparar SwapParams
// 2. Chamar poolManager.swap()
// 3. Hooks são chamados automaticamente
```

---

## 🎓 Casos de Uso Práticos

### 1. Points Hook (Recompensas)
- **Objetivo:** Recompensar usuários com pontos por swaps
- **Hooks usados:** `afterSwap`, `afterAddLiquidity`
- **Aplicação:** Gamificação, loyalty programs

### 2. Limit Order Hook (Ordens Limitadas)
- **Objetivo:** Permitir ordens limitadas on-chain
- **Hooks usados:** `beforeSwap`
- **Aplicação:** Trading avançado, DEX com ordens

### 3. Dynamic Fee Hook (Taxas Dinâmicas)
- **Objetivo:** Ajustar taxas baseado em volume/volatilidade
- **Hooks usados:** `beforeSwap`, `afterSwap`
- **Aplicação:** Otimização de receitas, gestão de risco

### 4. Oracle Hook (Oráculo Customizado)
- **Objetivo:** Manter preços atualizados para outros contratos
- **Hooks usados:** `afterSwap`
- **Aplicação:** Price feeds, DeFi protocols

### 5. TWAMM Hook (Time-Weighted AMM)
- **Objetivo:** Executar swaps grandes ao longo do tempo
- **Hooks usados:** `beforeSwap`, `afterSwap`
- **Aplicação:** Large trades, MEV protection

---

## ⚠️ Considerações Importantes

### Segurança
- ✅ Sempre valide inputs nos hooks
- ✅ Use reentrancy guards quando necessário
- ✅ Teste extensivamente antes de deploy
- ✅ Considere auditoria para produção

### Gas Optimization
- ✅ Hooks são chamados em cada operação (custo de gas)
- ✅ Mantenha lógica simples quando possível
- ✅ Use storage eficientemente

### Compatibilidade
- ✅ Hooks são específicos por pool
- ✅ Não podem ser alterados após criação da pool
- ✅ Planeje bem antes de criar pools com hooks

---

## 📚 Recursos Adicionais

- [Documentação Oficial Uniswap V4](https://docs.uniswap.org/contracts/v4/overview)
- [Uniswap V4 Whitepaper](https://uniswap.org/whitepaper-v4.pdf)
- [GitHub: v4-core](https://github.com/Uniswap/v4-core)
- [GitHub: v4-periphery](https://github.com/Uniswap/v4-periphery)
- [GitHub: v4-template](https://github.com/uniswapfoundation/v4-template)

---

## 🚀 Próximos Passos

1. **Entender os conceitos** (você está aqui! ✅)
2. **Setup do ambiente** (instalar dependências)
3. **Criar primeiro hook** (Points Hook como exemplo)
4. **Testar localmente** (Foundry + Anvil)
5. **Expandir funcionalidades** (outros hooks, integrações)

---

**Pronto para começar?** Vamos implementar! 🎉

