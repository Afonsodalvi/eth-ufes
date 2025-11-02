# DeFi Simulation Lab

Laboratório didático DeFi com simulações Tenderly: comparação Uniswap v2 vs v3 e demonstrações práticas de riscos (contrato/upgrades/chaves de admin, oráculo, composability e bridge).

**Stack**: TypeScript + viem + Tenderly SDK

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Setup](#setup)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Demonstrações de Riscos](#demonstrações-de-riscos)
- [Referências](#referências)

## Pré-requisitos

- Node.js 20+
- Conta Tenderly com projeto criado
- Token de acesso Tenderly (Access Key)
- (Opcional) VirtualNet configurada para execuções reais

## Setup

1. **Clone e instale dependências:**

```bash
npm install
```

2. **Configure o arquivo `.env`:**

```bash
cp .env.example .env
```

Edite `.env` com suas credenciais:

```env
TENDERLY_ACCOUNT=Omnes
TENDERLY_PROJECT=project
TENDERLY_KEY=seu_token_aqui
FROM=0xseu_endereco_eoa
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id
```

3. **Execute os scripts:**

```bash
# Comparar Uniswap V2 vs V3
npm run compare

# Simular bundle de ataque spot oracle
npm run bundle:spot

# Demonstração de state override (DAI wards)
npm run override:ward

# Enviar swap real na VirtualNet
npm run vnet:swapv3
```

## Estrutura do Repositório

```
defi-sim-lab/
├── src/
│   ├── tenderly.ts              # Cliente Tenderly SDK
│   ├── constants.ts              # Endereços e constantes
│   ├── abi/
│   │   ├── uniswapV2Router.ts   # ABI Uniswap V2
│   │   └── uniswapV3Router.ts   # ABI Uniswap V3
│   ├── simulate/
│   │   ├── 01_uniswap_compare.ts              # V2 vs V3
│   │   ├── 02_bundle_spot_oracle_attack.ts    # Manipulação spot
│   │   └── 03_state_override_dai_ward.ts      # Override storage
│   ├── vnet/
│   │   ├── viemClient.ts         # Cliente viem para VirtualNet
│   │   └── 04_vnet_swap_v3_send.ts # TX real na VirtualNet
│   └── risk-demos/
│       └── README.md              # Receitas de demonstração de riscos
├── package.json
├── tsconfig.json
└── .env.example
```

## Scripts Disponíveis

### `01_uniswap_compare.ts`

Compara Uniswap V2 e V3 com a mesma entrada (0.01 ETH), mostrando:
- Gas usado
- Quantidade de DAI recebida
- Eficiência de capital

**Objetivo didático**: Demonstrar diferenças entre x·y=k (V2) e concentrated liquidity (V3).

### `02_bundle_spot_oracle_attack.ts`

Simula um bundle de duas transações no mesmo bloco:
1. **TX1**: Ataque faz swap MUITO grande (manipula spot price)
2. **TX2**: Vítima faz swap dependente desse spot (recebe preço pior)

**Objetivo didático**: Mostrar por que usar spot de DEX como oráculo é perigoso.

### `03_state_override_dai_ward.ts`

Demonstra como usar **state overrides** para simular privilégios de admin:
- Calcula storage slot de `wards[address]` no DAI
- Define `wards[FAKE_WARD] = 1` via override
- Simula mint (que normalmente requer ward)

**Objetivo didático**: Mostrar como overrides permitem simular cenários de privilégios/erros sem alterar a mainnet real.

### `04_vnet_swap_v3_send.ts`

Envia uma transação **real** na VirtualNet:
- Swap ETH → DAI via Uniswap V3
- Retorna hash da transação

**Objetivo didático**: Demonstrar execução real em ambiente seguro (VirtualNet com faucet ilimitada).

## Demonstrações de Riscos

Veja `src/risk-demos/README.md` para receitas práticas de:

- **(A) Contrato**: Upgrades e chaves de admin
- **(B) Oráculo**: Manipulação/atraso
- **(C) Composability**: "Money Legos" e cascatas
- **(D) Bridge**: Congelamento e pausas

## Referências Oficiais

### Tenderly SDK & Simulations

- [SDK Quickstart](https://docs.tenderly.co/sdk/quickstart)
- [Simulate Transaction](https://docs.tenderly.co/simulations-and-forks/simulating-transactions)
- [Bundled Simulations](https://docs.tenderly.co/simulations-and-forks/simulating-transactions/bundled-transactions)
- [State Overrides](https://docs.tenderly.co/simulations-and-forks/simulating-transactions/state-overrides)

### Virtual TestNets

- [Virtual TestNets Overview](https://docs.tenderly.co/virtual-testnets/overview)
- [Admin RPC API](https://docs.tenderly.co/virtual-testnets/admin-rpc-api)
- [Faucet Ilimitada](https://docs.tenderly.co/virtual-testnets/overview)

### Uniswap

- [Uniswap V2 Router](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02)
- [Uniswap V3 SwapRouter](https://docs.uniswap.org/contracts/v3/reference/periphery/SwapRouter)

## 💡 Dicas para Aula

1. **DeFiLlama ao vivo**: Mostre TVL do dia para contextualizar (marcos 2020–2025)

2. **Side-by-side**:
   - V2 vs V3: gas usado e DAI recebidos (do `asset_changes`)
   - Bundle: antes/depois no mesmo bloco

3. **Overrides**: Use o exemplo DAI/wards (visualmente forte: "com um bit no storage, virei admin")

4. **VirtualNet**: Envie TX real no RPC virtual (alunos adoram ver hash "on-chain")

## 📝 Licença

MIT

## 🤝 Contribuindo

Este é um repositório didático. Sinta-se livre para expandir com mais exemplos de riscos e simulações!
