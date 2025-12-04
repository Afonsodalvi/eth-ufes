# 🎓 Guia Step-by-Step para Remix IDE (Versão Simplificada)

## 📋 Preparação

### Passo 1: Acessar Remix IDE

1. Abra o navegador
2. Acesse: https://remix.ethereum.org/
3. Aguarde o carregamento completo

### Passo 2: Criar Estrutura de Pastas

No painel esquerdo do Remix, crie a seguinte estrutura:

```
contracts/
├── tokens/
│   ├── MockERC20.sol
│   └── PointsToken.sol
└── hooks/
    └── PointsHookDemo.sol
```

---

## 🔧 Passo 1: Configurar Ambiente

### 1.1 Selecionar Compilador

1. No painel esquerdo, clique em **"Solidity Compiler"** (ícone de Solidity)
2. Selecione a versão: **0.8.24**
3. Marque **"Auto compile"**

### 1.2 Configurar Ambiente de Deploy

1. No painel **"Deploy & Run Transactions"**
2. No dropdown **"Environment"**, selecione **"Remix VM"** ou **"JavaScript VM"**
3. Isso permite deploy e testes sem precisar de fork ou RPC

---

## 📝 Passo 2: Criar Contratos Base

### 2.1 MockERC20.sol

Crie o arquivo `contracts/tokens/MockERC20.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
```

**Explicação:**
- Token ERC20 simples para testes
- Permite mint e burn
- Usado como Token0 e Token1 nas pools

### 2.2 PointsToken.sol

Crie o arquivo `contracts/tokens/PointsToken.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PointsToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Points Token", "POINTS") Ownable(initialOwner) {}
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
```

**Explicação:**
- Token ERC20 que representa pontos
- Apenas o owner pode fazer mint
- O hook será o owner

---

## 🎣 Passo 3: Criar PointsHook para Demonstração

### 3.1 PointsHookDemo.sol (Versão Simplificada)

Crie o arquivo `contracts/hooks/PointsHookDemo.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../tokens/PointsToken.sol";

/**
 * @title PointsHookDemo - Versão Simplificada para Demonstração
 * @notice Hook que distribui pontos para usuários que fazem swaps ou adicionam liquidez
 * @dev Versão simplificada que pode ser chamada manualmente para demonstração
 */
contract PointsHookDemo {
    // Contrato do token de pontos
    PointsToken public immutable pointsToken;
    
    // Mapeamento de usuário para pontos
    mapping(address => uint256) public userPoints;
    
    // Mapeamento de poolId para volume
    mapping(bytes32 => uint256) public poolVolume;
    
    // Eventos
    event PointsAwarded(address indexed user, uint256 points, string reason);
    event VolumeRecorded(bytes32 indexed poolId, uint256 volume);
    
    constructor(PointsToken _pointsToken) {
        pointsToken = _pointsToken;
    }
    
    /**
     * @notice Função chamada após um swap (para demonstração)
     * @param user Endereço do usuário que fez o swap
     * @param swapValue Valor do swap em wei (ETH)
     * @param poolId ID da pool (opcional, para rastreamento)
     */
    function afterSwap(
        address user, 
        uint256 swapValue,
        bytes32 poolId
    ) external {
        // Calcular pontos (1 ETH = 1 ponto)
        uint256 points = swapValue;
        
        // Distribuir pontos
        if (points > 0) {
            userPoints[user] += points;
            pointsToken.mint(user, points);
            poolVolume[poolId] += swapValue;
            emit PointsAwarded(user, points, "swap");
            emit VolumeRecorded(poolId, swapValue);
        }
    }
    
    /**
     * @notice Função chamada após adicionar liquidez (para demonstração)
     * @param user Endereço do usuário que adicionou liquidez
     * @param liquidityValue Valor da liquidez em wei (ETH)
     * @param poolId ID da pool (opcional, para rastreamento)
     */
    function afterAddLiquidity(
        address user, 
        uint256 liquidityValue,
        bytes32 poolId
    ) external {
        // Calcular pontos (1 ETH = 1 ponto)
        uint256 points = liquidityValue;
        
        // Distribuir pontos
        if (points > 0) {
            userPoints[user] += points;
            pointsToken.mint(user, points);
            emit PointsAwarded(user, points, "liquidity");
        }
    }
    
    /**
     * @notice Consulta pontos de um usuário
     * @param user Endereço do usuário
     * @return Quantidade de pontos do usuário
     */
    function getPoints(address user) external view returns (uint256) {
        return userPoints[user];
    }
    
    /**
     * @notice Consulta volume de uma pool
     * @param poolId ID da pool
     * @return Volume total da pool em wei
     */
    function getPoolVolume(bytes32 poolId) external view returns (uint256) {
        return poolVolume[poolId];
    }
}
```

**Explicação:**
- Versão simplificada do hook para demonstração
- Remove dependências do Uniswap V4 para facilitar
- Mantém a lógica principal de distribuição de pontos
- Pode ser chamada manualmente para simular operações

---

## 🧪 Passo 4: Demonstração Interativa

### 4.1 Deploy dos Contratos

#### Passo 4.1.1: Deploy PointsToken

1. No painel **"Deploy & Run Transactions"**
2. Selecione **"PointsToken"** no dropdown
3. **IMPORTANTE**: No campo de parâmetros, coloque um endereço temporário
   - Exemplo: `0x1234567890123456789012345678901234567890`
   - Ou use um dos endereços disponíveis no Remix (Account dropdown)
4. Clique em **"Deploy"**
5. **Copie o endereço do contrato deployado** (você precisará dele)
6. Anote o endereço: `_________________________`

#### Passo 4.1.2: Deploy PointsHookDemo

1. Selecione **"PointsHookDemo"** no dropdown
2. No campo de parâmetros, cole o endereço do PointsToken deployado
3. Clique em **"Deploy"**
4. **Copie o endereço do PointsHookDemo**
5. Anote o endereço: `_________________________`

#### Passo 4.1.3: Configurar Ownership

1. No contrato **PointsToken** deployado, encontre a função **"transferOwnership"**
2. Cole o endereço do **PointsHookDemo** no campo
3. Clique em **"transact"**
4. Verifique que o owner agora é o PointsHookDemo:
   - Função: `owner()`
   - Clique em **"call"**
   - Deve retornar o endereço do PointsHookDemo

#### Passo 4.1.4: Deploy MockERC20 (Opcional)

1. Selecione **"MockERC20"** no dropdown
2. Parâmetros: `"Token0"`, `"TKN0"`
3. Clique em **"Deploy"**

---

### 4.2 Simular Operações

#### Cenário 1: Usuário faz Swap

**Passo a Passo:**

1. **Escolher um endereço de teste:**
   - No Remix, você pode usar qualquer endereço do dropdown "Account"
   - Ou usar um endereço específico como: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`

2. **Simular swap de 1 ETH:**
   - No contrato **PointsHookDemo** deployado
   - Função: `afterSwap`
   - Parâmetros:
     - `user`: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2` (ou outro endereço)
     - `swapValue`: `1000000000000000000` (1 ETH em wei)
     - `poolId`: `0x0000000000000000000000000000000000000000000000000000000000000001` (exemplo)
   - Clique em **"transact"**

3. **Verificar pontos:**
   - Função: `getPoints`
   - Parâmetro: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`
   - Clique em **"call"**
   - **Resultado esperado**: `1000000000000000000` (1 ETH = 1 ponto)

4. **Verificar saldo do token:**
   - No contrato **PointsToken** deployado
   - Função: `balanceOf`
   - Parâmetro: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`
   - Clique em **"call"**
   - **Resultado esperado**: `1000000000000000000`

5. **Verificar volume da pool:**
   - No contrato **PointsHookDemo** deployado
   - Função: `getPoolVolume`
   - Parâmetro: `0x0000000000000000000000000000000000000000000000000000000000000001`
   - Clique em **"call"**
   - **Resultado esperado**: `1000000000000000000`

#### Cenário 2: Usuário adiciona Liquidez

**Passo a Passo:**

1. **Usar um endereço diferente:**
   - Exemplo: `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db`
   - Ou outro endereço do dropdown "Account"

2. **Simular adição de liquidez de 5 ETH:**
   - No contrato **PointsHookDemo** deployado
   - Função: `afterAddLiquidity`
   - Parâmetros:
     - `user`: `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db`
     - `liquidityValue`: `5000000000000000000` (5 ETH em wei)
     - `poolId`: `0x0000000000000000000000000000000000000000000000000000000000000001`
   - Clique em **"transact"**

3. **Verificar pontos:**
   - Função: `getPoints`
   - Parâmetro: `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db`
   - Clique em **"call"**
   - **Resultado esperado**: `5000000000000000000`

4. **Verificar saldo do token:**
   - No contrato **PointsToken** deployado
   - Função: `balanceOf`
   - Parâmetro: `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db`
   - Clique em **"call"**
   - **Resultado esperado**: `5000000000000000000`

#### Cenário 3: Múltiplos Swaps Acumulam Pontos

**Passo a Passo:**

1. **Usuário faz primeiro swap:**
   - `afterSwap(user: 0xAb..., swapValue: 1 ETH, poolId: 0x...01)`
   - Verificar: `getPoints(0xAb...)` = 1 ETH

2. **Usuário faz segundo swap:**
   - `afterSwap(user: 0xAb..., swapValue: 2 ETH, poolId: 0x...01)`
   - Verificar: `getPoints(0xAb...)` = 3 ETH (1 + 2)

3. **Usuário faz terceiro swap:**
   - `afterSwap(user: 0xAb..., swapValue: 0.5 ETH, poolId: 0x...01)`
   - Verificar: `getPoints(0xAb...)` = 3.5 ETH (1 + 2 + 0.5)

4. **Verificar volume acumulado:**
   - `getPoolVolume(0x...01)` = 3.5 ETH

---

## 📊 Demonstração Visual no Remix

### Layout Recomendado

```
┌─────────────────────────────────────────────────────────┐
│                    REMIX IDE                             │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  [File Explorer]    [Solidity Compiler]  [Deploy]      │
│                                                          │
│  contracts/         Compiler: 0.8.24    Environment:    │
│  ├── tokens/        Auto compile: ✓     Remix VM       │
│  └── hooks/         ────────────────────────────────────│
│                      [PointsHookDemo Deployed]            │
│                      ┌─────────────────────┐             │
│                      │ afterSwap           │             │
│                      │ user: 0xAb...      │             │
│                      │ swapValue: 1 ETH    │             │
│                      │ poolId: 0x...01     │             │
│                      │ [transact]          │             │
│                      ├─────────────────────┤             │
│                      │ getPoints           │             │
│                      │ user: 0xAb...       │             │
│                      │ [call] → 1 ETH     │             │
│                      └─────────────────────┘             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Vantagens da Versão Simplificada

✅ **Fácil de Configurar**: Não precisa de RPC ou fork  
✅ **Funciona Imediatamente**: Deploy e teste direto no Remix  
✅ **Foco no Conceito**: Demonstra a lógica de hooks sem complexidade  
✅ **Sem Dependências Externas**: Não precisa de serviços externos  
✅ **Ideal para Aprendizado**: Perfeito para entender o conceito básico

---

## 🎯 Pontos de Atenção para a Apresentação

### 1. Explicar o Conceito de Hooks

**Falar:**
- "Hooks são como plugins no Uniswap V4"
- "Eles permitem adicionar lógica customizada"
- "São chamados automaticamente pelo PoolManager"
- "Nesta versão simplificada, chamamos manualmente para demonstração"

**Mostrar:**
- O contrato PointsHookDemo
- Como ele distribui pontos após operações

### 2. Explicar o Sistema de Pontos

**Falar:**
- "1 ETH de swap = 1 ponto"
- "1 ETH de liquidez = 1 ponto"
- "Pontos são acumulativos"

**Mostrar:**
- Fazer múltiplos swaps
- Verificar que pontos acumulam

### 3. Explicar a Integração

**Falar:**
- "O hook precisa ser owner do PointsToken"
- "Isso permite que ele faça mint"
- "Em produção, isso seria feito no deploy"

**Mostrar:**
- Transferir ownership
- Tentar fazer mint sem ser owner (falha)
- Fazer mint sendo owner (sucesso)

---

## 🔍 Perguntas Frequentes Durante a Apresentação

### Q1: "Por que o hook precisa ser owner do token?"

**R:** O PointsToken usa `onlyOwner` para proteger a função `mint()`. Isso garante que apenas o hook possa criar novos pontos, evitando inflação descontrolada.

### Q2: "Como isso funcionaria no Uniswap V4 real?"

**R:** No Uniswap V4 real:
- O PoolManager chama o hook automaticamente
- O hook recebe informações sobre a operação (delta, params)
- O hook processa e retorna um selector para validação
- **Esta versão simplificada demonstra o conceito sem precisar do PoolManager real**

### Q3: "Os pontos têm valor?"

**R:** Nesta implementação, os pontos são apenas um sistema de gamificação. Em produção, poderiam ser:
- Trocados por recompensas
- Usados para descontos
- Convertidos em tokens reais

### Q4: "Isso custa gas?"

**R:** Sim, cada operação custa gas:
- Deploy dos contratos: ~2-3M gas
- Cada swap/liquidity: +20-50k gas (pelo hook)
- Consultas (getPoints): Gratuitas (view)

---

## 📝 Checklist para a Apresentação

### Antes da Aula

- [ ] Testar todos os contratos no Remix
- [ ] Preparar endereços de exemplo
- [ ] Ter valores de exemplo prontos (1 ETH, 5 ETH, etc.)
- [ ] Preparar slides com diagramas
- [ ] Testar a conexão de internet

### Durante a Apresentação

- [ ] Explicar o conceito de hooks
- [ ] Mostrar o código do PointsHookDemo
- [ ] Deploy dos contratos
- [ ] Demonstrar swap → pontos
- [ ] Demonstrar liquidez → pontos
- [ ] Mostrar acumulação de pontos
- [ ] Responder perguntas

### Após a Apresentação

- [ ] Compartilhar código
- [ ] Compartilhar este guia
- [ ] Oferecer suporte para dúvidas

---

## 🎬 Roteiro de Apresentação (15-20 minutos)

### Parte 1: Introdução (3 min)
- O que são hooks no Uniswap V4
- Por que são úteis
- Exemplo: sistema de pontos

### Parte 2: Código (5 min)
- Mostrar PointsHookDemo.sol
- Explicar funções principais
- Explicar eventos

### Parte 3: Demonstração (7 min)
- Deploy dos contratos
- Simular swap → ver pontos
- Simular liquidez → ver pontos
- Mostrar acumulação

### Parte 4: Q&A (5 min)
- Responder perguntas
- Explicar detalhes técnicos
- Próximos passos

---

## 🚀 Extensões Possíveis

### Para Próximas Aulas

1. **Adicionar Taxa de Pontos:**
   - 1 ETH = 0.5 pontos (50% de taxa)

2. **Adicionar Decaimento:**
   - Pontos diminuem com o tempo

3. **Adicionar Níveis:**
   - Bronze, Prata, Ouro baseado em pontos

4. **Adicionar Recompensas:**
   - Trocar pontos por tokens

---

## 📚 Recursos Adicionais

### Documentação
- [Remix IDE](https://remix.ethereum.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Uniswap V4 Docs](https://docs.uniswap.org/contracts/v4/overview)

### Guias Relacionados
- [Guia Didático Completo](./GUIA_DIDATICO_COMPLETO.md) - Explicação completa dos conceitos
- [Diagramas Visuais](./DIAGRAMAS_VISUAIS.md) - Diagramas para entender melhor

---

## ⚠️ Troubleshooting

### Problema: Contratos não compilam

**Solução:**
1. Verifique se está usando Solidity 0.8.24
2. Verifique se os imports do OpenZeppelin estão corretos
3. Tente compilar manualmente

### Problema: Transações falhando

**Solução:**
1. Verifique se você tem ETH suficiente no account selecionado
2. Verifique se os parâmetros estão corretos
3. Verifique os logs de erro no console

### Problema: Ownership não funciona

**Solução:**
1. Verifique se o PointsToken foi deployado corretamente
2. Verifique se o endereço do hook está correto
3. Certifique-se de que a transação de transferOwnership foi executada

---

## 🎯 Vantagens da Versão Simplificada

### Para Apresentação:
- 🎯 Mais fácil de configurar
- 🎯 Funciona imediatamente
- 🎯 Foco no conceito principal
- 🎯 Sem dependências externas

### Para Aprendizado:
- 📚 Entende o conceito básico de hooks
- 📚 Vê como pontos são distribuídos
- 📚 Aprende sobre ownership e controle
- 📚 Prática com Solidity básico

---

**Boa apresentação! 🎓**
