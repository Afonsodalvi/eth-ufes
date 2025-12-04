# 🦄 Uniswap V4 Learning Lab

Projeto completo para aprender e testar o Uniswap V4 através de exemplos práticos e funcionais.

## 📚 Documentação

Este projeto inclui documentação completa em português:

1. **[UNISWAP_V4_GUIDE.md](./UNISWAP_V4_GUIDE.md)** - Guia técnico completo
   - Conceitos fundamentais
   - Arquitetura e componentes
   - Sistema de hooks
   - Estrutura do projeto

2. **[EXPLICACAO_COMPLETA.md](./EXPLICACAO_COMPLETA.md)** - Explicação para iniciantes
   - Conceitos explicados de forma simples
   - Analogias práticas
   - Exemplos passo a passo
   - Casos de uso reais

3. **[GUIA_DIDATICO_COMPLETO.md](./GUIA_DIDATICO_COMPLETO.md)** - Guia didático completo
   - Explicação passo a passo de todo o sistema
   - Fluxos detalhados de operações
   - Conceitos importantes
   
4. **[GUIA_TESTES_DIDATICO.md](./GUIA_TESTES_DIDATICO.md)** - Guia completo dos testes
   - Explicação detalhada de cada teste
   - Como funciona o fixture
   - Conceitos importantes de testes

## 🎯 O que você vai aprender

### Conceitos Fundamentais
- ✅ Arquitetura Singleton do V4
- ✅ Flash Accounting (EIP-1153)
- ✅ Sistema de Hooks
- ✅ PoolKey e PoolId
- ✅ Native ETH support

### Habilidades Práticas
- ✅ Criar hooks customizados
- ✅ Criar e gerenciar pools
- ✅ Adicionar/remover liquidez
- ✅ Executar swaps
- ✅ Testar hooks

## 🏗️ Estrutura do Projeto

```
uniswap-v4/
├── README.md                    # Este arquivo
├── UNISWAP_V4_GUIDE.md         # Guia técnico
├── EXPLICACAO_COMPLETA.md      # Explicação detalhada
├── PROJETO_PROPOSAL.md         # Proposta do projeto
│
├── lib/                         # Dependências
│   ├── v4-core/                # Uniswap V4 Core
│   └── v4-periphery/           # Uniswap V4 Periphery
│
├── src/
│   ├── hooks/                  # Hooks customizados
│   ├── tokens/                 # Tokens de teste
│   └── utils/                  # Utilitários
│
├── test/
│   ├── fixtures/               # Fixtures de teste
│   ├── hooks/                  # Testes de hooks
│   └── integration/            # Testes de integração
│
└── script/                     # Scripts de deploy
```

## 🚀 Quick Start

### Pré-requisitos
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (opcional, para scripts)

### Instalação

```bash
# 1. Navegar para o diretório
cd uniswap-v4

# 2. Instalar dependências do Uniswap V4
forge install Uniswap/v4-core 
forge install Uniswap/v4-periphery 

# 3. Instalar outras dependências
forge install OpenZeppelin/openzeppelin-contracts 

# 4. Build
forge build

# 5. Testes
forge test
```

## 📖 Como Usar Este Projeto

### 1. Leia a Documentação
Comece lendo os arquivos de documentação na ordem:
1. `EXPLICACAO_COMPLETA.md` - Para entender os conceitos básicos
2. `GUIA_DIDATICO_COMPLETO.md` - Para entender o sistema completo
3. `UNISWAP_V4_GUIDE.md` - Para detalhes técnicos
4. `GUIA_TESTES_DIDATICO.md` - Para entender os testes

### 2. Explore os Hooks
Cada hook tem:
- Código fonte em `src/hooks/`
- Testes em `test/hooks/`
- Documentação inline

### 3. Execute os Testes
```bash
# Configurar RPC no .env (obrigatório para fork)
ETHEREUM_MAINNET_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID

# Testar Points Hook
forge test --match-contract PointsHookTest

# Com verbosidade
forge test --match-contract PointsHookTest -vvv
```

### 4. Crie Seu Próprio Hook
Use os hooks existentes como template e crie o seu!

## 🎣 Hooks Implementados

### PointsHook
Recompensa usuários com pontos por swaps e adição de liquidez.

**Hooks usados:** `afterSwap`, `afterAddLiquidity`

**Documentação:**
- Ver `GUIA_DIDATICO_COMPLETO.md` para explicação completa
- Ver `GUIA_TESTES_DIDATICO.md` para entender os testes

## 🧪 Testes

```bash
# Todos os testes
forge test

# Testes específicos
forge test --match-contract PointsHookTest
forge test --match-contract LimitOrderHookTest

# Com gas report
forge test --gas-report

# Com traces detalhados
forge test -vvv
```

## 📝 Scripts

```bash
# Deploy de contratos
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast

# Criar pool
forge script script/CreatePool.s.sol --rpc-url $RPC_URL --broadcast

# Adicionar liquidez
forge script script/AddLiquidity.s.sol --rpc-url $RPC_URL --broadcast

# Fazer swap
forge script script/Swap.s.sol --rpc-url $RPC_URL --broadcast
```

## 🔗 Recursos

- [Documentação Oficial Uniswap V4](https://docs.uniswap.org/contracts/v4/overview)
- [Uniswap V4 Whitepaper](https://uniswap.org/whitepaper-v4.pdf)
- [GitHub: v4-core](https://github.com/Uniswap/v4-core)
- [GitHub: v4-periphery](https://github.com/Uniswap/v4-periphery)
- [GitHub: v4-template](https://github.com/uniswapfoundation/v4-template)

## 🤝 Contribuindo

Este é um projeto educacional. Sinta-se livre para:
- Adicionar novos hooks
- Melhorar documentação
- Adicionar exemplos
- Reportar issues

## 📄 Licença

Este projeto é para fins educacionais.

## ⚠️ Aviso

Este código é para **aprendizado e testes**. Não use em produção sem:
- Auditoria de segurança completa
- Testes extensivos
- Revisão de código profissional

---

**Happy Learning! 🚀**

Para dúvidas ou sugestões, abra uma issue ou entre em contato.

