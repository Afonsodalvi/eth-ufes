# Como usar Slither neste projeto

## Problema conhecido

### Erro 1: `solc` não encontrado

Se você receber o erro:
```
FileNotFoundError: [Errno 2] No such file or directory: 'solc'
```

**Solução**: Especifique a versão do Solidity no `foundry.toml`:
```toml
[profile.default]
solc = "0.8.26"  # Adicione esta linha
```

O Slither detectará automaticamente e instalará o compilador necessário.

### Erro 2: Erro na biblioteca v4-core

O Slither não consegue compilar o projeto completo devido a um erro na biblioteca `v4-core`:
```
Error (2449): Definition of base has to precede definition of derived contract
  --> lib/v4-core/src/interfaces/IPoolManager.sol
```

Este é um problema conhecido na biblioteca Uniswap V4 e não afeta o funcionamento do projeto.

## Soluções

### Opção 1: Analisar apenas arquivos específicos (Recomendado) ✅

**IMPORTANTE**: Certifique-se de que o `foundry.toml` tem `solc = "0.8.26"` configurado!

Analise apenas os arquivos que você criou em `src/`:

```bash
# Analisar um arquivo específico (FUNCIONA!)
slither src/Counter.sol --foundry-ignore-compile

# Analisar o hook principal
slither src/hooks/PointsHook.sol --foundry-ignore-compile

# Analisar o token de pontos
slither src/tokens/PointsToken.sol --foundry-ignore-compile

# Analisar um diretório específico
slither src/hooks/ --foundry-ignore-compile --filter-paths "lib/"
```

### Opção 2: Usar script auxiliar

Use o script `slither-simple.sh` que tenta analisar o projeto ignorando a lib:

```bash
./scripts/slither-simple.sh
```

**Nota**: Este script pode ainda falhar devido ao problema de compilação, mas tentará filtrar os erros da lib.

### Opção 3: Analisar após compilação parcial

Se alguns contratos compilaram com sucesso (mesmo com erros na lib), você pode tentar:

```bash
# Compilar (pode falhar, mas alguns contratos podem ter compilado)
forge build --skip "*/test/**" --skip "*/script/**" || true

# Tentar usar artefatos compilados
slither . --foundry-ignore-compile --filter-paths "lib/" --exclude-dependencies
```

## Arquivos principais para análise

Os arquivos mais importantes para análise de segurança são:

- `src/hooks/PointsHook.sol` - Hook principal do projeto
- `src/tokens/PointsToken.sol` - Token de pontos
- `src/utils/HookUtils.sol` - Utilitários do hook
- `src/core/PoolManager.sol` - Versão customizada do PoolManager

## Exemplo de uso

**⚠️ Limitação**: Devido ao problema na lib, o Slither pode não funcionar diretamente. 

### Alternativa: Usar outras ferramentas

1. **Foundry's built-in checks**: O Foundry já faz várias verificações durante a compilação
2. **Manual review**: Revisão manual do código seguindo boas práticas
3. **Testes**: Os testes em `test/` já cobrem a funcionalidade principal

### Se quiser tentar o Slither mesmo assim:

```bash
# Tentar analisar um arquivo específico (pode falhar)
slither src/hooks/PointsHook.sol --ignore-compile --filter-paths "lib/" 2>&1 | grep -v "lib/" || echo "Análise não pôde ser concluída devido a dependências"
```

## Nota importante

O erro na lib `v4-core` **não afeta** a funcionalidade do seu código. É um problema interno da biblioteca Uniswap V4 que não impacta os contratos que você desenvolveu.

## Solução recomendada

Para análise de segurança, recomenda-se:
1. ✅ Revisão manual do código
2. ✅ Executar todos os testes: `forge test`
3. ✅ Usar testes de invariantes: `forge test --invariant`
4. ✅ Revisar os contratos principais manualmente

