# Risk Demonstrations - Receitas Rápidas para Aula

Este documento contém receitas práticas para demonstrar diferentes riscos DeFi em aula usando Tenderly SDK.

## (A) Contrato: Upgrades e Chaves de Admin

### Demonstração
Crie um ERC20 Pausable (OpenZeppelin) por trás de um `TransparentUpgradeableProxy`.

### Simulação com SDK

**TX1**: transfer ok  
**TX2**: admin chama `pause()` (ou `upgradeTo()` para impl. "bugada")  
**TX3**: transfer falha (ou comportamento muda após upgrade)

Faça em **bundle** para mostrar sequência no mesmo bloco.

```typescript
// Exemplo conceitual
const bundle = [
  { to: token, input: encodeTransfer(...) },      // TX1: OK
  { to: token, input: encodePause() },             // TX2: Admin pausa
  { to: token, input: encodeTransfer(...) }        // TX3: Falha
];

await tenderly.simulator.simulateBundle({ bundle });
```

**Alternativa**: Force privilégios de admin na simulação via **state overrides** (padrão "wards" do DAI como guia - veja `03_state_override_dai_ward.ts`).

---

## (B) Oráculo: Manipulação/Atraso

### Abordagem 1: Spot Price Attack (Mais Simples)

**Por que usar spot de DEX como preço é perigoso**

Use o script `02_bundle_spot_oracle_attack.ts` para:
- Mover o preço no pool com swap grande
- Mostrar a "vítima" tomando preço pior no mesmo bloco

### Abordagem 2: State Override (Oráculo Desatualizado)

**Demonstração de atraso ou valor incorreto**

1. Calcule o slot do feed de preço (ou do contrato que lê preço)
2. Injete um valor desatualizado/errado só na simulação via `state_objects.storage`

```typescript
// Exemplo: override de preço em um oracle
const PRICE_SLOT = 1n; // slot do preço no contrato
const OLD_PRICE = '0x000000000000000000000000000000000000000000000000000000005af3107a40'; // preço antigo

await tenderly.simulator.simulateTransaction({
  // ... transação
  state_objects: {
    [ORACLE_ADDRESS]: {
      storage: {
        [PRICE_SLOT]: OLD_PRICE
      }
    }
  }
});
```

---

## (C) Composability Risk ("Money Legos")

### Receita: Bundle com 3 Passos

**Cenário didático**:

1. Troque ETH → stETH (Curve/Uni)
2. Deposite stETH como colateral (Aave/Compound)
3. Tome empréstimo (USDC)

**Depois**:
- Override o preço do stETH (depeg)
- Simule a chamada de liquidação
- Mostre como uma mudança em um lego impacta o outro:
  - Colateral desvalorizado → saúde da posição cai → liquidação

**Nota**: Endereços/ABIs mudam por protocolo; a técnica é idêntica: `simulateBundle` + `state_overrides`.

```typescript
// Exemplo conceitual
const bundle = [
  { /* swap ETH -> stETH */ },
  { /* depositar stETH como colateral */ },
  { /* tomar empréstimo USDC */ }
];

// Override de preço (depeg)
const depeggedPrice = '0x...'; // preço menor
await tenderly.simulator.simulateBundle({
  bundle,
  state_objects: {
    [STETH_ORACLE]: {
      storage: { [PRICE_SLOT]: depeggedPrice }
    }
  }
});
```

---

## (D) Bridge Risk

### Receita Didática na VirtualNet

**Cenário**:

1. Implante um ERC20 Pausable "representando" um token bridged
2. **TX1**: transfer ok
3. **TX2**: admin chama `pause()` (simula bridge congelando mint/transfer após hack)
4. **TX3**: transfer falha

Use **faucet** e **Admin RPC** para criar o cenário rapidamente.

### Admin RPC Úteis para Bridge Demo

```bash
# Congelar token (simula bridge pausado)
curl -X POST $VNET_RPC \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tenderly_setStorageAt",
    "params": [TOKEN_ADDRESS, SLOT, "0x01"], // paused = true
    "id": 1
  }'
```

---

## Referências Técnicas

### Bundles (simulações em sequência no mesmo bloco)
- [Tenderly Docs: Bundled Simulations](https://docs.tenderly.co/simulations-and-forks/simulating-transactions/bundled-transactions)

### State Overrides
- [Tenderly Docs: State Overrides](https://docs.tenderly.co/simulations-and-forks/simulating-transactions/state-overrides)
- Exemplo oficial com DAI/wards: veja `03_state_override_dai_ward.ts`

### Virtual TestNets + Admin RPC
- [Tenderly Docs: Virtual TestNets](https://docs.tenderly.co/virtual-testnets/overview)
- [Admin RPC: tenderly_setBalance, tenderly_setErc20Balance](https://docs.tenderly.co/virtual-testnets/admin-rpc-api)
- [evm_increaseTime / evm_mine](https://docs.tenderly.co/virtual-testnets/admin-rpc-api#evm_increasetime)

---

## Dicas para o Momento da Aula

1. **Abra a DeFiLlama ao vivo** e mostre TVL do dia para contextualizar (marcos 2020–2025)

2. **Mostre side-by-side**:
   - V2 vs V3: `gas_used` e DAI recebidos (do `asset_changes`)
   - Bundle: "antes/depois no mesmo bloco", evidenciando a fragilidade do spot

3. **Explique overrides** com o exemplo DAI/wards (é visualmente forte: "com um bit no storage, virei admin na simulação")

4. **VirtualNet**: demonstre enviar a TX de swap de verdade no seu RPC virtual (os alunos adoram ver um hash "on-chain" no seu "lab")
