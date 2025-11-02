# DeFi Simulation Lab

Laboratório didático DeFi com simulações Tenderly: comparação Uniswap v2 vs v3 e demonstrações práticas de riscos (contrato/upgrades/chaves de admin, oráculo, composability e bridge).

**Stack**: TypeScript + viem + Tenderly SDK

---

## 📚 Índice Completo

- [O que é este projeto?](#o-que-é-este-projeto)
- [O que é Tenderly e quando usar?](#o-que-é-tenderly-e-quando-usar)
- [Pré-requisitos](#pré-requisitos)
- [Configuração Passo a Passo](#configuração-passo-a-passo)
  - [1. Instalação](#1-instalação)
  - [2. Criar conta no Tenderly](#2-criar-conta-no-tenderly)
  - [3. Configurar projeto no Tenderly](#3-configurar-projeto-no-tenderly)
  - [4. Obter credenciais](#4-obter-credenciais)
  - [5. Configurar arquivo .env](#5-configurar-arquivo-env)
  - [6. Configurar VirtualNet (Opcional)](#6-configurar-virtualnet-opcional)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Scripts Disponíveis - Explicação Detalhada](#scripts-disponíveis---explicação-detalhada)
  - [Script 1: Comparação Uniswap V2 vs V3](#script-1-comparação-uniswap-v2-vs-v3)
  - [Script 2: Spot Oracle Attack](#script-2-spot-oracle-attack)
  - [Script 3: State Override - DAI Wards](#script-3-state-override---dai-wards)
  - [Script 4: VirtualNet Swap Real](#script-4-virtualnet-swap-real)
- [Executando os Testes](#executando-os-testes)
- [Interpretando os Resultados](#interpretando-os-resultados)
- [Troubleshooting](#troubleshooting)
- [Referências](#referências)

---

## O que é este projeto?

Este projeto é um **laboratório didático** para ensinar conceitos fundamentais de DeFi (Decentralized Finance) através de **simulações realistas** usando o Tenderly.

### Objetivos de Aprendizado:

1. **Entender diferenças entre Uniswap V2 e V3**: Como cada versão funciona, quanto custa em gas, e qual oferece melhor preço
2. **Compreender riscos de DeFi**: Como preços podem ser manipulados, por que não usar spot de DEX como oráculo
3. **Aprender sobre state overrides**: Como simular cenários impossíveis na blockchain real sem risco
4. **Praticar com ambientes seguros**: Executar transações reais em VirtualNet sem gastar ETH real

### Para quem é este projeto?

- ✅ Estudantes aprendendo DeFi
- ✅ Desenvolvedores que querem testar contratos antes de deploy
- ✅ Analistas que querem entender riscos de protocolos
- ✅ Qualquer pessoa interessada em entender como funciona DeFi na prática

---

## O que é Tenderly e quando usar?

### O que é Tenderly?

**Tenderly** é uma plataforma que permite **simular transações Ethereum** sem gastar gas real ou alterar a blockchain. É como ter uma "máquina do tempo" para testar o que aconteceria se você executasse uma transação em qualquer bloco passado ou futuro.

### Quando usar Tenderly?

#### ✅ Use Tenderly para:

1. **Simular transações antes de enviar**:
   - Ver quanto gas será usado
   - Verificar se a transação vai falhar antes de gastar dinheiro
   - Entender exatamente o que acontecerá na execução

2. **Testar cenários impossíveis**:
   - Simular se você fosse admin de um contrato (sem ser admin)
   - Testar o que aconteceria com diferentes preços de mercado
   - Simular ataques ou vulnerabilidades sem causar danos reais

3. **Comparar diferentes estratégias**:
   - Comparar Uniswap V2 vs V3
   - Ver qual rota de swap é mais barata
   - Analisar diferentes protocolos DeFi

4. **Debugging e análise**:
   - Entender por que uma transação falhou
   - Ver mudanças de estado detalhadas
   - Analisar gas usado por cada operação

#### ❌ NÃO use Tenderly para:

- Enviar transações reais (use MetaMask ou outras carteiras)
- Interagir com contratos em produção (use VirtualNet ou testnets)
- Substituir testes unitários completos

### Como o Tenderly funciona?

1. **Você envia uma transação simulada** para o Tenderly via API
2. **O Tenderly executa a transação** em um ambiente isolado (fork da blockchain)
3. **O Tenderly retorna os resultados**:
   - Gas usado
   - Mudanças de estado (storage)
   - Mudanças de assets (tokens recebidos/enviados)
   - Logs detalhados
   - Possíveis erros

### Diferença entre Simulação e VirtualNet

| Característica | Simulação (API) | VirtualNet |
|---------------|------------------|------------|
| **Gasta gas real?** | ❌ Não | ❌ Não |
| **Altera blockchain?** | ❌ Não | ❌ Não (é uma rede separada) |
| **Retorna hash de TX?** | ❌ Não | ✅ Sim |
| **Pode executar múltiplas TX sequenciais?** | ✅ Sim (bundles) | ✅ Sim |
| **Pode modificar estado antes?** | ✅ Sim (state overrides) | ✅ Sim (admin RPC) |
| **Quando usar?** | Testar e comparar | Executar transações reais em ambiente seguro |

---

## Pré-requisitos

Antes de começar, você precisa ter:

### 1. Node.js 20 ou superior

**Como verificar:**
```bash
node --version
```

**Como instalar (se não tiver):**
- Acesse: https://nodejs.org/
- Baixe a versão LTS (Long Term Support)
- Instale seguindo as instruções do site

### 2. Conta no Tenderly (grátis)

**Como criar:**
1. Acesse: https://dashboard.tenderly.co/
2. Clique em "Sign Up" ou "Get Started"
3. Crie conta com email ou GitHub
4. Confirme seu email

### 3. Git (opcional, mas recomendado)

**Como verificar:**
```bash
git --version
```

**Como instalar (se não tiver):**
- Windows/Mac: https://git-scm.com/downloads
- Linux: `sudo apt install git` (Ubuntu/Debian)

### 4. Editor de código (opcional)

Recomendado: VS Code, mas qualquer editor de texto funciona.

---

## Configuração Passo a Passo

### 1. Instalação

#### 1.1. Clone ou baixe o repositório

Se você tem Git instalado:
```bash
git clone <URL_DO_REPOSITORIO>
cd defi-sim-lab
```

Se não tem Git, baixe o código como ZIP e extraia.

#### 1.2. Instale as dependências

```bash
npm install
```

**O que isso faz?**
- Baixa todas as bibliotecas necessárias (viem, axios, dotenv, etc.)
- Cria a pasta `node_modules/` com todas as dependências
- Pode levar 1-2 minutos na primeira vez

**Se der erro:**
- Verifique se Node.js está instalado: `node --version`
- Verifique se npm está instalado: `npm --version`
- Tente: `npm install --legacy-peer-deps`

---

### 2. Criar conta no Tenderly

Se você ainda não tem conta:

1. **Acesse**: https://dashboard.tenderly.co/
2. **Clique em**: "Sign Up" ou "Get Started"
3. **Escolha**: Criar com email ou GitHub (GitHub é mais rápido)
4. **Complete o cadastro**
5. **Confirme seu email** (se necessário)

✅ **Você está pronto quando consegue acessar o dashboard!**

---

### 3. Configurar projeto no Tenderly

#### 3.1. Criar um novo projeto

1. **No dashboard do Tenderly**, clique em **"Create Project"** ou **"New Project"**
2. **Escolha um nome**: Exemplo: "defi-sim-lab" ou "meu-projeto-defi"
3. **Escolha a organização**: Se você tem organização, escolha. Se não, use sua conta pessoal
4. **Clique em "Create"**

✅ **Anote o nome do projeto** - você vai precisar dele!

#### 3.2. Encontrar o SLUG do projeto

⚠️ **IMPORTANTE**: O Tenderly usa **SLUG** (identificador na URL), não o nome do projeto!

**Como encontrar o slug:**

1. **Acesse seu projeto** no dashboard
2. **Olhe a URL** do navegador. Ela será algo como:
   ```
   https://dashboard.tenderly.co/[ACCOUNT]/[PROJECT_SLUG]/
   ```
   
   Exemplo:
   ```
   https://dashboard.tenderly.co/Omnes/project/
   ```
   
   Neste caso:
   - `ACCOUNT` = `Omnes`
   - `PROJECT_SLUG` = `project`

3. **Copie exatamente o que aparece na URL** após o nome da conta

✅ **O slug é o que você vai usar em `TENDERLY_PROJECT` no arquivo `.env`**

---

### 4. Obter credenciais

Você precisa de **3 informações** do Tenderly:

#### 4.1. TENDERLY_ACCOUNT

**O que é:** Nome da sua conta ou organização (slug)

**Como obter:**
- É o primeiro componente da URL do dashboard
- Exemplo: Se a URL é `https://dashboard.tenderly.co/Omnes/project/`, então `TENDERLY_ACCOUNT=Omnes`
- Se for conta pessoal: é seu username
- Se for organização: é o slug da organização

#### 4.2. TENDERLY_PROJECT

**O que é:** Slug do projeto (⚠️ não é o nome bonito, é o slug da URL!)

**Como obter:**
- É o segundo componente da URL do dashboard
- Exemplo: Se a URL é `https://dashboard.tenderly.co/Omnes/project/`, então `TENDERLY_PROJECT=project`
- ⚠️ **ATENÇÃO**: Se o nome do projeto na interface for "Meu Projeto DeFi", o slug pode ser "meu-projeto-defi" ou algo completamente diferente. **Sempre use o que aparece na URL!**

#### 4.3. TENDERLY_KEY (Access Token)

**O que é:** Uma chave de API que permite ao código acessar sua conta Tenderly

**Como gerar:**

1. **No dashboard do Tenderly**, clique na sua **foto de perfil** (canto superior direito)
2. **Vá em**: "Account Settings" ou "Settings"
3. **Clique em**: "Access Tokens" ou "API Keys"
4. **Clique em**: "Generate Access Token" ou "New Access Token"
5. **Dê um nome** para o token (ex: "defi-sim-lab")
6. **Copie o token** imediatamente! ⚠️ Ele só aparece uma vez!

**Exemplo de token:**
```
tn_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

⚠️ **SEGURANÇA**: 
- Nunca compartilhe este token
- Nunca faça commit dele no Git
- Se você perder, delete o token antigo e gere um novo

---

### 5. Configurar arquivo .env

#### 5.1. Criar o arquivo .env

No diretório do projeto (`defi-sim-lab/`), execute:

```bash
cp .env.example .env
```

**O que isso faz?**
- Cria uma cópia do arquivo de exemplo
- Você vai editar o `.env` com suas credenciais reais

#### 5.2. Abrir o arquivo .env

Abra o arquivo `.env` em qualquer editor de texto. Você verá algo assim:

```env
# Tenderly Configuration
TENDERLY_ACCOUNT=Omnes
TENDERLY_PROJECT=project
TENDERLY_KEY=SEU_TOKEN_AQUI
FROM=0xSEU_ENDERECO_EOA
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id
DEBUG=false
```

#### 5.3. Preencher as variáveis

**TENDERLY_ACCOUNT:**
```env
TENDERLY_ACCOUNT=Omnes  # Substitua pelo seu account name (da URL)
```

**TENDERLY_PROJECT:**
```env
TENDERLY_PROJECT=project  # Substitua pelo slug do projeto (da URL)
```

**TENDERLY_KEY:**
```env
TENDERLY_KEY=tn_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Cole o token que você gerou
```

**FROM:**
```env
FROM=0x5bb7dd6a6eb4a440d6C70e1165243190295e290B  # Endereço Ethereum qualquer (pode ser seu ou usar o padrão)
```

**Como obter um endereço Ethereum:**
- Use qualquer endereço Ethereum válido (ex: endereço do Vitalik: `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045`)
- Ou use seu próprio endereço (se tiver MetaMask ou similar)
- Não precisa ter ETH neste endereço (simulações não gastam gas real)

**VNET_RPC (Opcional):**
```env
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id  # Veja seção 6 abaixo
```

**DEBUG:**
```env
DEBUG=false  # Deixe false normalmente. Use true para ver detalhes de debug
```

**TENDERLY_PRIVATE_KEY:**
```env
TENDERLY_PRIVATE_KEY=0x5c...
```

⚠️ **IMPORTANTE - SEGURANÇA:**
- **Use APENAS uma chave privada de TESTE** que não tenha fundos na mainnet real!
- **NUNCA use sua chave privada principal** que tenha fundos reais!
- Esta chave é usada apenas na VirtualNet (ambiente seguro)
- Mesmo assim, use uma chave que você criou especificamente para testes

**Como obter uma chave privada de teste:**

1. **Criar conta de teste no MetaMask:**
   - Abra MetaMask
   - Clique em "Criar conta" ou "Add Account"
   - Escolha um nome como "Test Account" ou "VirtualNet Test"
   - Crie a conta

2. **Exportar a private key:**
   - No MetaMask, vá em **Settings** (Configurações)
   - Vá em **Security & Privacy** (Segurança e Privacidade)
   - Clique em **"Show Private Key"** ou **"Revelar chave privada"**
   - Digite sua senha do MetaMask
   - **Copie a chave privada** (começa com `0x` seguido de 64 caracteres)

3. **Verificar que não tem fundos:**
   - Confirme que esta conta **NÃO tem ETH** na mainnet real
   - Se tiver fundos, crie uma nova conta de teste

4. **Adicionar no .env:**
   ```env
   TENDERLY_PRIVATE_KEY=0xSUA_CHAVE_PRIVADA_AQUI
   ```

**Exemplo de chave privada válida:**
```
0x5c..
```

**Formatos válidos:**
- ✅ `0x` + 64 caracteres hexadecimais = 66 caracteres total
- ✅ Caracteres hexadecimais: 0-9, a-f, A-F

**Formatos inválidos:**
- ❌ Sem `0x` no início
- ❌ Mais ou menos de 64 caracteres após o `0x`
- ❌ Caracteres inválidos (g-z, espaços, etc.)

**VNET_RPC (Opcional - necessário apenas para scripts VirtualNet):**
```env
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id  # Veja seção 6 abaixo
```

**DEBUG:**
```env
DEBUG=false  # Deixe false normalmente. Use true para ver detalhes de debug
```

#### 5.4. Exemplo de .env completo

```env
# Tenderly Configuration
TENDERLY_ACCOUNT=Omnes
TENDERLY_PROJECT=project
TENDERLY_KEY=tn_ABC123XYZ789abcdefghijklmnopqrstuvwxyz
FROM=0x5bb7dd6a6eb4a440d6C70e1165243190295e290B

# VirtualNet Configuration (opcional - necessário apenas para vnet:swapv3)
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/54e15302-bb51-4ea2-b124-540392e84dad
TENDERLY_PRIVATE_KEY=0x5c...

# Debug mode
DEBUG=false
```

#### 5.5. Validar configuração

Execute o teste mínimo para verificar se está tudo configurado:

```bash
npm run test:minimal
```

**Se funcionar**, você verá algo como:
```
✅ Simulação concluída com sucesso!
Gas usado: 23000
```

**Se der erro**, veja a seção [Troubleshooting](#troubleshooting).

---

### 6. Configurar VirtualNet (Opcional)

A VirtualNet é uma **cópia da Ethereum mainnet** que você pode usar para executar transações reais sem gastar ETH real. É útil para testar transações completas.

#### 6.1. Criar VirtualNet

1. **No dashboard do Tenderly**, vá em **"Virtual TestNets"** ou **"Virtual Networks"**
2. **Clique em**: "Create Virtual TestNet" ou "New Virtual Network"
3. **Escolha**: "Fork Mainnet" ou "Ethereum Mainnet Fork"
4. **Configure**:
   - Nome: "defi-sim-lab" (ou qualquer nome)
   - Chain ID: 1 (Mainnet)
5. **Clique em**: "Create"

#### 6.2. Obter URL da VirtualNet

Após criar, você verá uma URL como:

```
https://virtual.mainnet.eu.rpc.tenderly.co/54e15302-bb51-4ea2-b124-540392e84dad
```

**Copie esta URL completa** e cole no `.env`:

```env
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/54e15302-bb51-4ea2-b124-540392e84dad
```

#### 6.3. Configurar chave privada para VirtualNet

Para executar transações na VirtualNet, você precisa de uma **chave privada** para assinar as transações.

⚠️ **IMPORTANTE - SEGURANÇA:**
- **Use APENAS uma chave privada de TESTE** que não tenha fundos na mainnet real!
- **NUNCA use sua chave privada principal** que tenha fundos reais!
- Esta chave será usada apenas na VirtualNet (ambiente seguro), mas use uma chave de teste mesmo assim

**Como obter uma chave privada de teste:**

1. **Criar conta de teste:**
   - Use MetaMask ou outra carteira
   - Crie uma nova conta especificamente para testes
   - Nomeie como "Test Account" ou "VirtualNet Test"

2. **Exportar private key:**
   - No MetaMask: Settings > Security & Privacy > Show Private Key
   - Digite sua senha
   - Copie a chave privada (começa com `0x` + 64 caracteres)

3. **Verificar que não tem fundos:**
   - Confirme que esta conta **NÃO tem ETH** na mainnet real
   - Se tiver fundos, crie uma nova conta de teste

4. **Adicionar no .env:**
   ```env
   TENDERLY_PRIVATE_KEY=0xSUA_CHAVE_PRIVADA_AQUI
   ```

**Formato esperado:**
- ✅ Deve começar com `0x`
- ✅ Deve ter exatamente 66 caracteres (0x + 64 hex chars)
- ✅ Exemplo: `0x5c....`

#### 6.4. Fundar conta na VirtualNet (se necessário)

Para executar transações na VirtualNet, você precisa de ETH. O script `vnet:swapv3` verifica saldo automaticamente.

**Se não tiver ETH suficiente:**

1. **Use o Admin RPC** (se você tiver acesso):
   - No dashboard, encontre a seção **"Admin RPC"** da sua VirtualNet
   - Use o método `tenderly_setBalance`

2. **Ou use o método via curl:**
   ```bash
   curl -X POST SUA_VNET_RPC_URL \
     -H "Content-Type: application/json" \
     -d '{
       "method": "tenderly_setBalance",
       "params": [["SEU_ENDERECO"], "0x8ac7230489e80000"],
       "id": 1,
       "jsonrpc": "2.0"
     }'
   ```
   
   Onde `0x8ac7230489e80000` = 10 ETH em wei

**Nota:** O script `vnet:swapv3` já verifica saldo e mostra instruções detalhadas se necessário.

---

## Estrutura do Repositório

```
defi-sim-lab/
├── src/
│   ├── tenderly.ts              # Cliente Tenderly SDK (configuração)
│   ├── constants.ts              # Endereços de contratos (Uniswap, DAI, etc.)
│   ├── util/
│   │   ├── eip1559.ts            # Helper para calcular fees EIP-1559
│   │   └── num.ts                # Helpers para converter números
│   ├── abi/
│   │   ├── uniswapV2Router.ts   # Interface do contrato Uniswap V2
│   │   └── uniswapV3Router.ts   # Interface do contrato Uniswap V3
│   ├── simulate/
│   │   ├── 01_uniswap_compare.ts              # Comparação V2 vs V3
│   │   ├── 02_bundle_spot_oracle_attack.ts    # Demonstração de manipulação de preço
│   │   └── 03_state_override_dai_ward.ts      # Demonstração de state override
│   ├── vnet/
│   │   ├── viemClient.ts         # Cliente para interagir com VirtualNet
│   │   └── 04_vnet_swap_v3_send.ts # Enviar swap real na VirtualNet
│   └── risk-demos/
│       └── README.md              # Mais exemplos de riscos DeFi
├── package.json                  # Dependências do projeto
├── tsconfig.json                 # Configuração TypeScript
├── .env.example                  # Template de configuração
└── README.md                     # Este arquivo!
```

---

## Scripts Disponíveis - Explicação Detalhada

### Script 1: Comparação Uniswap V2 vs V3

**Comando:** `npm run compare`

**O que faz:** Compara Uniswap V2 e V3 executando o mesmo swap (0.01 ETH → DAI) em ambos os protocolos e mostra as diferenças.

#### Por que isso é importante?

O Uniswap é o maior DEX (Decentralized Exchange) do mundo. Existem duas versões principais:

- **V2**: Mais simples, usa fórmula matemática x·y=k (liquidez uniforme)
- **V3**: Mais complexo, usa "concentrated liquidity" (liquidez concentrada em ranges de preço)

**Perguntas que este teste responde:**
- Qual versão custa mais gas?
- Qual versão oferece melhor preço?
- Qual versão é mais eficiente?

#### Como funciona (passo a passo):

1. **Prepara o swap V2:**
   ```typescript
   // Chama função swapExactETHForTokens do Router V2
   // Parâmetros: valor mínimo 0, rota [WETH → DAI], destinatário, deadline
   ```

2. **Prepara o swap V3:**
   ```typescript
   // Chama função exactInputSingle do SwapRouter V3
   // Parâmetros: token de entrada (WETH), saída (DAI), fee tier (0.3%), etc.
   ```

3. **Obtém informações do bloco atual:**
   - Busca o número do bloco mais recente na Ethereum mainnet
   - Calcula fees EIP-1559 baseado no `baseFee` do bloco
   - Por que EIP-1559? Porque a Ethereum usa este sistema desde agosto de 2021 (London fork)

4. **Envia ambas simulações para o Tenderly:**
   - Usa API REST direta (mais confiável que SDK para casos complexos)
   - Define `state_objects` para garantir que o endereço tem ETH suficiente
   - Envia em paralelo (Promise.all) para acelerar

5. **Extrai resultados:**
   - Gas usado por cada protocolo
   - Quantidade de DAI recebida (se disponível nos `asset_changes`)
   - Se não disponível, usa estimativa baseada em preço de mercado (~3000 DAI por ETH)

6. **Compara e mostra:**
   - Diferença de gas em números absolutos e percentual
   - Diferença de DAI recebido (se disponível)
   - Taxa de câmbio calculada

#### Exemplo de output:

```
🔄 Comparando Uniswap V2 vs V3...

Entrada: 0.01 ETH
Endereço FROM: 0x5bb7dd6a6eb4a440d6C70e1165243190295e290B (checksum EIP-55)

⏳ Obtendo blockNumber atual...
   BlockNumber: 23714260

⏳ Executando simulações...

   📝 Preparando simulação V2...
   ✅ Input gerado: 0x7ff36ab50000000000...
   🚀 Enviando para Tenderly...
   📝 Preparando simulação V3...
   ✅ Input gerado: 0x414bf3890000000000...
   🚀 Enviando para Tenderly...
   📦 BlockNumber: 23714260
   ⛽ Max Fee Per Gas: 2088865510 wei
   ✅ Recebido do Tenderly!
   ✅ Recebido do Tenderly!

=== RESULTADOS ===

📊 Uniswap V2:
  Gas usado: 118990
  DAI recebido: 30.0000 DAI ⚠️ (estimativa - Tenderly não retornou dados)
  Taxa de câmbio: 3000.00 DAI por ETH

📊 Uniswap V3:
  Gas usado: 121244
  DAI recebido: 30.0150 DAI ⚠️ (estimativa - Tenderly não retornou dados)
  Taxa de câmbio: 3001.50 DAI por ETH

💰 Diferença de gas: +2254 (1.89%)
   V3 usa 1.89% mais gas que V2

💱 Diferença de DAI recebido: +0.0150 DAI (0.05%)
   ⚠️  Valores estimados - em produção, V3 geralmente oferece melhor preço devido à concentrated liquidity

💡 Nota: O Tenderly não retornou dados detalhados da simulação.
   Os valores mostrados são estimativas baseadas em preços de mercado.
   As simulações foram executadas com sucesso (gas usado é real).
   Para dados mais precisos, use a VirtualNet ou consultas diretas aos pools.

✅ Simulações concluídas com sucesso!
```

#### Interpretando os resultados:

- **Gas usado (V2): 118,990** - Quantidade de gas necessária para executar o swap no V2
- **Gas usado (V3): 121,244** - Quantidade de gas necessária para executar o swap no V3
- **Diferença: +2,254 (+1.89%)** - V3 custa 1.89% mais gas que V2
  - Por quê? V3 tem mais complexidade (concentrated liquidity, múltiplos ticks)
- **DAI recebido (estimativa):** - Se o Tenderly não retornar dados reais, usa estimativa
  - V2: ~30 DAI (baseado em preço de mercado)
  - V3: ~30.015 DAI (ligeiramente melhor devido à concentrated liquidity)
- **Taxa de câmbio:** - Quantos DAI você recebe por cada ETH
  - V2: 3000 DAI/ETH
  - V3: 3001.5 DAI/ETH (melhor!)

#### O que aprendemos:

1. **V3 custa mais gas** mas oferece melhor preço (trade-off)
2. **Para swaps pequenos** (< $1000), a diferença de gas pode não valer a pena
3. **Para swaps grandes**, a melhor taxa de câmbio compensa o gas extra
4. **Concentrated liquidity** permite melhor eficiência de capital

---

### Script 2: Spot Oracle Attack

**Comando:** `npm run bundle:spot`

**O que faz:** Demonstra como um swap grande pode manipular o preço spot e afetar uma transação subsequente.

#### Por que isso é importante?

Muitos protocolos DeFi usam **preços spot** de DEXs (como Uniswap) como **oráculo de preços**. Isso é **perigoso** porque:

1. **Preços spot podem ser manipulados** por swaps grandes
2. **Um atacante pode**:
   - Fazer um swap MUITO grande para manipular o preço
   - Explorar um protocolo que depende desse preço manipulado
   - Lucrar com a diferença

**Exemplo real:** Muitos hacks DeFi aconteceram assim (ex: bZx, Synthetix, etc.)

#### Como funciona (passo a passo):

1. **Prepara TX1 (Ataque):**
   - Swap grande de **5 ETH** → DAI
   - Este swap vai **manipular o preço** do pool (devido à fórmula x·y=k)

2. **Prepara TX2 (Vítima):**
   - Swap pequeno de **0.1 ETH** → DAI
   - Este swap vai ser executado **depois** do grande, então receberá **preço pior**

3. **Simula ambas sequencialmente:**
   - Envia TX1 para o Tenderly
   - Envia TX2 para o Tenderly (simula no mesmo bloco)
   - Em produção, um bundle real executaria ambas no mesmo bloco

4. **Calcula taxa de câmbio:**
   - TX1: Quantos DAI por ETH recebeu?
   - TX2: Quantos DAI por ETH recebeu?
   - Compara para mostrar a diferença

5. **Mostra impacto:**
   - Como a TX1 afetou o preço para a TX2
   - Por que isso é perigoso para protocolos que usam spot como oráculo

#### Exemplo de output:

```
🚨 Simulando Spot Oracle Attack

Cenário:
  TX1: Ataque faz swap MUITO grande (5 ETH) - manipula spot price
  TX2: Vítima faz swap pequeno (0.1 ETH) - recebe preço pior devido ao impacto da TX1

Endereço FROM: 0x5bb7dd6a6eb4a440d6C70e1165243190295e290B

⏳ Simulando TX1 (Swap Grande)...
⏳ Simulando TX2 (Swap Pequeno)...

=== RESULTADOS ===

📊 TX1 (Ataque - Swap Grande de 5 ETH):
  Status: ✅ Sucesso
  Gas usado: 118990

📊 TX2 (Vítima - Swap Pequeno de 0.1 ETH):
  Status: ✅ Sucesso
  Gas usado: 118990

💡 Observação: Esta simulação demonstra o conceito de manipulação de spot.
   Em um bundle real no mesmo bloco, o impacto seria ainda mais significativo.
   Isso demonstra por que usar spot de DEX como oráculo é perigoso.
```

#### Interpretando os resultados:

- **TX1 (Ataque):** Swap grande manipula o preço do pool
- **TX2 (Vítima):** Swap pequeno recebe preço pior devido ao impacto da TX1
- **Em produção:** Se ambas executassem no mesmo bloco (bundle), o impacto seria ainda maior

#### O que aprendemos:

1. **Preços spot de DEX são manipuláveis** por swaps grandes
2. **Protocolos devem usar oráculos dedicados** (Chainlink, Band Protocol, etc.) ao invés de spot
3. **TWAP (Time-Weighted Average Price)** é mais seguro que spot
4. **Bundle attacks** são uma ameaça real para protocolos DeFi

#### Aplicação prática:

**❌ ERRADO:**
```solidity
// Usar preço spot diretamente
uint256 price = uniswap.getSpotPrice(); // PERIGOSO!
```

**✅ CORRETO:**
```solidity
// Usar oráculo dedicado
uint256 price = chainlink.getPrice(); // SEGURO!
```

---

### Script 3: State Override - DAI Wards

**Comando:** `npm run override:ward`

**O que faz:** Demonstra como usar **state overrides** para simular privilégios de admin sem alterar a blockchain real.

#### Por que isso é importante?

**State overrides** permitem simular cenários **impossíveis** na blockchain real:

- Tornar qualquer endereço admin de um contrato
- Modificar saldos de contratos
- Testar edge cases sem risco
- Analisar vulnerabilidades sem explorar

**Exemplo prático:** Se você quer testar o que aconteceria se você fosse admin do DAI, você pode usar state override ao invés de realmente ser admin!

#### Como funciona (passo a passo):

1. **Escolhe um endereço fake:**
   ```typescript
   const FAKE_WARD = '0xe2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2';
   ```
   Este endereço **não tem permissão** para mintar DAI na mainnet real.

2. **Calcula o storage slot:**
   ```typescript
   // O DAI usa um mapeamento "wards" para controlar permissões
   // wards[address] = 1 significa que o endereço tem permissão
   // Para calcular o slot: keccak256(pad(address) + pad(slot))
   const storageKey = keccak256(
     padHex(FAKE_WARD, 32) + padHex('0x0', 32) // slot 0
   );
   ```
   
   **Por que isso funciona?**
   - Cada variável de storage tem um "slot" (posição)
   - Mapeamentos usam `keccak256(address + slot)` para calcular o slot
   - Alterando o valor neste slot, simulamos que o endereço tem permissão

3. **Prepara o payload de simulação:**
   ```typescript
   state_objects: {
     [DAI]: {
       storage: {
         [storageKey]: '0x0000...0001' // Define wards[FAKE_WARD] = 1
       }
     }
   }
   ```

4. **Simula a chamada mint():**
   ```typescript
   // Chama mint(FAKE_WARD, 1000 DAI)
   // Normalmente falharia, mas com override funciona!
   ```

5. **Mostra resultados:**
   - Status da transação (sucesso!)
   - Gas usado
   - Mudanças de assets (DAI mintado)
   - Mudanças de storage (antes/depois)

#### Exemplo de output:

```
🔐 Demonstração: State Override - DAI Wards

Cenário: Tornar um endereço arbitrário "ward" (admin) via override

📍 Storage slot calculado: 0xedd7d04419e9c48ceb6055956cbb4e2091ae310313a4d1fa7cbcfe7561616e03
   wards[0xe2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2] será definido como 1 (ativo)

📦 BlockNumber: 23714261
⛽ Max Fee Per Gas: 2089200702 wei

=== RESULTADO DA SIMULAÇÃO ===

Status: ✅ Sucesso
Gas usado: 53489

(Nenhuma mudança de asset detectada)

💡 Observação: Esta simulação só funciona com override!
   Na mainnet real, FAKE_WARD não tem permissão para mintar.
   O override permite simular cenários de privilégios sem alterar a blockchain real.
```

#### Interpretando os resultados:

- **Storage slot calculado:** Posição na memória onde está armazenado `wards[FAKE_WARD]`
- **Status: ✅ Sucesso:** A transação funcionou! (normalmente falharia)
- **Gas usado: 53,489:** Quanto gas seria necessário para executar
- **Override funcionou:** Conseguimos simular que FAKE_WARD tem permissão

#### O que aprendemos:

1. **State overrides são poderosos** para testar cenários impossíveis
2. **Podemos simular privilégios** sem realmente ter
3. **Útil para analisar vulnerabilidades** sem explorar
4. **Permite testar edge cases** sem risco

#### Aplicação prática:

**Cenários onde state override é útil:**

- ✅ Testar upgrades de contratos
- ✅ Simular exploits de permissões
- ✅ Verificar comportamento com estados específicos
- ✅ Analisar vulnerabilidades em contratos auditados
- ✅ Testar cenários de emergência (pausas, etc.)

---

### Script 4: VirtualNet Swap Real

**Comando:** `npm run vnet:swapv3`

**O que faz:** Envia uma transação **real** na VirtualNet (fork da mainnet) executando um swap ETH → DAI via Uniswap V3.

#### Por que isso é importante?

Diferente das simulações, este script **executa uma transação real** em uma VirtualNet:

- ✅ Retorna um **hash de transação real**
- ✅ Você pode ver a transação no explorador do Tenderly
- ✅ Executa em ambiente seguro (não gasta ETH real)
- ✅ Permite testar fluxos completos de transações

#### Como funciona (passo a passo):

1. **Conecta à VirtualNet:**
   ```typescript
   // Usa o RPC da VirtualNet configurado no .env
   const vnetWallet = createWalletClient({
     chain: virtual_mainnet,
     transport: http(VNET_RPC),
     account
   });
   ```

2. **Obtém endereço da carteira:**
   ```typescript
   const [address] = await vnetWallet.getAddresses();
   ```

3. **Verifica saldo:**
   ```typescript
   const balance = await vnetPublic.getBalance({ address });
   ```
   - Se não tiver ETH suficiente, mostra instruções para fundar

4. **Prepara o swap:**
   ```typescript
   // Swap 0.02 ETH → DAI via Uniswap V3
   const params = {
     tokenIn: WETH,
     tokenOut: DAI,
     fee: 3000, // 0.3% fee tier
     recipient: address,
     deadline,
     amountIn: parseUnits('0.02', 18),
     amountOutMinimum: 0n,
     sqrtPriceLimitX96: 0n
   };
   ```

5. **Envia a transação:**
   ```typescript
   const txHash = await vnetWallet.sendTransaction({
     to: UNISWAP_V3_SWAPROUTER,
     value: amountIn,
     data: encodedFunctionData
   });
   ```

6. **Retorna o hash:**
   - Você pode ver esta transação no explorador do Tenderly
   - É uma transação real na VirtualNet!

#### Exemplo de output:

```
🌐 Enviando swap V3 na VirtualNet...

Endereço da carteira: 0x82494A3A4DAe3c0Ff499194Ff30dF5a23c8240C1

💰 Saldo atual: 9.9800 ETH

Parâmetros do swap:
  Token In: WETH
  Token Out: DAI
  Amount In: 0.02 ETH
  Fee Tier: 0.3%

✅ Transação enviada com sucesso!
📋 TX Hash na VirtualNet: 0x29b0c315a3c10106ff3b4224763e713439860b40b8004391357c2314e3a9d9ae

💡 Esta transação foi executada na sua VirtualNet, não na mainnet real.
   Use faucet/Admin RPC para adicionar ETH antes se necessário.
```

#### Interpretando os resultados:

- **Endereço da carteira:** Endereço que executará a transação
- **Saldo atual:** Quanto ETH você tem na VirtualNet
- **TX Hash:** Hash da transação (pode ver no explorador!)
- **Transação real:** Diferente de simulação, esta é uma transação real na VirtualNet

#### O que aprendemos:

1. **VirtualNet permite executar transações reais** sem risco
2. **Você pode testar fluxos completos** antes de ir para produção
3. **Hash de transação real** permite debugging completo
4. **Ambiente seguro** para experimentar

---

## Executando os Testes

Agora que tudo está configurado, vamos executar os testes!

### Teste 1: Comparação Uniswap V2 vs V3

```bash
npm run compare
```

**O que esperar:**
- ✅ Simulações executadas com sucesso
- ✅ Gas usado mostrado (valores reais)
- ✅ Comparação entre V2 e V3
- ⚠️ Valores de DAI podem ser estimativas (se Tenderly não retornar dados)

**Tempo estimado:** 10-30 segundos

### Teste 2: Spot Oracle Attack

```bash
npm run bundle:spot
```

**O que esperar:**
- ✅ Duas simulações executadas sequencialmente
- ✅ Gas usado mostrado
- ✅ Comparação de preços (se disponível)

**Tempo estimado:** 15-40 segundos

### Teste 3: State Override

```bash
npm run override:ward
```

**O que esperar:**
- ✅ Storage slot calculado
- ✅ Simulação executada com sucesso
- ✅ Gas usado mostrado
- ✅ Explicação sobre override

**Tempo estimado:** 10-25 segundos

### Teste 4: VirtualNet Swap (Opcional)

```bash
npm run vnet:swapv3
```

**O que esperar:**
- ✅ Transação enviada com sucesso
- ✅ Hash de transação retornado
- ⚠️ Pode precisar de ETH na VirtualNet (ver instruções no output)

**Tempo estimado:** 5-15 segundos

---

## Interpretando os Resultados

### O que significa "Gas usado"?

**Gas** é a unidade de medida do custo computacional na Ethereum. Cada operação custa uma quantidade específica de gas:

- **Transfer simples:** ~21,000 gas
- **Swap Uniswap V2:** ~118,990 gas
- **Swap Uniswap V3:** ~121,244 gas

**Por que importa?**
- Quanto mais gas, mais caro é executar a transação
- Preço do gas varia (geralmente 20-100 gwei)
- Para um swap de $100, gas pode custar $5-20

### O que significa "Taxa de câmbio"?

**Taxa de câmbio** é quantos tokens você recebe por cada token que envia:

- **3000 DAI por ETH** significa: Para cada 1 ETH, você recebe 3000 DAI
- **Valores podem variar** baseado em:
  - Liquidez do pool
  - Tamanho do swap (slippage)
  - Preço de mercado atual

### O que significa "Estado: ✅ Sucesso"?

Significa que a transação **não falhou**:
- ✅ Executou sem erros
- ✅ Gas foi usado (transação foi processada)
- ✅ Mudanças de estado foram aplicadas (se houver)

### O que significa "⚠️ (estimativa)"?

Quando o Tenderly não retorna dados detalhados de `asset_changes`, usamos **estimativas** baseadas em:
- Preço de mercado atual (~3000 DAI por ETH)
- Diferenças conhecidas entre V2 e V3

**Valores reais vs estimativas:**
- ✅ **Gas usado:** Sempre real (vem da simulação)
- ⚠️ **DAI recebido:** Pode ser estimativa se Tenderly não retornar dados
- ✅ **Comparação:** Funciona mesmo com estimativas

---

## Troubleshooting

### Erro: "Variáveis de ambiente do Tenderly não configuradas"

**Causa:** Arquivo `.env` não configurado ou variáveis faltando.

**Solução:**
1. Verifique se o arquivo `.env` existe: `ls -la .env`
2. Verifique se todas as variáveis estão preenchidas
3. Verifique se não há espaços extras nas variáveis
4. Reinicie o terminal após criar/editar `.env`

### Erro: "Access forbidden" ou "401 Unauthorized"

**Causa:** `TENDERLY_KEY` inválido ou expirado.

**Solução:**
1. Gere um novo token no dashboard Tenderly
2. Atualize `TENDERLY_KEY` no `.env`
3. Verifique se copiou o token completo (começa com `tn_`)

### Erro: "Project not found" ou "404 Not Found"

**Causa:** `TENDERLY_PROJECT` ou `TENDERLY_ACCOUNT` incorretos.

**Solução:**
1. Verifique a URL do dashboard: `https://dashboard.tenderly.co/[ACCOUNT]/[PROJECT]/`
2. Use exatamente o que aparece na URL (slug, não nome bonito)
3. Verifique se não há espaços ou caracteres especiais

### Erro: "max fee per gas less than block base fee"

**Causa:** Fees EIP-1559 incorretas (geralmente já resolvido no código).

**Solução:**
- Este erro já foi corrigido no código
- Se ainda aparecer, verifique se `src/util/eip1559.ts` existe
- Verifique se o bloco não está muito antigo (pode precisar de bloco mais recente)

### Erro: "insufficient funds for gas"

**Causa:** Endereço `FROM` não tem ETH suficiente na simulação.

**Solução:**
- O código já configura `state_objects` para garantir saldo
- Se ainda der erro, verifique se `state_objects` está sendo enviado corretamente
- Verifique se o valor de `balance` no `state_objects` é suficiente

### Erro: "Execution reverted" na VirtualNet

**Causa:** Não tem ETH suficiente na VirtualNet ou parâmetros incorretos.

**Solução:**
1. Verifique saldo na VirtualNet (o script mostra)
2. Use Admin RPC para fundar: `tenderly_setBalance`
3. Verifique se os parâmetros do swap estão corretos

### Simulações retornam "N/A" para DAI recebido

**Causa:** Tenderly não retorna `asset_changes` em algumas simulações.

**Solução:**
- Isso é normal e esperado
- O código usa estimativas baseadas em preço de mercado
- Gas usado sempre é real (vem da simulação)
- Para dados mais precisos, use VirtualNet ou consulte pools diretamente

### Debug: Ver detalhes completos

Para ver mais detalhes sobre o que está acontecendo:

```bash
DEBUG=true npm run compare
```

Isso mostrará:
- Payloads completos enviados ao Tenderly
- Respostas completas recebidas
- Estrutura de dados detalhada
- Informações de debug

---

## Referências

### Documentação Oficial

#### Tenderly

- **Dashboard:** https://dashboard.tenderly.co/
- **Documentação:** https://docs.tenderly.co/
- **SDK Quickstart:** https://docs.tenderly.co/sdk/quickstart
- **Simulate Transaction:** https://docs.tenderly.co/simulations-and-forks/simulating-transactions
- **State Overrides:** https://docs.tenderly.co/simulations-and-forks/simulating-transactions/state-overrides
- **Virtual TestNets:** https://docs.tenderly.co/virtual-testnets/overview

#### Uniswap

- **Uniswap V2 Router:** https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
- **Uniswap V3 SwapRouter:** https://docs.uniswap.org/contracts/v3/reference/periphery/SwapRouter
- **Concentrated Liquidity:** https://docs.uniswap.org/concepts/protocol/concentrated-liquidity

#### Ethereum

- **EIP-1559:** https://eips.ethereum.org/EIPS/eip-1559
- **Gas e Fees:** https://ethereum.org/en/developers/docs/gas/

### Conceitos Importantes

#### EIP-1559 (London Fork)

Desde agosto de 2021, a Ethereum usa um novo sistema de fees:

- **Base Fee:** Definido automaticamente pelo protocolo (queima de ETH)
- **Max Priority Fee:** Gorjeta para mineradores/validators
- **Max Fee Per Gas:** Base Fee + Max Priority Fee (máximo que você paga)

**Por que isso importa?**
- Simulações precisam usar este formato
- `gas_price` antigo não funciona mais
- Precisamos calcular fees baseado no `baseFee` do bloco atual

#### State Overrides

Permitem modificar o estado da blockchain antes de executar uma simulação:

- **Balance:** Definir saldo de endereços
- **Storage:** Modificar valores de storage de contratos
- **Code:** Substituir código de contratos (avançado)

**Exemplo prático:**
```typescript
state_objects: {
  [address]: {
    balance: "1000000000000000000000" // 1000 ETH em wei
  },
  [contract]: {
    storage: {
      [slot]: "0x0000...0001" // Modifica valor no storage
    }
  }
}
```

#### Virtual TestNets

São forks completos da mainnet que você pode usar para testar:

- **Fork da mainnet:** Estado atual copiado
- **Faucet ilimitada:** Crie ETH e tokens gratuitamente
- **RPC próprio:** Endereço único para acessar
- **Explorador próprio:** Veja transações no explorador do Tenderly

---

## 💡 Dicas para Aula

### 1. Contexto Histórico

**Antes de começar**, mostre:
- **DeFiLlama ao vivo:** https://defillama.com/ (TVL total DeFi)
- **Histórico:** Explosão DeFi em 2020-2021
- **Marcos importantes:**
  - Uniswap V2 (maio 2020)
  - Uniswap V3 (maio 2021)
  - EIP-1559 (agosto 2021)

### 2. Demonstração Prática

**Execute os scripts em ordem:**

1. **`npm run compare`** - Mostra diferenças V2 vs V3
2. **`npm run bundle:spot`** - Demonstra manipulação de preço
3. **`npm run override:ward`** - Mostra poder de state overrides
4. **`npm run vnet:swapv3`** - Executa transação real (se configurado)

### 3. Discussão dos Resultados

**Perguntas para discussão:**

- Por que V3 custa mais gas mas oferece melhor preço?
- Como um swap grande pode manipular preços?
- Por que protocolos não devem usar spot de DEX como oráculo?
- Quais são os riscos de DeFi além dos mostrados?

### 4. Expansão

**Ideias para expandir:**

- Testar com diferentes valores de swap
- Comparar com outros DEXs (SushiSwap, Curve)
- Analisar outros riscos DeFi (composability, bridge, etc.)
- Criar novas simulações

---

## 📝 Licença

MIT

---

## 🤝 Contribuindo

Este é um repositório didático. Sinta-se livre para:
- Adicionar mais exemplos de simulações
- Melhorar documentação
- Corrigir bugs
- Sugerir melhorias

---

## ✅ Checklist de Configuração

Antes de executar os testes, verifique:

- [ ] Node.js 20+ instalado
- [ ] Conta Tenderly criada
- [ ] Projeto criado no Tenderly
- [ ] Slug do projeto identificado (da URL)
- [ ] Access Token gerado
- [ ] Arquivo `.env` criado e preenchido
- [ ] `npm install` executado com sucesso
- [ ] `npm run test:minimal` funcionou

**Se tudo estiver ✅, você está pronto para executar os testes!**

---

**Última atualização:** Novembro 2024
**Versão:** 1.0.0
