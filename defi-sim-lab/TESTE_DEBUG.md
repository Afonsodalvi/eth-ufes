# Teste com Debug Ativado

Para diagnosticar o erro "Internal server error", execute com debug ativado:

```bash
DEBUG=true npm run compare
```

## O que será mostrado:

1. ✅ **Configuração do cliente Tenderly**
   - Account name
   - Project name
   - Network

2. ✅ **Payload completo enviado**
   - Estrutura exata da simulação
   - Todos os parâmetros da transação

3. ✅ **Erro completo**
   - Todas as propriedades do erro
   - Response status
   - Response data
   - Body do erro
   - Slug e ID do erro (se disponíveis)

## Copie e envie:

1. A saída completa do comando `DEBUG=true npm run compare`
2. Especialmente a seção "🔍 Todas as propriedades do erro"
3. A seção "📦 Objeto de simulação enviado"

Isso nos ajudará a identificar exatamente o que está causando o "Internal server error".
