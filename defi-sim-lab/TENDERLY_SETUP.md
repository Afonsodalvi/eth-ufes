# Configuração do Tenderly SDK

## 📋 Variáveis de Ambiente Necessárias

Conforme a [documentação oficial do Tenderly SDK](https://docs.tenderly.co/tenderly-sdk/intro-to-tenderly-sdk#how-to-get-the-account-name-project-slug-and-secret-key), você precisa configurar:

### 1. TENDERLY_ACCOUNT

**O que é:** Nome da sua conta pessoal ou organização no Tenderly (slug)

**Como obter:**
- Se for conta pessoal: É o username da sua conta
- Se for organização: É o slug da organização
- Pode ser encontrado na URL: `https://dashboard.tenderly.co/[ACCOUNT_NAME]/[PROJECT_NAME]`

**Exemplo:**
```env
TENDERLY_ACCOUNT=my-account-name
```

### 2. TENDERLY_PROJECT

**O que é:** Slug do projeto (⚠️ IMPORTANTE: é o slug, não o nome!)

**Como obter:**
- Acesse seu projeto no Tenderly Dashboard
- O slug é o identificador na URL: `https://dashboard.tenderly.co/[ACCOUNT]/[PROJECT_SLUG]`
- Pode ser diferente do nome do projeto que você vê na interface

**Exemplo:**
```env
TENDERLY_PROJECT=my-project-slug
```

⚠️ **ATENÇÃO:** Se o nome do projeto for "My Project", o slug pode ser "my-project" ou algo completamente diferente. Verifique na URL do dashboard!

### 3. TENDERLY_KEY

**O que é:** Access Token (chave de API)

**Como gerar:**
1. Acesse: [Account Settings > Access Tokens](https://docs.tenderly.co/account/projects/how-to-generate-api-access-token)
2. Para conta pessoal:
   - Clique na sua foto de perfil
   - Vá em **Account Settings** > **Access Tokens**
   - Clique em **Generate Access Token**
3. Para organização:
   - Selecione a organização no dropdown
   - Vá em **Access Tokens**
   - Clique em **New Access Token**

**⚠️ IMPORTANTE:** O token é mostrado apenas uma vez! Copie e guarde com segurança.

**Exemplo:**
```env
TENDERLY_KEY=tn_xxxxxxxxxxxxxxxxxxxxx
```

## 📝 Exemplo de .env Completo

```env
# Tenderly Configuration
TENDERLY_ACCOUNT=my-account-name
TENDERLY_PROJECT=my-project-slug
TENDERLY_KEY=tn_xxxxxxxxxxxxxxxxxxxxx

# EOA for simulations (opcional - usa padrão se não especificado)
FROM=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045

# VirtualNet RPC (opcional - para testes na VirtualNet)
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id
```

## ✅ Como Verificar se Está Correto

### Passo 1: Verifique os valores no Dashboard

1. Acesse https://dashboard.tenderly.co
2. Selecione seu projeto
3. Veja a URL no navegador: `https://dashboard.tenderly.co/[ACCOUNT_NAME]/[PROJECT_SLUG]`
4. Use exatamente esses valores no `.env`

### Passo 2: Teste a Configuração

Execute:
```bash
npm run compare
```

Se ainda der erro "Internal server error", verifique:
- ✅ O `TENDERLY_PROJECT` é o slug (da URL), não o nome
- ✅ O `TENDERLY_KEY` está completo e correto (começa com `tn_`)
- ✅ O `TENDERLY_ACCOUNT` corresponde ao nome da conta/organização na URL

## 🔍 Troubleshooting

### Erro: "Missing network"
✅ **Resolvido:** O código já inclui `network: Network.MAINNET` na configuração

### Erro: "Invalid account or project"
❌ **Causa:** `TENDERLY_ACCOUNT` ou `TENDERLY_PROJECT` incorretos
✅ **Solução:** Verifique na URL do dashboard e use exatamente o que aparece

### Erro: "Invalid access key"
❌ **Causa:** `TENDERLY_KEY` incorreto ou expirado
✅ **Solução:** Gere um novo token em Account Settings > Access Tokens

### Erro: "Internal server error"
❌ **Possíveis causas:**
1. `TENDERLY_PROJECT` está usando o nome do projeto ao invés do slug
2. O projeto não existe ou você não tem acesso
3. O token não tem permissões suficientes

✅ **Solução:**
- Verifique se está usando o **slug** do projeto (da URL)
- Verifique se tem acesso ao projeto no dashboard
- Gere um novo token com todas as permissões

## 📚 Referências

- [Intro to Tenderly SDK](https://docs.tenderly.co/tenderly-sdk/intro-to-tenderly-sdk)
- [How to get account name, project slug, and secret key](https://docs.tenderly.co/tenderly-sdk/intro-to-tenderly-sdk#how-to-get-the-account-name-project-slug-and-secret-key)
- [How to generate API access token](https://docs.tenderly.co/account/projects/how-to-generate-api-access-token)
