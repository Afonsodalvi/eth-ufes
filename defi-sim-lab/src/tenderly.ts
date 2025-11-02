import 'dotenv/config';
import { Tenderly, Network } from '@tenderly/sdk';

// Validação das variáveis de ambiente
const TENDERLY_ACCOUNT = process.env.TENDERLY_ACCOUNT;
const TENDERLY_PROJECT = process.env.TENDERLY_PROJECT;
const TENDERLY_KEY = process.env.TENDERLY_KEY;

if (!TENDERLY_ACCOUNT || !TENDERLY_PROJECT || !TENDERLY_KEY) {
  console.error('❌ Erro: Variáveis de ambiente do Tenderly não configuradas!');
  console.error('   Configure no arquivo .env:');
  console.error('   - TENDERLY_ACCOUNT: Nome da conta ou organização (slug)');
  console.error('   - TENDERLY_PROJECT: Slug do projeto (não o nome!)');
  console.error('   - TENDERLY_KEY: Access Token gerado no Tenderly Dashboard');
  console.error('\n   Guia: https://docs.tenderly.co/tenderly-sdk/intro-to-tenderly-sdk#how-to-get-the-account-name-project-slug-and-secret-key');
  process.exit(1);
}

// Inicializa o cliente Tenderly com network configurado
// Conforme documentação: https://docs.tenderly.co/tenderly-sdk/intro-to-tenderly-sdk
export const tenderly = new Tenderly({
  accountName: TENDERLY_ACCOUNT,      // Nome da conta ou organização (slug)
  projectName: TENDERLY_PROJECT,      // Slug do projeto (importante: é o slug, não o nome!)
  accessKey: TENDERLY_KEY,            // Access Token gerado em Account Settings > Access Tokens
  network: Network.MAINNET,           // Ethereum Mainnet - obrigatório!
});

// Helper para padronizar simulações - network_id como string
export const TND_NET_ID = '1'; // mainnet como string (algumas versões do SDK são sensíveis)

// Log de confirmação (apenas em modo debug)
if (process.env.DEBUG === 'true') {
  console.log('✅ Cliente Tenderly inicializado:');
  console.log(`   Account: ${TENDERLY_ACCOUNT}`);
  console.log(`   Project: ${TENDERLY_PROJECT}`);
  console.log(`   Network: MAINNET (1)`);
}

// Exporta MAINNET para usar nos scripts (chainId "1")
export const MAINNET = Network.MAINNET;
