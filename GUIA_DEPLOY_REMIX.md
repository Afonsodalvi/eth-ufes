# 🚀 Guia Rápido: Deploy no Remix

## ⚠️ Erro: ERC721InvalidReceiver

Se você está vendo este erro, provavelmente está passando o endereço do **Price Feed Chainlink** como `initialOwner` no constructor.

## ✅ Solução Rápida

### 1. Obtenha Seu Endereço

No Remix, no canto superior direito, você verá uma aba **"Account"**. 
- Clique nela
- Copie o endereço que aparece (exemplo: `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`)
- **Este é o endereço que você deve usar como `initialOwner`**

### 2. Ordem Correta dos Parâmetros

Ao fazer deploy, preencha nesta ordem:

```
1. name_              → "Meu NFT" (string)
2. symbol_            → "NFT" (string)
3. paymentToken_      → Endereço do seu token ERC20 (address)
4. priceInToken_      → 100000000000000000000 (uint256 - 100 tokens)
5. priceInETH_        → 100000000000000000 (uint256 - 0.1 ETH)
6. priceInBTC_        → 29439104758763897 (uint256 - calculado)
7. maxSupply_         → 1000 (uint256)
8. initialOwner       → SEU ENDEREÇO (address) ⚠️ NÃO USE O PRICE FEED AQUI!
9. btcEthPriceFeed_   → 0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22 (address)
```

### 3. Exemplo Visual

```
┌─────────────────────────────────────────────────┐
│ Deploy & Run Transactions                      │
├─────────────────────────────────────────────────┤
│ Contract: NFTPayment                           │
│                                                 │
│ Constructor Parameters:                        │
│                                                 │
│ [1] name_                                       │
│     "Meu NFT"                                  │
│                                                 │
│ [2] symbol_                                     │
│     "NFT"                                       │
│                                                 │
│ [3] paymentToken_                               │
│     0x... (endereço do seu token)              │
│                                                 │
│ [4] priceInToken_                                │
│     100000000000000000000                       │
│                                                 │
│ [5] priceInETH_                                 │
│     100000000000000000                          │
│                                                 │
│ [6] priceInBTC_                                 │
│     29439104758763897                           │
│                                                 │
│ [7] maxSupply_                                  │
│     1000                                        │
│                                                 │
│ [8] initialOwner                                │
│     0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 │ ← SEU ENDEREÇO
│                                                 │
│ [9] btcEthPriceFeed_                            │
│     0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22 │ ← PRICE FEED
│                                                 │
│ [Deploy]                                       │
└─────────────────────────────────────────────────┘
```

## 📋 Checklist Antes de Deployar

- [ ] Tenho o endereço do meu token ERC20 deployado
- [ ] Calculei o preço BTC (ou usei um valor aproximado)
- [ ] Copiei meu endereço da aba "Account" do Remix
- [ ] Verifiquei que meu endereço está na posição 8 (initialOwner)
- [ ] Verifiquei que o price feed está na posição 9 (btcEthPriceFeed_)
- [ ] Estou na rede Sepolia (se for usar o price feed)

## 🔢 Valores Recomendados para Teste

```solidity
name_: "Meu NFT"
symbol_: "NFT"
paymentToken_: [endereço do seu MockToken]
priceInToken_: 100000000000000000000  // 100 tokens (18 decimais)
priceInETH_: 100000000000000000       // 0.1 ETH (em wei)
priceInBTC_: 29439104758763897        // ~0.0294 BTC (aproximado)
maxSupply_: 1000
initialOwner_: [SEU ENDEREÇO DO REMIX]
btcEthPriceFeed_: 0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22
```

## 🎯 Passo a Passo Completo

### Passo 1: Deploy do Token Mock

1. Crie um arquivo `MockToken.sol` no Remix
2. Cole o código do MockToken (veja EXEMPLOS_CODIGO_ETAPAS.md)
3. Compile
4. Deploy
5. **Copie o endereço do token deployado**

### Passo 2: Calcular Preço BTC (Opcional)

Se quiser calcular o preço BTC exato:

1. Faça um deploy temporário do NFT (pode usar valores dummy)
2. Chame a função `calculateBTCPriceFromETH(100000000000000000)`
3. Use o valor retornado

**OU** use um valor aproximado: `29439104758763897`

### Passo 3: Deploy do NFT

1. Abra o arquivo `NFTPayment.sol`
2. Compile
3. Vá para "Deploy & Run Transactions"
4. Preencha todos os parâmetros na ordem correta
5. **IMPORTANTE**: Use seu endereço (da aba Account) como `initialOwner`
6. Clique em "Deploy"

## 🐛 Se Ainda Der Erro

### Verifique:

1. **initialOwner está correto?**
   - Deve ser seu endereço do Remix
   - NÃO deve ser o price feed
   - NÃO deve ser endereço zero

2. **Todos os endereços estão corretos?**
   - `paymentToken_` é o endereço do seu token?
   - `btcEthPriceFeed_` é o price feed Chainlink?

3. **Valores numéricos estão corretos?**
   - Preços estão em wei/decimais?
   - maxSupply é maior que zero?

4. **Rede está correta?**
   - Para usar price feed, precisa estar na Sepolia
   - Para testes locais, pode usar valores mock

## 💡 Dica: Use Variáveis

Para evitar erros, você pode criar um arquivo de configuração:

```solidity
// config.sol
address constant MY_ADDRESS = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
address constant PRICE_FEED_SEPOLIA = 0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22;
uint256 constant PRICE_TOKEN = 100000000000000000000;
uint256 constant PRICE_ETH = 100000000000000000;
```

Depois use essas constantes ao fazer deploy.

## ✅ Sucesso!

Se o deploy funcionou, você verá:
- Contrato deployado na aba "Deployed Contracts"
- Pode expandir e ver todas as funções
- Pode testar `currentSupply()`, `priceInETH()`, etc.

---

**Lembre-se**: O endereço do price feed (`0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22`) é apenas para o parâmetro `btcEthPriceFeed_`, nunca para `initialOwner`!

