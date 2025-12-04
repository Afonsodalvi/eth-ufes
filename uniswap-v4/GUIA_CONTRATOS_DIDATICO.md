# 📚 Guia Didático Completo: Contratos do PointsHook

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [PointsToken: O Token de Pontos](#pointstoken-o-token-de-pontos)
3. [PointsHook: O Coração do Sistema](#pointshook-o-coração-do-sistema)
4. [HookUtils: Ferramentas Úteis](#hookutils-ferramentas-úteis)
5. [PoolManager: A Versão Customizada](#poolmanager-a-versão-customizada)
6. [PointsHookTest: Para Testes](#pointshooktest-para-testes)
7. [Como Tudo Se Conecta](#como-tudo-se-conecta)

---

## 🎯 Visão Geral

Este guia explica **passo a passo** cada contrato que implementamos para criar o sistema de pontos da Uniswap V4. Vamos entender **o que cada contrato faz**, **por que ele existe**, e **como tudo se conecta**.

### Arquitetura Completa

```
┌─────────────────────────────────────────────────────────┐
│                    Uniswap V4 Pool                       │
│              (PoolManager Oficial)                       │
└─────────────────────────────────────────────────────────┘
                        │
                        │ chama hooks
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  PointsHook                             │
│  - Recebe chamadas do PoolManager                       │
│  - Calcula pontos                                       │
│  - Distribui pontos                                    │
└─────────────────────────────────────────────────────────┘
                        │
                        │ usa
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  PointsToken                            │
│  - Token ERC20 para pontos                              │
│  - Apenas o hook pode criar pontos (mint)               │
└─────────────────────────────────────────────────────────┘
```

### Contratos que Vamos Entender

1. **PointsToken** - O token que representa os pontos
2. **PointsHook** - O hook que distribui pontos
3. **HookUtils** - Funções auxiliares para trabalhar com hooks
4. **PoolManager** - Versão customizada do PoolManager
5. **PointsHookTest** - Versão de teste do hook

---

## 🪙 PointsToken: O Token de Pontos

### O que é?

O `PointsToken` é um **token ERC20** que representa os pontos que os usuários ganham. É como uma moeda virtual que você ganha fazendo swaps ou adicionando liquidez.

### Analogia

Imagine que você está em um programa de fidelidade:
- Cada vez que você faz uma compra, ganha pontos
- Esses pontos são registrados em uma conta
- Você pode ver quantos pontos tem
- Os pontos são como uma moeda virtual

O `PointsToken` é exatamente isso: uma moeda virtual (token ERC20) que representa seus pontos.

### Estrutura do Contrato

```solidity
contract PointsToken is ERC20, Ownable {
    // Herda de ERC20 (token padrão)
    // Herda de Ownable (tem um dono)
}
```

**O que isso significa?**
- `ERC20`: É um token padrão, como USDC ou DAI
- `Ownable`: Tem um dono que pode controlar certas funções

### Análise Linha por Linha

#### 1. Imports

```solidity
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
```

**O que faz:**
- Importa o contrato `ERC20` da OpenZeppelin (biblioteca padrão)
- Importa o contrato `Ownable` da OpenZeppelin

**Por quê?**
- Não precisamos reinventar a roda
- OpenZeppelin é auditado e seguro
- `ERC20` já tem tudo que precisamos para um token
- `Ownable` já tem controle de acesso

**Analogia:**
É como usar peças de LEGO prontas em vez de fazer tudo do zero.

#### 2. Construtor

```solidity
constructor(address initialOwner) 
    ERC20("Points Token", "POINTS") 
    Ownable(initialOwner) 
{}
```

**O que faz:**
1. Recebe `initialOwner` (o dono inicial)
2. Cria um token ERC20 com nome "Points Token" e símbolo "POINTS"
3. Define `initialOwner` como o dono do contrato

**Por quê `initialOwner`?**
- O hook precisa ser o dono para poder criar pontos
- Se o hook não for dono, não pode fazer `mint()`
- Definimos no construtor para evitar problemas depois

**Exemplo:**
```solidity
// Quando criamos o token:
PointsToken token = new PointsToken(hookAddress);
// hookAddress é o dono
// hookAddress pode criar pontos
```

#### 3. Função `mint()`

```solidity
function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
}
```

**O que faz:**
- Cria novos pontos e dá para o endereço `to`
- Só o dono pode chamar (por causa de `onlyOwner`)

**Por quê `onlyOwner`?**
- Se qualquer um pudesse criar pontos, seria uma bagunça!
- Apenas o hook (que é o dono) pode criar pontos
- Isso garante que pontos só são criados quando o hook decide

**Fluxo:**
```
Hook quer dar pontos → Hook chama token.mint(usuario, 100) 
                    → Token verifica: "Hook é o dono?" 
                    → Se sim, cria 100 pontos para o usuário ✅
                    → Se não, reverte ❌
```

**Analogia:**
É como um banco: apenas o banco pode criar dinheiro. Você não pode criar dinheiro do nada.

#### 4. Funções de Transfer (Comentadas)

```solidity
/*
function transfer(address, uint256) public pure override returns (bool) {
    revert("Points are non-transferable");
}
*/
```

**O que faz:**
- Está comentado, então não está ativo
- Se descomentado, impediria transferência de pontos

**Por quê comentado?**
- Por padrão, tokens ERC20 podem ser transferidos
- Se quisermos que pontos sejam não-transferíveis, descomentamos
- Por enquanto, deixamos transferível (mais flexível)

**Se descomentado:**
- Pontos não podem ser transferidos
- Pontos não podem ser vendidos
- Pontos são apenas para o usuário que ganhou

**Analogia:**
É como pontos de fidelidade que não podem ser transferidos para outra pessoa.

### Resumo do PointsToken

| Aspecto | Explicação |
|---------|------------|
| **O que é** | Token ERC20 que representa pontos |
| **Quem pode criar pontos** | Apenas o dono (o hook) |
| **Quem pode receber pontos** | Qualquer endereço |
| **Pontos podem ser transferidos?** | Sim (por padrão), mas pode ser desabilitado |
| **Por que existe** | Para representar pontos de forma padronizada (ERC20) |

---

## 🎣 PointsHook: O Coração do Sistema

### O que é?

O `PointsHook` é o **coração do sistema**. Ele é chamado automaticamente pelo PoolManager quando alguém faz um swap ou adiciona liquidez, e ele decide quantos pontos dar e para quem.

### Analogia

Imagine um sistema de recompensas em um shopping:
- Você faz uma compra (swap)
- O sistema detecta automaticamente
- O sistema calcula quantos pontos você ganha
- O sistema dá os pontos para você

O `PointsHook` é esse sistema automático, mas para a Uniswap V4.

### Estrutura do Contrato

```solidity
contract PointsHook is BaseHook {
    // Herda de BaseHook (classe base da Uniswap V4)
    // Implementa afterSwap e afterAddLiquidity
}
```

**O que é BaseHook?**
- É uma classe base fornecida pela Uniswap V4
- Já tem muita coisa pronta
- Nós só implementamos as funções que queremos

**Analogia:**
É como herdar de uma classe base que já tem métodos prontos, e você só adiciona o que precisa.

### Análise Detalhada

#### 1. Variáveis de Estado

```solidity
PointsToken public immutable pointsToken;
mapping(address => uint256) public userPoints;
mapping(PoolId => uint256) public poolVolume;
uint256 public constant POINTS_PER_ETH = 1e18;
```

**Vamos entender cada uma:**

##### `pointsToken`
```solidity
PointsToken public immutable pointsToken;
```

**O que é:**
- Referência ao token de pontos
- `immutable` significa que não pode ser mudado depois do construtor

**Por quê `immutable`?**
- Mais eficiente em gas
- Garante que o token não muda depois de deployado
- É uma garantia de segurança

**Analogia:**
É como ter um endereço fixo de uma loja. Você sabe que sempre será aquele endereço.

##### `userPoints`
```solidity
mapping(address => uint256) public userPoints;
```

**O que é:**
- Mapeamento de endereço para quantidade de pontos
- Cada usuário tem seu próprio contador de pontos

**Como funciona:**
```solidity
userPoints[alice] = 100;  // Alice tem 100 pontos
userPoints[bob] = 50;     // Bob tem 50 pontos
```

**Analogia:**
É como um caderno onde você anota quantos pontos cada pessoa tem.

##### `poolVolume`
```solidity
mapping(PoolId => uint256) public poolVolume;
```

**O que é:**
- Mapeamento de pool para volume total
- Rastreia quanto volume cada pool teve

**Por quê?**
- Para estatísticas
- Para ver qual pool é mais ativa
- Para análises futuras

**Analogia:**
É como um contador de vendas por loja. Você sabe qual loja vendeu mais.

##### `POINTS_PER_ETH`
```solidity
uint256 public constant POINTS_PER_ETH = 1e18;
```

**O que é:**
- Constante que define: 1 ETH = 1 ponto
- `1e18` = 1 ETH (em wei)

**Por quê constante?**
- Não muda
- Fácil de entender
- Pode ser ajustado se necessário (mas precisa recompilar)

**Analogia:**
É como uma regra fixa: "1 real = 1 ponto". Sempre será assim.

#### 2. Eventos

```solidity
event PointsAwarded(address indexed user, uint256 points, string reason);
event VolumeRecorded(PoolId indexed poolId, uint256 volume);
```

**O que são eventos?**
- São logs que ficam na blockchain
- Podem ser "ouvidos" por aplicações externas
- São importantes para frontends e indexadores

**Por quê usar eventos?**
- Frontends podem mostrar quando pontos são dados
- Indexadores podem rastrear todas as distribuições
- É uma forma de comunicação com o mundo externo

**Analogia:**
É como um alto-falante anunciando: "Alice ganhou 100 pontos por fazer um swap!"

#### 3. Construtor

```solidity
constructor(IPoolManager _poolManager, PointsToken _pointsToken) 
    BaseHook(_poolManager) 
{
    pointsToken = _pointsToken;
}
```

**O que faz:**
1. Recebe o PoolManager e o PointsToken
2. Chama o construtor do BaseHook com o PoolManager
3. Guarda a referência ao PointsToken

**Por quê precisa do PoolManager?**
- O BaseHook precisa saber qual PoolManager usar
- O hook será chamado pelo PoolManager

**Por quê precisa do PointsToken?**
- Para poder criar pontos quando necessário

**Fluxo de Deploy:**
```
1. Criar PointsToken (hook é o dono)
2. Criar PointsHook (passa PoolManager e PointsToken)
3. Hook está pronto para usar!
```

#### 4. Função `getHookPermissions()`

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: true,  // ✅ Implementamos
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: false,
        afterSwap: true,  // ✅ Implementamos
        // ... outros false
    });
}
```

**O que faz:**
- Diz ao Uniswap V4 quais hooks este contrato implementa
- `true` = implementamos, `false` = não implementamos

**Por quê isso é importante?**
- O Uniswap V4 verifica isso antes de chamar o hook
- Se disser `true` mas não implementar, vai dar erro
- Se disser `false`, o hook não será chamado

**O que implementamos:**
- ✅ `afterAddLiquidity`: Chamado depois de adicionar liquidez
- ✅ `afterSwap`: Chamado depois de fazer swap

**Por quê só esses?**
- São os únicos que precisamos para distribuir pontos
- Não precisamos de `beforeSwap` (não fazemos nada antes)
- Não precisamos de `afterRemoveLiquidity` (não damos pontos para remover)

**Analogia:**
É como dizer ao sistema: "Eu só quero ser chamado depois de swaps e depois de adicionar liquidez. Não me chame em outros momentos."

#### 5. Função `_afterSwap()`

Esta é a função mais importante! Ela é chamada automaticamente depois de cada swap.

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    // 1. Calcular valor do swap em ETH
    uint256 swapValue = _calculateSwapValue(key, delta);
    
    // 2. Atualizar volume da pool
    PoolId poolId = key.toId();
    poolVolume[poolId] += swapValue;
    
    // 3. Calcular pontos
    uint256 points = _calculatePoints(swapValue);
    
    // 4. Descobrir quem é o usuário real
    address recipient = sender;
    if (hookData.length == 32) {
        address dataAddress = abi.decode(hookData, (address));
        if (dataAddress != address(0)) {
            recipient = dataAddress;
        }
    }
    
    // 5. Distribuir pontos
    if (points > 0) {
        userPoints[recipient] += points;
        pointsToken.mint(recipient, points);
        emit PointsAwarded(recipient, points, "swap");
    }
    
    // 6. Emitir evento de volume
    emit VolumeRecorded(poolId, swapValue);
    
    // 7. Retornar selector correto
    return (IHooks.afterSwap.selector, 0);
}
```

**Vamos entender passo a passo:**

##### Passo 1: Calcular Valor do Swap

```solidity
uint256 swapValue = _calculateSwapValue(key, delta);
```

**O que faz:**
- Calcula quanto ETH foi movimentado no swap
- Se swap foi de 1 ETH → Token0, `swapValue = 1 ETH`
- Se swap foi de Token0 → 1 ETH, `swapValue = 1 ETH`

**Por quê?**
- Precisamos saber o valor para calcular pontos
- Só damos pontos baseado em ETH (não em outros tokens)

**Analogia:**
É como calcular quanto você gastou em uma compra para saber quantos pontos ganha.

##### Passo 2: Atualizar Volume

```solidity
PoolId poolId = key.toId();
poolVolume[poolId] += swapValue;
```

**O que faz:**
- Calcula o ID da pool
- Adiciona o valor do swap ao volume total da pool

**Por quê?**
- Para estatísticas
- Para saber qual pool tem mais volume

**Analogia:**
É como adicionar uma venda ao total de vendas da loja.

##### Passo 3: Calcular Pontos

```solidity
uint256 points = _calculatePoints(swapValue);
```

**O que faz:**
- Calcula quantos pontos dar baseado no valor
- 1 ETH = 1 ponto (POINTS_PER_ETH = 1e18)

**Como funciona:**
```solidity
function _calculatePoints(uint256 value) internal pure returns (uint256) {
    return value;  // 1 ETH = 1 ponto
}
```

**Exemplo:**
- Swap de 1 ETH → `points = 1 ETH`
- Swap de 0.5 ETH → `points = 0.5 ETH`
- Swap de 2 ETH → `points = 2 ETH`

**Analogia:**
É como calcular: "Você gastou 100 reais, então ganha 100 pontos."

##### Passo 4: Descobrir Usuário Real

```solidity
address recipient = sender;
if (hookData.length == 32) {
    address dataAddress = abi.decode(hookData, (address));
    if (dataAddress != address(0)) {
        recipient = dataAddress;
    }
}
```

**O que faz:**
- Por padrão, `recipient = sender` (quem chamou)
- Se `hookData` contém um endereço, usa esse endereço

**Por quê isso é necessário?**
- Em produção, `sender` é o router (não o usuário real)
- Em testes, passamos o usuário real via `hookData`
- Isso permite que o hook saiba quem é o usuário real

**Analogia:**
É como descobrir quem realmente fez a compra, não quem processou o pagamento.

**Exemplo:**
```
Usuário → Router → PoolManager → Hook
         ↑ sender é o router
         Mas queremos dar pontos para o usuário!
         
Solução: Router passa usuário via hookData
Hook lê hookData e descobre o usuário real ✅
```

##### Passo 5: Distribuir Pontos

```solidity
if (points > 0) {
    userPoints[recipient] += points;
    pointsToken.mint(recipient, points);
    emit PointsAwarded(recipient, points, "swap");
}
```

**O que faz:**
1. Atualiza o contador de pontos do usuário
2. Cria os pontos no token
3. Emite evento para o mundo saber

**Por quê verificar `points > 0`?**
- Se não houver pontos, não faz nada
- Economiza gas
- Evita eventos desnecessários

**Fluxo Completo:**
```
Swap de 1 ETH acontece
    ↓
Hook calcula: swapValue = 1 ETH
    ↓
Hook calcula: points = 1 ETH
    ↓
Hook atualiza: userPoints[alice] += 1 ETH
    ↓
Hook cria: pointsToken.mint(alice, 1 ETH)
    ↓
Hook emite: PointsAwarded(alice, 1 ETH, "swap")
    ↓
Alice agora tem 1 ETH em pontos! ✅
```

##### Passo 6: Retornar Selector

```solidity
return (IHooks.afterSwap.selector, 0);
```

**O que faz:**
- Retorna o selector da função `afterSwap`
- Retorna `0` para o delta adicional (não modificamos o swap)

**Por quê?**
- O PoolManager verifica se o hook retornou o selector correto
- Se não retornar, o PoolManager reverte
- É uma forma de validação

**Analogia:**
É como assinar um documento. Você precisa assinar corretamente para ser válido.

#### 6. Função `_afterAddLiquidity()`

Similar ao `_afterSwap`, mas para adicionar liquidez.

```solidity
function _afterAddLiquidity(
    address sender,
    PoolKey calldata key,
    ModifyLiquidityParams calldata params,
    BalanceDelta delta,
    BalanceDelta feesAccrued,
    bytes calldata hookData
) internal override returns (bytes4, BalanceDelta) {
    // 1. Calcular valor da liquidez em ETH
    uint256 liquidityValue = _calculateLiquidityValue(key, delta);
    
    // 2. Calcular pontos
    uint256 points = _calculatePoints(liquidityValue);
    
    // 3. Descobrir usuário real (mesmo código do afterSwap)
    address recipient = sender;
    if (hookData.length == 32) {
        address dataAddress = abi.decode(hookData, (address));
        if (dataAddress != address(0)) {
            recipient = dataAddress;
        }
    }
    
    // 4. Distribuir pontos
    if (points > 0) {
        userPoints[recipient] += points;
        pointsToken.mint(recipient, points);
        emit PointsAwarded(recipient, points, "liquidity");
    }
    
    // 5. Retornar selector correto
    return (IHooks.afterAddLiquidity.selector, BalanceDelta.wrap(0));
}
```

**Diferenças do `_afterSwap`:**
- Não atualiza volume (volume é só para swaps)
- Usa `_calculateLiquidityValue` em vez de `_calculateSwapValue`
- Retorna `BalanceDelta` em vez de `int128`

**Por quê dar pontos por liquidez?**
- Incentiva pessoas a adicionar liquidez
- Mais liquidez = melhor para todos
- É uma forma de recompensar provedores de liquidez

**Analogia:**
É como dar pontos para quem deposita dinheiro no banco. Quanto mais você deposita, mais pontos ganha.

#### 7. Função `_calculateSwapValue()`

```solidity
function _calculateSwapValue(PoolKey calldata key, BalanceDelta delta) 
    internal view returns (uint256) 
{
    int128 amount0 = delta.amount0();
    int128 amount1 = delta.amount1();
    
    // Se currency0 é ETH
    if (Currency.unwrap(key.currency0) == address(0)) {
        return uint256(uint128(amount0 < 0 ? -amount0 : amount0));
    }
    
    // Se currency1 é ETH
    if (Currency.unwrap(key.currency1) == address(0)) {
        return uint256(uint128(amount1 < 0 ? -amount1 : amount1));
    }
    
    // Se nenhum é ETH, retorna 0
    return 0;
}
```

**O que faz:**
- Pega os valores do `delta` (mudança de saldo)
- Verifica qual currency é ETH (address(0))
- Retorna o valor absoluto em ETH

**Por quê valor absoluto?**
- `delta` pode ser negativo (saída) ou positivo (entrada)
- Queremos o valor total, não importa a direção
- `amount0 < 0 ? -amount0 : amount0` pega o valor absoluto

**Exemplo:**
```
Swap: 1 ETH → Token0
delta.amount0() = -1 ETH (ETH saiu)
swapValue = |-1 ETH| = 1 ETH ✅

Swap: Token0 → 1 ETH
delta.amount1() = 1 ETH (ETH entrou)
swapValue = |1 ETH| = 1 ETH ✅
```

**Por quê retornar 0 se nenhum é ETH?**
- Só damos pontos para swaps com ETH
- Swaps Token/Token não geram pontos
- É uma decisão de design

**Analogia:**
É como calcular quanto você gastou, mas só contando gastos em reais, não em dólares.

#### 8. Função `_calculateLiquidityValue()`

Similar ao `_calculateSwapValue`, mas para liquidez.

```solidity
function _calculateLiquidityValue(PoolKey calldata key, BalanceDelta delta) 
    internal view returns (uint256) 
{
    // Mesma lógica do _calculateSwapValue
    // Mas para liquidez
}
```

**Diferença:**
- Usa a mesma lógica
- Mas é chamado quando liquidez é adicionada
- Calcula quanto ETH foi adicionado

#### 9. Função `_calculatePoints()`

```solidity
function _calculatePoints(uint256 value) internal pure returns (uint256) {
    return value;  // 1 ETH = 1 ponto
}
```

**O que faz:**
- Simplesmente retorna o valor
- 1 ETH = 1 ponto (POINTS_PER_ETH = 1e18)

**Por quê tão simples?**
- Por enquanto, é 1:1
- Pode ser modificado no futuro para ter fórmulas mais complexas
- Por exemplo: "1 ETH = 2 pontos" ou "pontos com bônus"

**Analogia:**
É como uma regra simples: "1 real = 1 ponto". Pode ser mudada depois para "1 real = 2 pontos" se quisermos.

#### 10. Funções de Consulta

```solidity
function getPoints(address user) external view returns (uint256) {
    return userPoints[user];
}

function getPoolVolume(PoolId poolId) external view returns (uint256) {
    return poolVolume[poolId];
}
```

**O que fazem:**
- `getPoints`: Retorna quantos pontos um usuário tem
- `getPoolVolume`: Retorna o volume total de uma pool

**Por quê `view`?**
- Não modificam o estado
- Podem ser chamadas gratuitamente (sem gas)
- São apenas para consulta

**Analogia:**
É como perguntar "Quantos pontos eu tenho?" sem fazer nenhuma ação.

### Resumo do PointsHook

| Aspecto | Explicação |
|---------|------------|
| **O que é** | Hook que distribui pontos automaticamente |
| **Quando é chamado** | Depois de swaps e depois de adicionar liquidez |
| **O que faz** | Calcula pontos e distribui para usuários |
| **Como calcula pontos** | 1 ETH = 1 ponto |
| **Onde guarda pontos** | No `userPoints` mapping e no `PointsToken` |

---

## 🛠️ HookUtils: Ferramentas Úteis

### O que é?

O `HookUtils` é uma biblioteca com funções auxiliares para trabalhar com hooks. São ferramentas que facilitam o trabalho.

### Analogia

É como uma caixa de ferramentas. Você não precisa usar, mas facilita muito quando precisa.

### Análise Detalhada

#### 1. Função `calculateHookAddress()`

```solidity
function calculateHookAddress(uint160 flags) 
    internal pure returns (address hookAddress) 
{
    uint160 hookPermissionCount = 14;
    uint160 clearAllHookPermissionsMask = ~uint160(0) << hookPermissionCount;
    
    return address(
        uint160(
            type(uint160).max & clearAllHookPermissionsMask | flags
        )
    );
}
```

**O que faz:**
- Calcula o endereço onde o hook deve ser deployado
- Baseado nas flags (permissões) do hook

**Como funciona:**
1. Limpa os últimos 14 bits do endereço máximo
2. Adiciona as flags nos últimos bits
3. Retorna o endereço calculado

**Por quê isso é necessário?**
- O Uniswap V4 usa os últimos bits do endereço para indicar permissões
- Isso permite verificar permissões sem chamada externa
- É uma otimização de gas

**Exemplo:**
```solidity
uint160 flags = Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG;
address hookAddress = calculateHookAddress(flags);
// hookAddress tem as flags corretas nos últimos bits
```

**Analogia:**
É como calcular um endereço especial onde o hook deve morar, baseado nas permissões que ele tem.

#### 2. Função `validateHookPermissions()`

```solidity
function validateHookPermissions(
    IHooks hook,
    Hooks.Permissions memory permissions
) internal pure returns (bool isValid) {
    Hooks.validateHookPermissions(hook, permissions);
    return true;
}
```

**O que faz:**
- Valida se um hook tem as permissões corretas
- Usa a função da biblioteca `Hooks`

**Por quê?**
- Garante que o hook está configurado corretamente
- Útil para testes e validações

**Analogia:**
É como verificar se uma pessoa tem as credenciais corretas para entrar em um lugar.

#### 3. Função `hasPermission()`

```solidity
function hasPermission(IHooks hook, uint160 flag) 
    internal pure returns (bool) 
{
    return hook.hasPermission(flag);
}
```

**O que faz:**
- Verifica se um hook tem uma permissão específica
- Retorna `true` ou `false`

**Por quê?**
- Útil para verificar permissões antes de fazer algo
- Pode ser usado em testes

**Analogia:**
É como perguntar: "Você tem permissão para fazer X?" e receber sim ou não.

### Resumo do HookUtils

| Aspecto | Explicação |
|---------|------------|
| **O que é** | Biblioteca de funções auxiliares |
| **Para que serve** | Facilitar trabalho com hooks |
| **É obrigatório?** | Não, mas é útil |
| **Quando usar** | Quando precisa calcular endereços ou validar permissões |

---

## 🏊 PoolManager: A Versão Customizada

### O que é?

O `PoolManager` é uma versão customizada do PoolManager oficial da Uniswap V4. Foi criada para resolver problemas de compatibilidade de tipos.

### Por que existe uma versão customizada?

**Problema:**
- O PoolManager oficial usa `IPoolManager.ModifyLiquidityParams`
- Os hooks usam `ModifyLiquidityParams` (de `PoolOperation.sol`)
- Mesmo que sejam idênticos, Solidity não permite conversão automática
- Isso causa erros de compilação

**Solução:**
- Criamos nossa própria versão do PoolManager
- Ela converte os tipos corretamente antes de chamar os hooks
- Isso resolve os problemas de compatibilidade

**Analogia:**
É como ter um tradutor que converte entre dois idiomas que são quase iguais, mas têm pequenas diferenças.

### O que foi modificado?

#### 1. Import dos Tipos Corretos

```solidity
import {ModifyLiquidityParams as HookModifyLiquidityParams, 
        SwapParams as HookSwapParams} 
    from "v4-core/types/PoolOperation.sol";
```

**O que faz:**
- Importa os tipos que os hooks esperam
- Usa aliases (`as`) para evitar conflitos de nomes

**Por quê aliases?**
- Já existe `ModifyLiquidityParams` no `IPoolManager`
- Precisamos de ambos, mas com nomes diferentes
- Aliases resolvem isso

#### 2. Conversão em `modifyLiquidity()`

```solidity
// Converter IPoolManager.ModifyLiquidityParams para HookModifyLiquidityParams
HookModifyLiquidityParams memory hookParams = HookModifyLiquidityParams({
    tickLower: params.tickLower,
    tickUpper: params.tickUpper,
    liquidityDelta: params.liquidityDelta,
    salt: params.salt
});

// Chamar hook com tipos corretos
Hooks.beforeModifyLiquidity(key.hooks, key, hookParams, hookData);
```

**O que faz:**
1. Recebe `IPoolManager.ModifyLiquidityParams` (tipo externo)
2. Converte para `HookModifyLiquidityParams` (tipo interno)
3. Chama o hook com o tipo correto

**Por quê isso funciona?**
- Criamos uma nova struct com os mesmos valores
- Solidity aceita isso porque estamos criando uma nova struct
- O hook recebe o tipo que espera

**Analogia:**
É como pegar um documento em português, traduzir para inglês, e entregar para alguém que só fala inglês.

#### 3. Conversão em `swap()`

Similar ao `modifyLiquidity`, mas para swaps:

```solidity
// Converter IPoolManager.SwapParams para HookSwapParams
HookSwapParams memory hookSwapParams = HookSwapParams({
    zeroForOne: params.zeroForOne,
    amountSpecified: params.amountSpecified,
    sqrtPriceLimitX96: params.sqrtPriceLimitX96
});

// Chamar hook com tipos corretos
Hooks.beforeSwap(key.hooks, key, hookSwapParams, hookData);
```

**Mesma lógica:**
- Recebe tipo externo
- Converte para tipo interno
- Chama hook

### Resumo do PoolManager Customizado

| Aspecto | Explicação |
|---------|------------|
| **O que é** | Versão customizada do PoolManager oficial |
| **Por que existe** | Resolver problemas de compatibilidade de tipos |
| **O que faz diferente** | Converte tipos antes de chamar hooks |
| **É seguro?** | Sim, apenas converte tipos, não muda lógica |
| **Quando usar** | Em desenvolvimento/testes (em produção, usar oficial) |

---

## 🧪 PointsHookTest: Para Testes

### O que é?

O `PointsHookTest` é uma versão especial do `PointsHook` que não valida o endereço no construtor. É usado apenas em testes.

### Por que existe?

**Problema:**
- O `BaseHook` (que `PointsHook` herda) valida o endereço no construtor
- Ele verifica se o endereço tem as flags corretas
- Em testes, usamos `vm.etch` para colocar código em um endereço específico
- `vm.etch` não executa o construtor
- Mas precisamos que o código esteja no endereço correto

**Solução:**
- Criamos `PointsHookTest` que não valida o endereço
- Deployamos normalmente (construtor executa)
- Copiamos o bytecode para o endereço correto com `vm.etch`
- Agora o código está no endereço certo, e os valores `immutable` estão corretos

**Analogia:**
É como ter uma chave mestra que abre qualquer porta, mas só usamos em testes. Em produção, usamos a chave normal.

### Análise Detalhada

#### 1. Herança

```solidity
contract PointsHookTest is PointsHook {
    // Herda tudo do PointsHook
    // Mas sobrescreve validateHookAddress
}
```

**O que faz:**
- Herda tudo do `PointsHook`
- Mas pode sobrescrever funções específicas

**Por quê herdar?**
- Não precisamos reescrever tudo
- Só mudamos o que precisa mudar
- Reutiliza todo o código do `PointsHook`

#### 2. Construtor

```solidity
constructor(IPoolManager _poolManager, PointsToken _pointsToken) 
    PointsHook(_poolManager, _pointsToken) 
{}
```

**O que faz:**
- Chama o construtor do `PointsHook`
- Não faz nada adicional

**Por quê?**
- Só precisamos que o construtor execute
- Os valores `immutable` (manager, pointsToken) serão definidos
- Depois copiamos o bytecode para outro endereço

#### 3. Sobrescrita de `validateHookAddress()`

```solidity
function validateHookAddress(BaseHook _this) internal pure override {
    // Não faz nada - não valida em testes
}
```

**O que faz:**
- Não valida o endereço
- Permite deploy em qualquer endereço

**Por quê isso é seguro em testes?**
- Em testes, controlamos tudo
- Sabemos que vamos colocar no endereço correto depois
- Em produção, nunca usaríamos isso

**Analogia:**
É como desabilitar o alarme de uma casa durante uma reforma. Você sabe que está seguro porque está controlando tudo.

### Como é usado nos testes?

```solidity
// 1. Deploy temporário
PointsHookTest tempHook = new PointsHookTest(manager, pointsToken);

// 2. Pegar bytecode
bytes memory hookCode = address(tempHook).code;

// 3. Colocar no endereço correto
vm.etch(hookAddress, hookCode);

// 4. Criar referência
hook = PointsHook(payable(hookAddress));
```

**Fluxo:**
1. Deploy normal (construtor executa, valores `immutable` são definidos)
2. Pegamos o bytecode (que já tem os valores `immutable`)
3. Colocamos no endereço correto com `vm.etch`
4. Agora temos o hook no endereço certo, com tudo configurado!

**Por quê funciona?**
- `immutable` são valores que vão direto no bytecode
- Quando copiamos o bytecode, copiamos os valores também
- O endereço não importa para os valores `immutable`

### Resumo do PointsHookTest

| Aspecto | Explicação |
|---------|------------|
| **O que é** | Versão de teste do PointsHook |
| **Diferença** | Não valida endereço no construtor |
| **Por que existe** | Permitir deploy em qualquer endereço para testes |
| **É seguro?** | Sim, apenas para testes |
| **Quando usar** | Apenas em testes, nunca em produção |

---

## 🔗 Como Tudo Se Conecta

### Fluxo Completo: Swap com Pontos

Vamos ver como tudo funciona junto quando alguém faz um swap:

```
┌─────────────────────────────────────────────────────────┐
│  1. Usuário faz swap                                     │
│     Usuário → Router → PoolManager                       │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  2. PoolManager executa swap                             │
│     - Calcula preço                                       │
│     - Atualiza liquidez                                   │
│     - Calcula delta                                       │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  3. PoolManager chama Hook.afterSwap()                   │
│     PoolManager → PointsHook._afterSwap()                │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  4. PointsHook calcula pontos                            │
│     - Calcula valor do swap em ETH                        │
│     - Calcula pontos (1 ETH = 1 ponto)                   │
│     - Descobre usuário real (via hookData)               │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  5. PointsHook distribui pontos                           │
│     - Atualiza userPoints[usuário]                        │
│     - Chama pointsToken.mint(usuário, pontos)             │
│     - Emite evento PointsAwarded                          │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  6. PointsToken cria pontos                              │
│     - Verifica: hook é dono? ✅                           │
│     - Cria pontos para o usuário                         │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  7. Usuário recebe pontos! ✅                             │
│     - userPoints[usuário] atualizado                     │
│     - pointsToken.balanceOf(usuário) atualizado          │
│     - Evento emitido na blockchain                       │
└─────────────────────────────────────────────────────────┘
```

### Fluxo Completo: Adicionar Liquidez com Pontos

Similar ao swap, mas para liquidez:

```
Usuário adiciona liquidez
    ↓
PoolManager executa modifyLiquidity
    ↓
PoolManager chama Hook.afterAddLiquidity
    ↓
PointsHook calcula pontos baseado em ETH adicionado
    ↓
PointsHook distribui pontos
    ↓
PointsToken cria pontos
    ↓
Usuário recebe pontos! ✅
```

### Diagrama de Dependências

```
PointsHook
    ├── depende de → PointsToken (para criar pontos)
    ├── depende de → IPoolManager (para saber qual pool)
    ├── usa → HookUtils (opcional, para cálculos)
    └── herda de → BaseHook (da Uniswap V4)

PointsToken
    ├── herda de → ERC20 (token padrão)
    └── herda de → Ownable (controle de acesso)

PoolManager (customizado)
    ├── implementa → IPoolManager
    └── converte tipos → para chamar hooks

PointsHookTest
    └── herda de → PointsHook (mas não valida endereço)
```

### Resumo de Responsabilidades

| Contrato | Responsabilidade |
|----------|------------------|
| **PointsToken** | Criar e gerenciar tokens de pontos |
| **PointsHook** | Calcular e distribuir pontos |
| **HookUtils** | Funções auxiliares para hooks |
| **PoolManager** | Gerenciar pools e chamar hooks |
| **PointsHookTest** | Versão de teste do hook |

---

## 🎓 Conceitos Importantes

### 1. Herança em Solidity

**O que é:**
- Um contrato pode herdar de outro
- Herda todas as funções e variáveis
- Pode sobrescrever funções

**Exemplo:**
```solidity
contract A {
    function foo() public {}
}

contract B is A {
    // B tem foo() também!
    // Pode sobrescrever se quiser
}
```

**Por quê usar:**
- Reutiliza código
- Evita duplicação
- Facilita manutenção

### 2. Immutable vs Constant

**Immutable:**
- Definido no construtor
- Pode ser diferente para cada deploy
- Mais eficiente em gas que variável normal

**Constant:**
- Definido em tempo de compilação
- Sempre o mesmo valor
- Mais eficiente que immutable

**Exemplo:**
```solidity
uint256 public constant POINTS_PER_ETH = 1e18;  // constant
PointsToken public immutable pointsToken;        // immutable
```

### 3. Mappings

**O que são:**
- Estruturas de dados que mapeiam chave → valor
- Muito eficientes em Solidity
- Sempre retornam um valor (0 se não existir)

**Exemplo:**
```solidity
mapping(address => uint256) public userPoints;

userPoints[alice] = 100;  // Define
uint256 points = userPoints[alice];  // Lê (retorna 100)
uint256 points2 = userPoints[bob];  // Lê (retorna 0, não existe)
```

**Analogia:**
É como um dicionário: você procura uma palavra (chave) e encontra o significado (valor).

### 4. Events

**O que são:**
- Logs que ficam na blockchain
- Podem ser "ouvidos" por aplicações externas
- Não custam muito gas

**Por quê usar:**
- Frontends podem reagir a eventos
- Indexadores podem rastrear tudo
- É uma forma de comunicação

**Exemplo:**
```solidity
event PointsAwarded(address indexed user, uint256 points);

emit PointsAwarded(alice, 100);
// Frontend pode "ouvir" isso e mostrar para o usuário
```

### 5. Modifiers

**O que são:**
- Funções que modificam o comportamento de outras funções
- Podem verificar condições antes de executar

**Exemplo:**
```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;  // Continua execução
}

function mint() external onlyOwner {
    // Só executa se passar pelo onlyOwner
}
```

**Analogia:**
É como um porteiro: verifica se você pode entrar antes de deixar passar.

---

## 📊 Resumo Final

### PointsToken
- **O que é:** Token ERC20 para pontos
- **Responsabilidade:** Criar e gerenciar pontos
- **Quem pode criar pontos:** Apenas o dono (hook)

### PointsHook
- **O que é:** Hook que distribui pontos
- **Responsabilidade:** Calcular e distribuir pontos automaticamente
- **Quando é chamado:** Depois de swaps e adicionar liquidez

### HookUtils
- **O que é:** Biblioteca de funções auxiliares
- **Responsabilidade:** Facilitar trabalho com hooks
- **É obrigatório?** Não, mas é útil

### PoolManager (Customizado)
- **O que é:** Versão customizada do PoolManager
- **Responsabilidade:** Gerenciar pools e chamar hooks com tipos corretos
- **Por que existe:** Resolver problemas de compatibilidade

### PointsHookTest
- **O que é:** Versão de teste do hook
- **Responsabilidade:** Permitir testes com deploy flexível
- **Quando usar:** Apenas em testes

---

## 🎯 Próximos Passos

Depois de entender os contratos, você pode:

1. **Modificar o hook:**
   - Mudar a fórmula de pontos
   - Adicionar novos tipos de recompensas
   - Adicionar validações

2. **Adicionar funcionalidades:**
   - Sistema de níveis
   - Bônus por volume
   - Recompensas especiais

3. **Explorar mais:**
   - Ver outros hooks da Uniswap V4
   - Entender outros padrões
   - Criar seu próprio hook

---

**Bons estudos! 🎓**

Este guia cobre todos os contratos implementados. Se tiver dúvidas, consulte os outros guias ou o código fonte diretamente!

