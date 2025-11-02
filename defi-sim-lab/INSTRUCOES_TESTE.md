# Instruções de Teste - Passo a Passo

## 1. Teste Mínimo (Recomendado Primeiro)

Este teste verifica se a conexão básica com Tenderly funciona:

```bash
npm run test:minimal
```

**O que esperar**:
- ✅ Se funcionar: Você verá "✅ Sucesso!" com a resposta da simulação
- ❌ Se falhar: Verá o erro detalhado e o payload que foi enviado

**Se o teste mínimo funcionar**: A configuração está correta, o problema está no payload específico do Uniswap.

## 2. Teste Via REST (Sem SDK)

Este teste bypass o SDK e chama a API diretamente:

```bash
npm run compare:raw
```

**O que esperar**:
- ✅ Se funcionar: Você verá o JSON completo da simulação
- ❌ Se falhar: Verá o erro detalhado (400, 401, 403, 404, 500)

**Por que usar**: Se este funcionar mas o SDK não, o problema está no SDK.

## 3. Teste Principal (SDK)

Este é o teste completo que você precisa:

```bash
npm run compare
```

**O que esperar**:
- ✅ Se funcionar: Comparação entre V2 e V3 com gas usado e DAI recebido
- ❌ Se falhar: Verá o erro detalhado

## Possíveis Erros e Soluções

### Erro 400 "From address not valid"
- **Solução**: O código agora usa automaticamente o endereço do Vitalik se o do .env causar problemas
- **Verifique**: O endereço no .env está correto?

### Erro 401/403 "Unauthorized"
- **Solução**: Gere um novo token em Account Settings > Access Tokens
- **Verifique**: O TENDERLY_KEY está correto?

### Erro 404 "Not Found"
- **Solução**: Verifique se o projeto existe e o slug está correto
- **Verifique**: Acesse https://dashboard.tenderly.co/Omnes/ufes/ e veja se funciona

### Erro 500 "Internal server error"
- **Solução**: Pode ser bug do SDK ou problema temporário do Tenderly
- **Alternativa**: Use `npm run compare:raw` (API REST direta)

## Verificação Final

Se todos os testes falharem, verifique:

1. ✅ Você consegue acessar o projeto no dashboard?
   - URL: https://dashboard.tenderly.co/Omnes/ufes/

2. ✅ O token tem permissões corretas?
   - Gere novo token em: Account Settings > Access Tokens
   - Certifique-se de que tem permissões de "Simulate"

3. ✅ O plano do Tenderly permite simulações?
   - Planos gratuitos podem ter limitações

## Contato

Se nada funcionar após seguir todos os passos, o problema pode ser:
- Limitação do plano Tenderly
- Bug na versão do SDK
- Problema temporário da API

Nesse caso, use a API REST diretamente no repositório didático.
