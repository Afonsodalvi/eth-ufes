# Explicação do Problema e Solução

## 🔴 Problema Encontrado

```
TypeError [ERR_UNKNOWN_FILE_EXTENSION]: Unknown file extension ".ts"
```

### Por que aconteceu?

O Node.js não reconhece arquivos `.ts` (TypeScript) nativamente. Para executar TypeScript diretamente, precisamos de um loader ou transpilador.

O `ts-node` com `--esm` tem problemas conhecidos com ESM (ES Modules):
- Requer configurações complexas no `tsconfig.json`
- Precisa de loaders especiais do Node.js
- Tem problemas de compatibilidade com `"type": "module"` no `package.json`

## ✅ Solução Aplicada

### Mudança 1: Substituição do `ts-node` por `tsx`

**Antes:**
```json
"scripts": {
  "compare": "ts-node --esm src/simulate/01_uniswap_compare.ts"
}
```

**Depois:**
```json
"scripts": {
  "compare": "tsx src/simulate/01_uniswap_compare.ts"
}
```

### Por que `tsx`?

1. ✅ **Funciona nativamente com ESM** - Não precisa de flags especiais
2. ✅ **Mais rápido** - Usa esbuild internamente
3. ✅ **Menos configuração** - Funciona out-of-the-box
4. ✅ **Melhor suporte** - Mantido ativamente e muito usado pela comunidade

### Mudança 2: Remoção da configuração `ts-node` do `tsconfig.json`

Removemos:
```json
"ts-node": {
  "esm": true
}
```

Não é mais necessário com `tsx`.

## 📦 Como Aplicar a Correção

1. **Instalar `tsx`:**
   ```bash
   npm install --save-dev tsx
   ```

2. **Remover `ts-node` (opcional, mas recomendado):**
   ```bash
   npm uninstall ts-node
   ```

3. **Testar os scripts:**
   ```bash
   npm run compare
   ```

## 🎯 Resultado Esperado

Agora os scripts devem executar sem erros:

```bash
$ npm run compare

🔄 Comparando Uniswap V2 vs V3...
Entrada: 0.01 ETH
Endereço FROM: 0x...

=== RESULTADOS ===
...
```

## 📚 Alternativas (Se `tsx` não funcionar)

### Opção 1: Compilar primeiro e executar

```bash
npm run build
node dist/simulate/01_uniswap_compare.js
```

### Opção 2: Usar `node --loader` (Node.js 20+)

```json
"scripts": {
  "compare": "node --loader ts-node/esm src/simulate/01_uniswap_compare.ts"
}
```

Mas isso requer configurações extras no `tsconfig.json`.

## ✅ Vantagens do `tsx`

- ✅ Zero configuração para ESM
- ✅ Execução direta de `.ts` sem build
- ✅ Melhor performance
- ✅ Suporte completo a imports `.js` em arquivos `.ts`
- ✅ Mantido ativamente

## 🔧 Troubleshooting

### Se ainda der erro após instalar `tsx`:

1. Verifique se `tsx` foi instalado:
   ```bash
   npx tsx --version
   ```

2. Limpe `node_modules` e reinstale:
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

3. Verifique se o `package.json` tem `"type": "module"` (deve ter)

### Se preferir voltar para `ts-node`:

Configure o `tsconfig.json` assim:

```json
{
  "compilerOptions": { ... },
  "ts-node": {
    "esm": true,
    "experimentalSpecifierResolution": "node"
  }
}
```

E use nos scripts:
```json
"compare": "node --loader ts-node/esm src/simulate/01_uniswap_compare.ts"
```

Mas `tsx` é muito mais simples e recomendado! 🚀
