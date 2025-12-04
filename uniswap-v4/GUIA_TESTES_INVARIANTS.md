# 🧪 Guia Didático: Testes de Invariantes

## 📋 Índice

1. [O que são Testes de Invariantes?](#o-que-são-testes-de-invariantes)
2. [Analogia Simples](#analogia-simples)
3. [Como Funcionam no Foundry](#como-funcionam-no-foundry)
4. [Análise do Nosso Teste](#análise-do-nosso-teste)
5. [O Problema Identificado](#o-problema-identificado)
6. [Solução Completa](#solução-completa)
7. [Explicação Passo a Passo](#explicação-passo-a-passo)

---

## 🎯 O que são Testes de Invariantes?

### Definição

Um **invariante** é uma propriedade que **sempre deve ser verdadeira**, não importa o que aconteça com o contrato.

### Exemplos de Invariantes

**Exemplo 1: Banco**
- **Invariante:** "A soma de todos os saldos das contas deve ser igual ao total de dinheiro no banco"
- **Por quê?** Se isso não for verdade, dinheiro sumiu ou foi criado do nada!

**Exemplo 2: Token ERC20**
- **Invariante:** "O totalSupply deve ser igual à soma de todos os saldos"
- **Por quê?** Se não for, tokens foram criados ou destruídos sem controle!

**Exemplo 3: Sistema de Votos**
- **Invariante:** "O número total de votos deve ser igual à soma dos votos de cada candidato"
- **Por quê?** Se não for, votos sumiram ou foram criados!

### Características de Invariantes

1. **Sempre Verdadeiros:** Não importa quantas operações aconteçam
2. **Fundamentais:** Se quebram, algo está muito errado
3. **Fáceis de Verificar:** Geralmente são comparações simples
4. **Importantes para Segurança:** Detectam bugs graves

---

## 🎭 Analogia Simples

### Analogia: Caixa de Dinheiro

Imagine uma **caixa de dinheiro** onde várias pessoas depositam e sacam:

```
┌─────────────────────────────────────┐
│      CAIXA DE DINHEIRO              │
│                                     │
│  Total na Caixa: R$ 1000            │
│                                     │
│  Contas:                            │
│  - Alice: R$ 300                    │
│  - Bob: R$ 200                     │
│  - Carol: R$ 500                   │
│                                     │
│  Invariante:                        │
│  Total = Alice + Bob + Carol        │
│  R$ 1000 = R$ 300 + R$ 200 + R$ 500│
│  ✅ SEMPRE DEVE SER VERDADEIRO!     │
└─────────────────────────────────────┘
```

**Se o invariante quebrar:**
- Total = R$ 1000, mas soma = R$ 900 → **R$ 100 sumiram!** 💸
- Total = R$ 1000, mas soma = R$ 1100 → **R$ 100 apareceram do nada!** ✨

**Isso é um problema grave!**

### No Nosso Token

```
┌─────────────────────────────────────┐
│      SIMPLE TOKEN                    │
│                                     │
│  totalSupply: 1000 tokens           │
│                                     │
│  Saldos:                            │
│  - Endereço A: 300 tokens          │
│  - Endereço B: 200 tokens          │
│  - Endereço C: 500 tokens          │
│                                     │
│  Invariante:                        │
│  totalSupply = Soma de todos saldos │
│  1000 = 300 + 200 + 500             │
│  ✅ SEMPRE DEVE SER VERDADEIRO!     │
└─────────────────────────────────────┘
```

---

## 🔧 Como Funcionam no Foundry

### Fluxo de um Teste de Invariante

```
┌─────────────────────────────────────────┐
│  1. setUp()                              │
│     - Deploy contratos                  │
│     - Configurar estado inicial          │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  2. Foundry cria "Handlers"             │
│     - Funções que fazem operações        │
│     - Ex: mint(), transfer(), burn()    │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  3. Foundry executa MUITAS operações    │
│     - Chama handlers aleatoriamente     │
│     - Com valores aleatórios            │
│     - Muitas vezes (ex: 1000x)          │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  4. Depois de cada operação (ou grupo)  │
│     - Chama função invariant_XXX()     │
│     - Verifica se invariante ainda é    │
│       verdadeiro                        │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  5. Se invariante quebrar:              │
│     - Teste FALHA                        │
│     - Foundry mostra sequência que      │
│       causou o problema                  │
└─────────────────────────────────────────┘
```

### Exemplo Visual

```
Tempo: 0
  totalSupply = 0
  Soma saldos = 0
  ✅ Invariante OK (0 == 0)

Tempo: 1 (mint para Alice, 100 tokens)
  totalSupply = 100
  Soma saldos = 100 (Alice tem 100)
  ✅ Invariante OK (100 == 100)

Tempo: 2 (transfer Alice → Bob, 50 tokens)
  totalSupply = 100
  Soma saldos = 100 (Alice: 50, Bob: 50)
  ✅ Invariante OK (100 == 100)

Tempo: 3 (mint para Carol, 200 tokens)
  totalSupply = 300
  Soma saldos = 300 (Alice: 50, Bob: 50, Carol: 200)
  ✅ Invariante OK (300 == 300)

... (muitas operações depois) ...

Tempo: 1000
  totalSupply = 5000
  Soma saldos = 4500 ❌
  ❌ INVARIANTE QUEBROU! (5000 != 4500)
  → BUG ENCONTRADO!
```

---

## 📝 Análise do Nosso Teste

### Código Atual

```solidity
contract SimpleTokenInvariantTest is Test {
    SimpleToken token;

    function setUp() public {
        token = new SimpleToken();
    }

    function invariant_TotalSupplyEqualsBalances() public view {
        uint256 sum;
        // PROBLEMA: Só soma o saldo do contrato de teste!
        sum += token.balanceOf(address(this));

        assertEq(token.totalSupply(), sum, "totalSupply != soma dos saldos");
    }
}
```

### O Problema

**O que o teste faz:**
1. Soma apenas o saldo de `address(this)` (o próprio contrato de teste)
2. Compara com `totalSupply`

**O que aconteceu no erro:**
```
mint(0x31807C52F661ab226FA9421144a2B9bFd5EBb974, 77569388563661973668893891328214)
```

- Tokens foram criados para outro endereço
- `totalSupply` = 77569388563661973668893891328214
- Mas `sum` só inclui `address(this)`, que tem 0
- Resultado: `77569388563661973668893891328214 != 0` ❌

**Analogia:**
É como contar o dinheiro na caixa, mas só olhar para uma conta e ignorar todas as outras!

---

## 🔍 O Problema Identificado

### Por que o Teste Falhou?

**Cenário:**
1. Foundry fez `mint` para endereço `0x31807C52F661ab226FA9421144a2B9bFd5EBb974`
2. Esse endereço recebeu tokens
3. `totalSupply` aumentou
4. Mas o teste só verifica `address(this)`, que não recebeu nada
5. Invariante quebrou!

**Visualização:**
```
Estado após mint:
┌─────────────────────────────────────┐
│  totalSupply: 775693885636619736... │
│                                     │
│  Saldos:                            │
│  - 0x31807C52...: 775693885636619...│  ← Tokens aqui!
│  - address(this): 0                 │  ← Teste só vê isso
│                                     │
│  Invariante verifica:               │
│  totalSupply (775693885636619...)   │
│  ==                                 │
│  sum (0)                            │
│  ❌ FALHA!                          │
└─────────────────────────────────────┘
```

### O que Precisamos Fazer?

**Solução:**
1. Rastrear TODOS os endereços que receberam tokens
2. Somar os saldos de TODOS esses endereços
3. Comparar com `totalSupply`

**Como fazer isso?**
- Usar um `mapping` para rastrear endereços
- Ou usar um array de endereços
- Ou usar handlers do Foundry (melhor solução)

---

## ✅ Solução Completa

### Versão Melhorada do Teste

Vou criar uma versão completa e didática:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/SimpleToken.sol";

/// @title SimpleTokenInvariantTest
/// @notice Teste de invariantes para SimpleToken
/// @dev Testa que totalSupply sempre é igual à soma de todos os saldos
contract SimpleTokenInvariantTest is Test {
    SimpleToken token;
    
    // Rastrear todos os endereços que receberam tokens
    address[] public actors;
    mapping(address => bool) public isActor;
    
    // Handlers para o Foundry chamar
    SimpleTokenHandler handler;

    function setUp() public {
        // 1. Deploy do token
        token = new SimpleToken();
        
        // 2. Deploy do handler (vai fazer operações aleatórias)
        handler = new SimpleTokenHandler(token, this);
        
        // 3. Registrar handlers para o Foundry usar
        targetContract(address(handler));
        
        // 4. Adicionar alguns endereços iniciais
        _addActor(address(this));
        _addActor(address(handler));
    }
    
    /// @notice Adiciona um endereço à lista de atores
    function _addActor(address actor) internal {
        if (!isActor[actor]) {
            actors.push(actor);
            isActor[actor] = true;
        }
    }
    
    /// @notice Invariante: totalSupply deve ser igual à soma de todos os saldos
    function invariant_TotalSupplyEqualsBalances() public view {
        uint256 sum;
        
        // Somar saldos de TODOS os atores conhecidos
        for (uint256 i = 0; i < actors.length; i++) {
            sum += token.balanceOf(actors[i]);
        }
        
        // O invariante: totalSupply deve ser igual à soma
        assertEq(
            token.totalSupply(), 
            sum, 
            "totalSupply deve ser igual à soma de todos os saldos"
        );
    }
    
    /// @notice Função pública para handlers adicionarem novos atores
    function addActor(address actor) external {
        // Apenas o handler pode adicionar atores
        require(msg.sender == address(handler), "Apenas handler pode adicionar");
        _addActor(actor);
    }
}

/// @title SimpleTokenHandler
/// @notice Handler que faz operações aleatórias no token para testes
/// @dev O Foundry vai chamar essas funções com valores aleatórios
contract SimpleTokenHandler is Test {
    SimpleToken token;
    SimpleTokenInvariantTest test;
    
    // Endereços que podem receber tokens
    address[] public possibleRecipients;
    
    constructor(SimpleToken _token, SimpleTokenInvariantTest _test) {
        token = _token;
        test = _test;
        
        // Adicionar alguns endereços possíveis
        possibleRecipients.push(address(this));
        possibleRecipients.push(address(test));
        possibleRecipients.push(address(0x1));
        possibleRecipients.push(address(0x2));
        possibleRecipients.push(address(0x3));
    }
    
    /// @notice Handler para mint - Foundry vai chamar com valores aleatórios
    function mint(address to, uint256 amount) public {
        // Limitar amount para evitar overflow
        amount = bound(amount, 1, type(uint128).max);
        
        // Escolher destinatário aleatório se não especificado
        if (to == address(0)) {
            to = possibleRecipients[uint256(keccak256(abi.encodePacked(block.timestamp))) % possibleRecipients.length];
        }
        
        // Fazer mint
        token.mint(to, amount);
        
        // Adicionar à lista de atores se for novo
        test.addActor(to);
    }
    
    /// @notice Handler para transfer - Foundry vai chamar com valores aleatórios
    function transfer(address to, uint256 amount) public {
        // Escolher remetente aleatório que tem saldo
        address from = _getRandomActorWithBalance();
        if (from == address(0)) return; // Ninguém tem saldo
        
        // Limitar amount
        uint256 maxAmount = token.balanceOf(from);
        if (maxAmount == 0) return;
        amount = bound(amount, 1, maxAmount);
        
        // Escolher destinatário aleatório se não especificado
        if (to == address(0)) {
            to = possibleRecipients[uint256(keccak256(abi.encodePacked(block.timestamp))) % possibleRecipients.length];
        }
        
        // Fazer transfer (precisa ser do ponto de vista do remetente)
        vm.prank(from);
        token.transfer(to, amount);
        
        // Adicionar destinatário à lista de atores se for novo
        test.addActor(to);
    }
    
    /// @notice Pega um ator aleatório que tem saldo
    function _getRandomActorWithBalance() internal view returns (address) {
        // Tentar alguns endereços conhecidos
        address[] memory candidates = new address[](possibleRecipients.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < possibleRecipients.length; i++) {
            if (token.balanceOf(possibleRecipients[i]) > 0) {
                candidates[count] = possibleRecipients[i];
                count++;
            }
        }
        
        if (count == 0) return address(0);
        
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp))) % count;
        return candidates[index];
    }
}
```

---

## 📚 Explicação Passo a Passo

### 1. Estrutura do Teste

```solidity
contract SimpleTokenInvariantTest is Test {
    SimpleToken token;
    address[] public actors;
    mapping(address => bool) public isActor;
    SimpleTokenHandler handler;
}
```

**O que cada variável faz:**

- `token`: O contrato que estamos testando
- `actors[]`: Lista de todos os endereços que receberam tokens
- `isActor`: Mapeamento para verificar rapidamente se um endereço é ator
- `handler`: Contrato que faz operações aleatórias

**Por quê isso?**
- Precisamos rastrear TODOS os endereços que têm tokens
- Senão, não conseguimos somar todos os saldos

### 2. Função setUp()

```solidity
function setUp() public {
    token = new SimpleToken();
    handler = new SimpleTokenHandler(token, this);
    targetContract(address(handler));
    _addActor(address(this));
    _addActor(address(handler));
}
```

**Passo a passo:**

1. **Deploy do token:** Criamos o contrato que vamos testar
2. **Deploy do handler:** Criamos o contrato que vai fazer operações
3. **targetContract:** Diz ao Foundry para usar o handler
4. **Adicionar atores iniciais:** Começamos com alguns endereços conhecidos

**O que é `targetContract`?**
- Diz ao Foundry: "Use este contrato para fazer operações aleatórias"
- O Foundry vai chamar as funções públicas do handler
- Com valores aleatórios

### 3. Função invariant_TotalSupplyEqualsBalances()

```solidity
function invariant_TotalSupplyEqualsBalances() public view {
    uint256 sum;
    
    // Somar saldos de TODOS os atores
    for (uint256 i = 0; i < actors.length; i++) {
        sum += token.balanceOf(actors[i]);
    }
    
    // Verificar invariante
    assertEq(token.totalSupply(), sum, "...");
}
```

**O que faz:**

1. **Inicializa `sum`:** Começa com 0
2. **Loop pelos atores:** Para cada endereço na lista
3. **Soma saldos:** Adiciona o saldo de cada ator
4. **Verifica:** Compara `totalSupply` com a soma

**Por quê funciona agora?**
- Rastreamos TODOS os endereços que receberam tokens
- Somamos TODOS os saldos
- Agora a comparação está correta!

### 4. O Handler

**O que é um Handler?**
- É um contrato que o Foundry usa para fazer operações
- O Foundry chama as funções públicas do handler
- Com valores aleatórios

**Por quê precisamos?**
- O Foundry não sabe como usar nosso contrato diretamente
- O handler "traduz" as operações para o Foundry
- E rastreia os endereços que receberam tokens

**Funções do Handler:**

##### `mint()`
```solidity
function mint(address to, uint256 amount) public {
    amount = bound(amount, 1, type(uint128).max);
    if (to == address(0)) {
        to = possibleRecipients[...];
    }
    token.mint(to, amount);
    test.addActor(to);
}
```

**O que faz:**
1. Limita `amount` para evitar overflow
2. Escolhe destinatário aleatório se não especificado
3. Faz o mint
4. Adiciona destinatário à lista de atores

##### `transfer()`
```solidity
function transfer(address to, uint256 amount) public {
    address from = _getRandomActorWithBalance();
    if (from == address(0)) return;
    
    amount = bound(amount, 1, token.balanceOf(from));
    
    vm.prank(from);
    token.transfer(to, amount);
    
    test.addActor(to);
}
```

**O que faz:**
1. Escolhe remetente que tem saldo
2. Limita `amount` ao saldo disponível
3. Usa `vm.prank` para simular que `from` está fazendo a chamada
4. Faz o transfer
5. Adiciona destinatário à lista de atores

**O que é `vm.prank`?**
- Cheatcode do Foundry
- Faz a próxima chamada como se fosse de outro endereço
- Necessário porque `transfer` verifica `msg.sender`

### 5. Função addActor()

```solidity
function addActor(address actor) external {
    require(msg.sender == address(handler), "Apenas handler");
    _addActor(actor);
}
```

**O que faz:**
- Permite que o handler adicione novos atores
- Apenas o handler pode chamar (segurança)
- Evita que qualquer um adicione atores falsos

**Por quê essa segurança?**
- Se qualquer um pudesse adicionar atores, poderíamos "trapacear"
- Adicionando endereços vazios, o invariante sempre passaria
- Mas não seria um teste real!

---

## 🎓 Conceitos Importantes

### 1. Invariantes vs Testes Normais

**Teste Normal:**
- Testa um cenário específico
- Ex: "Se eu fizer mint de 100 tokens, totalSupply deve ser 100"

**Teste de Invariante:**
- Testa uma propriedade que SEMPRE deve ser verdadeira
- Ex: "Não importa o que aconteça, totalSupply sempre é igual à soma dos saldos"

**Analogia:**
- Teste normal: "Se eu colocar 1kg de açúcar, a balança deve mostrar 1kg"
- Teste de invariante: "Não importa o que eu faça, a soma de tudo na balança sempre é igual ao total"

### 2. Handlers

**O que são:**
- Contratos que fazem operações no contrato que estamos testando
- O Foundry chama essas funções aleatoriamente
- Com valores aleatórios

**Por quê usar:**
- O Foundry não sabe como usar nosso contrato diretamente
- Handlers "traduzem" para o Foundry
- E garantem que operações são válidas

**Exemplo:**
```solidity
// Foundry não sabe fazer isso diretamente:
token.mint(alice, 100);  // Quem é alice? De onde vem 100?

// Handler faz isso:
function mint(address to, uint256 amount) public {
    // Escolhe valores válidos
    // Faz a operação
    // Rastreia o que aconteceu
}
```

### 3. Rastreamento de Estado

**Problema:**
- Em testes de invariantes, muitas operações acontecem
- Precisamos rastrear o estado para verificar invariantes
- Se não rastrearmos, não conseguimos verificar corretamente

**Solução:**
- Usar arrays ou mappings para rastrear
- Atualizar sempre que estado muda
- Verificar invariante usando o estado rastreado

**Exemplo:**
```solidity
// Rastrear endereços que receberam tokens
address[] public actors;

// Sempre que alguém recebe tokens:
actors.push(recipient);

// Verificar invariante:
uint256 sum;
for (uint256 i = 0; i < actors.length; i++) {
    sum += token.balanceOf(actors[i]);
}
```

### 4. bound() - Limitar Valores

**O que é:**
- Função do Foundry para limitar valores aleatórios
- Garante que valores estão em um range válido

**Sintaxe:**
```solidity
amount = bound(amount, min, max);
```

**Exemplo:**
```solidity
// Sem bound: amount pode ser qualquer valor (pode causar overflow)
amount = 999999999999999999999999999999999999999;

// Com bound: amount está entre 1 e 1000
amount = bound(amount, 1, 1000);
```

**Por quê usar:**
- Evita overflow
- Garante que operações são válidas
- Testes são mais eficientes

### 5. vm.prank() - Simular Chamadas

**O que é:**
- Cheatcode do Foundry para simular chamadas
- Faz a próxima chamada como se fosse de outro endereço

**Sintaxe:**
```solidity
vm.prank(alice);
token.transfer(bob, 100);
// A chamada acima é como se alice tivesse feito
```

**Por quê usar:**
- Algumas funções verificam `msg.sender`
- Em testes, queremos simular diferentes usuários
- `vm.prank` permite isso

---

## 🎯 Como Executar

### Comando Básico

```bash
forge test --match-contract SimpleTokenInvariantTest -vvv
```

### Com Mais Detalhes

```bash
forge test --match-contract SimpleTokenInvariantTest -vvvv
```

### Com Fuzzing Configurado

```bash
# No foundry.toml, configure:
[invariant]
runs = 256          # Número de sequências
depth = 15          # Profundidade de cada sequência
fail_on_revert = false  # Continuar mesmo com reverts
```

---

## 📊 Resumo

### O que Aprendemos

1. **Invariantes:** Propriedades que sempre devem ser verdadeiras
2. **Testes de Invariantes:** Testam essas propriedades com muitas operações aleatórias
3. **Handlers:** Contratos que fazem operações para o Foundry
4. **Rastreamento:** Precisamos rastrear estado para verificar invariantes
5. **bound():** Limita valores aleatórios para evitar problemas
6. **vm.prank():** Simula chamadas de outros endereços

### Checklist para Criar Testes de Invariantes

- [ ] Identificar invariantes do contrato
- [ ] Criar handler com operações válidas
- [ ] Rastrear estado necessário para verificar invariante
- [ ] Implementar função `invariant_XXX()` que verifica a propriedade
- [ ] Usar `bound()` para limitar valores
- [ ] Usar `vm.prank()` quando necessário
- [ ] Testar e ajustar

---

## 🎓 Para Sala de Aula

### Apresentação Sugerida

1. **Introdução (5 min)**
   - O que são invariantes (com analogia da caixa)
   - Por que são importantes

2. **Demonstração (10 min)**
   - Mostrar o teste atual (que falha)
   - Explicar por que falha
   - Mostrar a solução

3. **Código Passo a Passo (15 min)**
   - Explicar cada parte do código
   - Mostrar como handlers funcionam
   - Demonstrar execução

4. **Prática (10 min)**
   - Deixar alunos tentarem
   - Responder dúvidas

### Perguntas para Fazer

1. "Por que o teste original falhou?"
2. "O que é um handler?"
3. "Por que precisamos rastrear atores?"
4. "O que acontece se não usarmos `bound()`?"
5. "Por que usamos `vm.prank()`?"

---

**Bons estudos! 🎓**

Este guia cobre tudo sobre testes de invariantes. Use como referência para entender e ensinar!

