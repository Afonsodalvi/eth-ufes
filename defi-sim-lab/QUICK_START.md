# Quick Start

## 1. Instalação Rápida

```bash
# Instalar dependências
npm install

# Copiar e configurar .env
cp env.example .env
# Edite .env com suas credenciais Tenderly
```

## 2. Configuração Mínima do .env

```env
TENDERLY_ACCOUNT=SeuAccount
TENDERLY_PROJECT=SeuProject
TENDERLY_KEY=seu_access_key_aqui
FROM=0xSeuEnderecoEOA
VNET_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/seu-id
```

**Onde encontrar suas credenciais:**
- **TENDERLY_ACCOUNT** e **TENDERLY_PROJECT**: Nome da conta e projeto no Tenderly Dashboard
- **TENDERLY_KEY**: Settings > Authorization > Generate New Access Token
- **FROM**: Qualquer endereço EOA válido (pode ser vazio para bundles)
- **VNET_RPC**: Criar VirtualNet no Tenderly e copiar a URL do RPC

## 3. Executar Demonstrações

```bash
# Comparar Uniswap V2 vs V3
npm run compare

# Simular ataque de manipulação de spot (bundle)
npm run bundle:spot

# Demonstrar state override (DAI wards)
npm run override:ward

# Enviar swap real na VirtualNet
npm run vnet:swapv3
```

## 4. Primeira Execução

Execute `npm run compare` primeiro para validar sua configuração:

```bash
npm run compare
```

Se tudo estiver correto, você verá:
- Gas usado em V2 e V3
- Quantidade de DAI recebida
- Comparação de eficiência

## 5. Troubleshooting

**Erro: "Invalid account or project"**
- Verifique TENDERLY_ACCOUNT e TENDERLY_PROJECT no .env

**Erro: "Invalid access key"**
- Gere um novo token em Settings > Authorization

**Erro: "Missing FROM address"**
- Configure FROM no .env com um endereço EOA válido

**Erro ao executar na VirtualNet**
- Certifique-se de ter criado uma VirtualNet no Tenderly
- Use faucet/admin RPC para adicionar ETH se necessário

## Próximos Passos

- Leia `README.md` para entender a estrutura completa
- Explore `src/risk-demos/README.md` para receitas de demonstrações avançadas
- Personalize os scripts com seus próprios cenários
