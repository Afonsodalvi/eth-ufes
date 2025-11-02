# Instalação e Teste - Passo a Passo

## 1. Instalar tsx

```bash
cd defi-sim-lab
npm install --save-dev tsx
```

## 2. Configurar .env para Ethereum Mainnet

Certifique-se de que seu `.env` está configurado assim:

```env
TENDERLY_ACCOUNT=Omnes
TENDERLY_PROJECT=project
TENDERLY_KEY=seu_token_aqui
FROM=0xseu_endereco_eoa
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id
```

## 3. Testar os Scripts

### Teste 1: Comparação Uniswap V2 vs V3

```bash
npm run compare
```

**Resultado esperado:**
```
🔄 Comparando Uniswap V2 vs V3...
Entrada: 0.01 ETH
Endereço FROM: 0x...

=== RESULTADOS ===
📊 Uniswap V2:
  Gas usado: ...
  DAI recebido: ...
...
```

### Teste 2: Bundle Spot Oracle Attack

```bash
npm run bundle:spot
```

### Teste 3: State Override DAI Wards

```bash
npm run override:ward
```

### Teste 4: Swap Real na VirtualNet

```bash
npm run vnet:swapv3
```

## Problemas Comuns e Soluções

### Erro: "tsx: not found"

**Solução:**
```bash
npm install --save-dev tsx
```

### Erro: "Missing network"

**Solução:** O código foi ajustado para usar `"1"` (string) como network_id para Ethereum Mainnet.

### Erro: "Invalid account or project"

**Verifique:**
- `TENDERLY_ACCOUNT` e `TENDERLY_PROJECT` estão corretos no `.env`
- Os nomes estão exatamente como aparecem no Tenderly Dashboard

### Erro: "Invalid access key"

**Solução:**
- Gere um novo Access Key em: Settings > Authorization > Generate New Access Token
- Atualize `TENDERLY_KEY` no `.env`

### Erro: "FROM address required"

**Solução:**
- Configure `FROM` no `.env` com um endereço EOA válido (começa com `0x`)
- Pode ser qualquer endereço Ethereum válido

## Checklist Final

- [ ] `tsx` instalado (`npm install --save-dev tsx`)
- [ ] `.env` configurado com todas as variáveis
- [ ] `TENDERLY_ACCOUNT` e `TENDERLY_PROJECT` corretos
- [ ] `TENDERLY_KEY` válido (Access Key do Tenderly)
- [ ] `FROM` configurado com endereço EOA válido
- [ ] Todos os scripts funcionando

## Comandos Rápidos

```bash
# Instalar dependências
npm install

# Instalar tsx
npm install --save-dev tsx

# Testar comparação V2 vs V3
npm run compare

# Testar bundle spot attack
npm run bundle:spot

# Testar state override
npm run override:ward

# Testar swap na VirtualNet
npm run vnet:swapv3
```

## Sucesso! 🎉

Se todos os scripts executarem sem erros, você está pronto para usar o laboratório DeFi com simulações Tenderly na Ethereum Mainnet!
