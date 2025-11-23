# 🔗 Guia Completo - Simulações Tenderly

## 📚 Índice

1. [Como Funcionam as Simulações](#como-funcionam-as-simulações)
2. [RPC: Simulação API vs VirtualNet](#rpc-simulação-api-vs-virtualnet)
3. [Configurações do .env](#configurações-do-env)
4. [Scripts Detalhados](#scripts-detalhados)
5. [Explicação Técnica das Operações](#explicação-técnica-das-operações)

---

## 🌐 Como Funcionam as Simulações

### Simulação via API (REST)

**Como funciona:**
1. Você envia uma requisição HTTP POST para a API do Tenderly
2. O Tenderly cria um **fork interno temporário** da Ethereum Mainnet
3. Executa a transação neste fork isolado
4. Retorna os resultados (gas, mudanças de estado, etc.)
5. Salva no dashboard se `save: true`

**Rede usada:**
- ✅ **Ethereum Mainnet (Chain ID: 1)**
- ✅ Fork interno criado pelo Tenderly
- ✅ Usa estado atual da mainnet (último bloco)
- ❌ **NÃO altera a mainnet real**

**RPC:**
- Não usa RPC diretamente
- Usa API REST: `https://api.tenderly.co/api/v1/account/{ACCOUNT}/project/{PROJECT}/simulate`

### VirtualNet (Fork Persistente)

**Como funciona:**
1. Você cria uma VirtualNet no dashboard do Tenderly
2. É um **fork persistente** da mainnet (existe até você deletar)
3. Você se conecta via RPC customizado (como uma rede real)
4. Executa transações reais (não são simulações!)
5. Todas as transações aparecem no dashboard automaticamente

**Rede usada:**
- ✅ **Fork da Ethereum Mainnet (Chain ID: 1)**
- ✅ Cópia isolada e persistente
- ✅ Comporta-se como rede real
- ❌ **NÃO afeta a mainnet real**

**RPC:**
- URL customizada: `https://virtual.mainnet.eu.rpc.tenderly.co/{VNET_ID}`
- Você se conecta como se fosse uma rede Ethereum normal

---

## 🔧 RPC: Simulação API vs VirtualNet

### 📊 Tabela Comparativa

| Característica | Simulação API | VirtualNet |
|---------------|---------------|------------|
| **Tipo de RPC** | API REST (HTTP POST) | RPC Ethereum padrão |
| **URL** | `https://api.tenderly.co/api/v1/...` | `https://virtual.mainnet.eu.rpc.tenderly.co/...` |
| **Rede** | Fork temporário (criado para cada simulação) | Fork persistente (existe até deletar) |
| **Estado** | Estado atual da mainnet | Estado atual da mainnet (no momento da criação) |
| **TX Hash** | ❌ Não retorna | ✅ Retorna hash real |
| **Precisa de chave privada?** | ❌ Não | ✅ Sim (para assinar transações) |
| **Precisa fundar conta?** | ❌ Não (usa `state_objects`) | ✅ Sim (via faucet/admin RPC) |
| **Quando usar** | Testar, comparar, analisar | Executar transações reais em ambiente seguro |

---

## ⚙️ Configurações do .env

### Configurações Obrigatórias (Todas as Simulações)

```env
# Credenciais do Tenderly (OBRIGATÓRIO para todas as simulações)
TENDERLY_ACCOUNT=afonsodalvi          # Nome da conta (slug da URL)
TENDERLY_PROJECT=project              # Slug do projeto (não o nome!)
TENDERLY_KEY=j74a...  # Access Token
```

**Onde encontrar:**
- `TENDERLY_ACCOUNT` e `TENDERLY_PROJECT`: Aparecem na URL do dashboard
- `TENDERLY_KEY`: Gere em Account Settings > Access Tokens

### Configurações Opcionais (Simulações API)

```env
# Endereço para usar nas simulações (opcional)
FROM=0x5bb7dd6a6eb4a440d6c70e1165243190295e290b
```

**Nota:** Se não configurar, usa endereço padrão (Vitalik). O endereço é apenas para simulação, não precisa ser seu!

### Configurações Obrigatórias (VirtualNet)

```env
# VirtualNet RPC (OBRIGATÓRIO para scripts de VirtualNet)
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/5b8aa737-...

# Private Key para VirtualNet (OBRIGATÓRIO para scripts de VirtualNet)
TENDERLY_PRIVATE_KEY=<suaprivateKey>...
```

**⚠️ IMPORTANTE:**
- `TENDERLY_PRIVATE_KEY` deve ser uma chave de **TESTE** que não tenha fundos na mainnet real!
- O endereço derivado desta chave é: `0x82494A3A4DAe3c0Ff499194Ff30dF5a23c8240C1`
- Você precisa enviar ETH para este endereço na VirtualNet (via dashboard do Tenderly)

---

## 📊 Scripts Detalhados

### 1. `npm run test:verify` - Teste de Verificação

**Tipo:** Simulação API  
**RPC usado:** API REST do Tenderly  
**Rede:** Ethereum Mainnet (fork interno)

**O que faz:**
- Testa conexão básica com Tenderly
- Executa transferência simples de ETH (0.001 ETH)
- Valida se todas as configurações estão corretas

**Configurações necessárias:**
```env
TENDERLY_ACCOUNT=afonsodalvi
TENDERLY_PROJECT=project
TENDERLY_KEY=j74a2UDJIUPaq6gxIvhetj1vyDknbDYJ
FROM=0x5bb7dd6a6eb4a440d6c70e1165243190295e290b  # Opcional
```

**Operação executada:**
```
De: 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
Para: 0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE
Valor: 0.001 ETH
Input: 0x (transferência simples, sem dados)
```

**Link do dashboard:** Aparece no final do console

---

### 2. `npm run compare` - Comparação Uniswap V2 vs V3

**Tipo:** Simulação API  
**RPC usado:** API REST do Tenderly  
**Rede:** Ethereum Mainnet (fork interno)

**O que faz:**
- Compara eficiência de gas entre Uniswap V2 e V3
- Compara quantidade de DAI recebida
- Mostra diferenças entre os protocolos

**Configurações necessárias:**
```env
TENDERLY_ACCOUNT=afonsodalvi
TENDERLY_PROJECT=project
TENDERLY_KEY=j74a2UDJIUPaq6gxIvhetj1vyDknbDYJ
FROM=0x5bb7dd6a6eb4a440d6c70e1165243190295e290b  # Opcional
```

**Operações executadas:**

#### Simulação V2:
```
Função: swapExactETHForTokens()
Contrato: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D (UniswapV2Router02)
Valor enviado: 0.01 ETH
Path: WETH → DAI
Deadline: timestamp atual + 900 segundos
```

**O que acontece:**
1. Usuário envia 0.01 ETH para o Router V2
2. Router converte ETH em WETH automaticamente
3. Router encontra o pool WETH/DAI
4. Executa swap usando fórmula x * y = k (Constant Product)
5. Calcula quantidade de DAI baseado nas reservas do pool
6. Transfere DAI para o usuário
7. Retorna array `[amountWETH, amountDAI]`

**Resultado típico:**
- Gas usado: ~118,990
- DAI recebido: ~28.24 DAI
- Taxa de câmbio: ~2,824 DAI por ETH

#### Simulação V3:
```
Função: exactInputSingle()
Contrato: 0xE592427A0AEce92De3Edee1F18E0157C05861564 (SwapRouter)
Valor enviado: 0.01 ETH
Parâmetros:
  - tokenIn: WETH (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
  - tokenOut: DAI (0x6B175474E89094C44Da98b954EedeAC495271d0F)
  - fee: 3000 (0.3% - pool mais líquido)
  - recipient: endereço do usuário
  - deadline: timestamp atual + 900 segundos
  - amountIn: 0.01 ETH
  - amountOutMinimum: 0
  - sqrtPriceLimitX96: 0
```

**O que acontece:**
1. Usuário envia 0.01 ETH para o SwapRouter V3
2. Router converte ETH em WETH automaticamente
3. Router encontra o pool WETH/DAI com fee 0.3%
4. Executa swap usando fórmula de concentrated liquidity
5. Calcula quantidade de DAI baseado no tick atual e liquidez concentrada
6. Transfere DAI para o usuário
7. Retorna `amountOut` (uint256)

**Resultado típico:**
- Gas usado: ~121,296
- DAI recebido: ~28.24 DAI
- Taxa de câmbio: ~2,824 DAI por ETH

**Diferenças principais:**
- V3 usa mais gas (~2,306 a mais) devido à complexidade da concentrated liquidity
- V3 geralmente oferece melhor preço devido à liquidez concentrada
- V2 é mais simples e usa menos gas

**Links do dashboard:** 
- Aparecem durante execução e no final
- Um link para cada simulação (V2 e V3)

---

### 3. `npm run bundle:spot` - Spot Oracle Attack

**Tipo:** Simulação API  
**RPC usado:** API REST do Tenderly  
**Rede:** Ethereum Mainnet (fork interno)

**O que faz:**
- Demonstra manipulação de preço spot
- Simula swap grande (5 ETH) seguido de swap pequeno (0.1 ETH)
- Mostra como o preço pode ser manipulado

**Configurações necessárias:**
```env
TENDERLY_ACCOUNT=afonsodalvi
TENDERLY_PROJECT=project
TENDERLY_KEY=j74a2UDJIUPaq6gxIvhetj1vyDknbDYJ
FROM=0x5bb7dd6a6eb4a440d6c70e1165243190295e290b  # Opcional
```

**Operações executadas:**

#### TX1 - Swap Grande (Ataque):
```
Função: swapExactETHForTokens()
Valor: 5 ETH
Path: WETH → DAI
```

**O que acontece:**
1. Swap de 5 ETH é muito grande comparado ao pool
2. Causa **slippage significativo** (preço piora durante o swap)
3. **Manipula o preço spot** do pool
4. Pool fica com menos DAI e mais WETH
5. Próximos swaps receberão preço pior

**Resultado típico:**
- Gas usado: ~118,990
- DAI recebido: ~14,089.81 DAI
- Taxa de câmbio: ~2,817 DAI por ETH (pior devido ao tamanho)

#### TX2 - Swap Pequeno (Vítima):
```
Função: swapExactETHForTokens()
Valor: 0.1 ETH
Path: WETH → DAI
```

**O que acontece:**
1. Swap de 0.1 ETH acontece após o pool ter sido manipulado
2. Pool já tem menos DAI (foi removido na TX1)
3. Recebe **preço pior** do que receberia normalmente
4. Em um bundle real (mesmo bloco), o impacto seria ainda maior

**Resultado típico:**
- Gas usado: ~118,990
- DAI recebido: ~282.44 DAI
- Taxa de câmbio: ~2,824 DAI por ETH

**Por que isso é perigoso:**
- Se um protocolo usar o preço spot de um DEX como oráculo
- Um atacante pode manipular o preço com um swap grande
- Protocolos que confiam no preço spot podem ser explorados
- **Solução:** Usar oráculos como Chainlink, não preço spot de DEX

**Links do dashboard:**
- Um link para TX1 (ataque)
- Um link para TX2 (vítima)
- Aparecem durante execução e no final

---

### 4. `npm run override:ward` - State Override DAI Wards

**Tipo:** Simulação API  
**RPC usado:** API REST do Tenderly  
**Rede:** Ethereum Mainnet (fork interno)

**O que faz:**
- Demonstra State Override
- Simula tornar um endereço fake admin do DAI
- Mostra como testar cenários impossíveis

**Configurações necessárias:**
```env
TENDERLY_ACCOUNT=afonsodalvi
TENDERLY_PROJECT=project
TENDERLY_KEY=j74a2UDJIUPaq6gxIvhetj1vyDknbDYJ
```

**Operação executada:**
```
Função: mint(address,uint256) do contrato DAI
Contrato: 0x6B175474E89094C44Da98b954EedeAC495271d0F (DAI)
From: 0xe2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2 (endereço fake)
Amount: 1000 DAI
```

**State Override aplicado:**
```
Contrato: DAI
Storage Slot: wards[0xe2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2]
Valor: 1 (ativo - torna o endereço admin)
```

**O que acontece:**
1. State Override modifica o storage do contrato DAI antes da execução
2. Define `wards[fake_address] = 1` (torna admin)
3. Endereço fake agora pode chamar `mint()` (função protegida)
4. Minta 1000 DAI para o endereço fake
5. Na mainnet real, isso seria impossível (endereço não é admin)

**Por que isso é útil:**
- Permite testar cenários de privilégios sem precisar ser admin real
- Permite simular vulnerabilidades sem alterar a blockchain
- Útil para auditorias e testes de segurança

**Link do dashboard:** Aparece no final dos resultados

---

### 5. `npm run vnet:swapv3` - Swap V3 na VirtualNet

**Tipo:** VirtualNet (transação real)  
**RPC usado:** RPC da VirtualNet  
**Rede:** Fork persistente da Mainnet

**O que faz:**
- Executa swap REAL na VirtualNet (não é simulação!)
- Comporta-se como uma rede real
- Retorna TX hash

**Configurações necessárias:**
```env
TENDERLY_ACCOUNT=afonsodalvi
TENDERLY_PROJECT=project
TENDERLY_KEY=j74a2UDJIUPaq6gxIvhetj1vyDknbDYJ
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/5b8aa737-2bf9-45b1-9c96-ce2a7eb642fe
TENDERLY_PRIVATE_KEY=0x82494a3a4dae3c0ff499194ff30df5a23c8240c1...
```

**⚠️ IMPORTANTE:**
- O endereço derivado da `TENDERLY_PRIVATE_KEY` é: `0x82494A3A4DAe3c0Ff499194Ff30dF5a23c8240C1`
- Você precisa enviar ETH para este endereço na VirtualNet
- Como fazer: Use o dashboard do Tenderly para enviar ETH para este endereço

**Operação executada:**
```
Função: exactInputSingle()
Contrato: 0xE592427A0AEce92De3Edee1F18E0157C05861564 (SwapRouter)
Valor: 0.02 ETH
Parâmetros: WETH → DAI, fee 0.3%
```

**O que acontece:**
1. Script verifica saldo do endereço na VirtualNet
2. Se saldo < 0.1 ETH, mostra erro e instruções
3. Prepara transação de swap
4. Assina transação com a chave privada
5. Envia transação para a VirtualNet via RPC
6. VirtualNet executa a transação (como se fosse mainnet)
7. Retorna TX hash

**Diferença da simulação:**
- ✅ Esta é uma transação REAL (não simulação)
- ✅ Aparece no histórico da VirtualNet
- ✅ Pode ser vista no explorer da VirtualNet
- ✅ Comporta-se exatamente como na mainnet

**Como ver a transação:**
1. TX hash aparece no console
2. Acesse o dashboard da VirtualNet
3. Procure pela TX hash no histórico
4. Veja todos os detalhes como em uma transação real

---

## 🔍 Explicação Técnica das Operações

### Como Funciona um Swap no Uniswap V2

**Fórmula:** `x * y = k` (Constant Product)

**Passo a passo:**

1. **Usuário envia ETH:**
   ```
   De: 0x5bb7dd6a6eb4a440d6c70e1165243190295e290b
   Para: 0x7a250d5630B4cF539739dF2C5dAcb4c659f2488D (Router V2)
   Valor: 0.01 ETH
   ```

2. **Router converte ETH → WETH:**
   - Router chama `WETH.deposit()` automaticamente
   - ETH é convertido em WETH (Wrapped Ether)

3. **Router encontra o pool:**
   - Pool: `0xa478c2975ab1ea89e8196811f51a7b7ade33eb11` (WETH/DAI)
   - Reservas antes: `reserve0 = DAI`, `reserve1 = WETH`

4. **Calcula quantidade de DAI:**
   ```
   amountOut = (amountIn * 997 * reserve0) / ((reserve1 * 1000) + (amountIn * 997))
   ```
   - 997/1000 = taxa de 0.3% do pool
   - Garante que `(reserve0 - amountOut) * (reserve1 + amountIn) >= reserve0 * reserve1`

5. **Executa o swap:**
   - Transfere WETH para o pool
   - Pool transfere DAI para o usuário
   - Atualiza reservas do pool

6. **Eventos emitidos:**
   - `Swap`: Mostra valores de entrada e saída
   - `Sync`: Atualiza reservas do pool

### Como Funciona um Swap no Uniswap V3

**Fórmula:** Concentrated Liquidity (liquidez concentrada)

**Passo a passo:**

1. **Usuário envia ETH:**
   ```
   De: 0x5bb7dd6a6eb4a440d6c70e1165243190295e290b
   Para: 0xE592427A0AEce92De3Edee1F18E0157C05861564 (SwapRouter V3)
   Valor: 0.01 ETH
   ```

2. **Router converte ETH → WETH:**
   - Similar ao V2

3. **Router encontra o pool:**
   - Pool: `0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8` (WETH/DAI, fee 0.3%)
   - Pool V3 usa "ticks" para representar preços
   - Liquidez está concentrada em ranges de preço

4. **Calcula quantidade de DAI:**
   ```
   Usa fórmula complexa baseada em:
   - Tick atual do pool
   - Liquidez disponível no tick
   - Sqrt price (raiz quadrada do preço)
   ```
   - Mais preciso que V2 devido à liquidez concentrada
   - Geralmente oferece melhor preço

5. **Executa o swap:**
   - Transfere WETH para o pool
   - Pool calcula novo tick e sqrt price
   - Pool transfere DAI para o usuário
   - Atualiza estado do pool (tick, liquidez, etc.)

6. **Eventos emitidos:**
   - `Swap`: Mostra valores, novo sqrt price, liquidez, tick

### Diferenças Principais V2 vs V3

| Aspecto | V2 | V3 |
|---------|----|----|
| **Fórmula** | x * y = k (constant product) | Concentrated liquidity |
| **Liquidez** | Distribuída em todo o range | Concentrada em ranges específicos |
| **Gas** | Menor (~118k) | Maior (~121k) |
| **Preço** | Baseado em reservas totais | Baseado em liquidez concentrada |
| **Complexidade** | Simples | Complexa (ticks, sqrt price) |
| **Flexibilidade** | Limitada | Alta (múltiplos fee tiers) |

---

## 📋 Resumo Rápido

| Script | Tipo | RPC | Rede | Precisa Chave Privada? |
|--------|------|-----|------|----------------------|
| `test:verify` | Simulação API | API REST | Mainnet (fork) | ❌ Não |
| `compare` | Simulação API | API REST | Mainnet (fork) | ❌ Não |
| `bundle:spot` | Simulação API | API REST | Mainnet (fork) | ❌ Não |
| `override:ward` | Simulação API | API REST | Mainnet (fork) | ❌ Não |
| `vnet:swapv3` | VirtualNet | RPC VirtualNet | Fork persistente | ✅ Sim |

---

## 🎯 Como Usar os Links

### Para Análise Detalhada:

1. **Copie o link** que aparece no console
2. **Cole no navegador** ou clique (se seu terminal suporta)
3. **No dashboard você verá:**
   - ✅ Trace completo da transação (todas as chamadas)
   - ✅ Gas usado em cada operação
   - ✅ Mudanças de estado (storage)
   - ✅ Asset changes (tokens recebidos/enviados)
   - ✅ Logs detalhados
   - ✅ Input e Output decodificados
   - ✅ Possíveis erros

### Para Material de Aula:

- ✅ Todos os links são salvos automaticamente
- ✅ Você pode acessar depois no dashboard
- ✅ Compartilhe os links com alunos
- ✅ Use para análise detalhada em aula
- ✅ Mostre o trace completo para entender o que acontece

---

## 💡 Dicas para Professores

1. **Execute os scripts antes da aula** para ter os links prontos
2. **Salve os links** em um documento para referência
3. **Use o dashboard** para mostrar detalhes técnicos aos alunos
4. **Compare diferentes simulações** usando os links lado a lado
5. **Explique o trace** passo a passo para mostrar o que acontece internamente

---

## 🔍 Onde Encontrar Todos os Links

**Dashboard principal (simulações):**
```
https://dashboard.tenderly.co/{ACCOUNT}/{PROJECT}/simulations
```

**VirtualNet:**
```
https://dashboard.tenderly.co/{ACCOUNT}/{PROJECT}/virtual-network
```

Substitua `{ACCOUNT}` e `{PROJECT}` pelos valores do seu `.env`.

---

**🎉 Agora você tem uma explicação completa e detalhada de todas as simulações!**
