# Guia de Testes dos Scripts

## Scripts Disponíveis

### 1. `npm run compare` - Comparação Uniswap V2 vs V3

**O que faz:**
- Simula swap de 0.01 ETH → DAI em Uniswap V2
- Simula swap de 0.01 ETH → DAI em Uniswap V3 (fee 0.3%)
- Compara gas usado e quantidade de DAI recebida

**Como testar:**
```bash
npm run compare
```

**O que você deve ver:**
- ✅ Comparação de gas usado entre V2 e V3
- ✅ Quantidade de DAI recebida em cada versão
- ✅ Diferença percentual de gas

**Possíveis problemas:**
- ❌ Se FROM não estiver configurado no .env
- ❌ Se TENDERLY_KEY não estiver válido
- ❌ Se TENDERLY_ACCOUNT ou TENDERLY_PROJECT estiverem incorretos

---

### 2. `npm run bundle:spot` - Bundle de Ataque Spot Oracle

**O que faz:**
- Simula duas transações no mesmo bloco:
  1. TX1: Swap grande (5 ETH) - manipula spot price
  2. TX2: Swap pequeno (0.1 ETH) - vítima recebe preço pior

**Como testar:**
```bash
npm run bundle:spot
```

**O que você deve ver:**
- ✅ Status de cada transação no bundle
- ✅ Gas usado por cada TX
- ✅ Mudanças de assets (tokens) para cada TX
- ✅ Demonstração de como TX2 recebe preço pior

**Possíveis problemas:**
- ❌ Se FROM não estiver configurado
- ❌ Erro de validação se os endereços estiverem incorretos

---

### 3. `npm run override:ward` - State Override DAI Wards

**O que faz:**
- Calcula storage slot de `wards[address]` no DAI
- Usa state override para tornar um endereço arbitrário "ward" (admin)
- Simula mint de DAI (que normalmente requer permissão)

**Como testar:**
```bash
npm run override:ward
```

**O que você deve ver:**
- ✅ Storage slot calculado
- ✅ Status da simulação (sucesso/falha)
- ✅ Gas usado
- ✅ Mudanças de assets (mint de DAI)

**Possíveis problemas:**
- ❌ Se TENDERLY_KEY não estiver configurado
- ❌ Se TENDERLY_ACCOUNT ou TENDERLY_PROJECT estiverem incorretos
- ⚠️  Esta simulação pode falhar se o DAI não tiver função mint() pública

---

### 4. `npm run vnet:swapv3` - Swap Real na VirtualNet

**O que faz:**
- Envia uma transação REAL na sua VirtualNet
- Executa swap de 0.02 ETH → DAI via Uniswap V3
- Retorna hash da transação

**Como testar:**
```bash
npm run vnet:swapv3
```

**O que você deve ver:**
- ✅ Endereço da carteira
- ✅ Hash da transação na VirtualNet
- ✅ Confirmação de sucesso

**Possíveis problemas:**
- ❌ Se VNET_RPC não estiver configurado
- ❌ Se não tiver ETH na VirtualNet (use faucet/admin RPC)
- ❌ Se a VirtualNet não estiver ativa

---

## Checklist Antes de Testar

- [ ] `.env` configurado corretamente
- [ ] `TENDERLY_ACCOUNT` e `TENDERLY_PROJECT` corretos
- [ ] `TENDERLY_KEY` válido (Access Key do Tenderly)
- [ ] `FROM` configurado com endereço EOA válido
- [ ] `VNET_RPC` configurado (para script vnet:swapv3)
- [ ] Dependências instaladas (`npm install`)

## Resolução de Problemas

### Erro: "Invalid account or project"
- Verifique `TENDERLY_ACCOUNT` e `TENDERLY_PROJECT` no .env
- Certifique-se de que estão escritos exatamente como no Tenderly Dashboard

### Erro: "Invalid access key"
- Gere um novo Access Key em: Settings > Authorization > Generate New Access Token
- Atualize `TENDERLY_KEY` no .env

### Erro: "FROM address required"
- Configure `FROM` no .env com um endereço EOA válido (0x...)
- Pode ser qualquer endereço que você controla ou possui chave privada

### Erro: "VNET_RPC required"
- Crie uma VirtualNet no Tenderly Dashboard
- Copie a URL do RPC e configure `VNET_RPC` no .env

### Erro: "Cannot find module"
- Execute `npm install` novamente
- Verifique se `node_modules` existe

## Exemplo de .env Correto

```env
TENDERLY_ACCOUNT=Omnes
TENDERLY_PROJECT=project
TENDERLY_KEY=seu_token_aqui_com_32_caracteres
FROM=0x1234567890123456789012345678901234567890
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id-unico
```
