import 'dotenv/config';
import { createPublicClient, http, createWalletClient, Hex, defineChain } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

// Validação das variáveis de ambiente necessárias para VirtualNet
const TENDERLY_PRIVATE_KEY = process.env.TENDERLY_PRIVATE_KEY;
const VNET_RPC = process.env.VNET_RPC;

if (!TENDERLY_PRIVATE_KEY || !VNET_RPC) {
  console.error('❌ Erro: Variáveis de ambiente para VirtualNet não configuradas!');
  console.error('   Configure no arquivo .env:');
  console.error('   - TENDERLY_PRIVATE_KEY: Private Key para VirtualNet (chave de TESTE apenas!)');
  console.error('   - VNET_RPC: URL da sua VirtualNet do Tenderly');
  console.error('');
  console.error('   ⚠️  IMPORTANTE: Use uma chave privada de TESTE que NÃO tenha fundos na mainnet real!');
  console.error('   Como gerar uma chave de teste:');
  console.error('   1. Use MetaMask para criar uma nova conta de teste');
  console.error('   2. Exporte a private key (Settings > Security & Privacy > Show Private Key)');
  console.error('   3. VERIFIQUE que esta chave NÃO tem fundos na mainnet antes de usar!');
  process.exit(1);
}

// Validar formato da chave privada (deve começar com 0x e ter 66 caracteres)
if (!TENDERLY_PRIVATE_KEY.startsWith('0x') || TENDERLY_PRIVATE_KEY.length !== 66) {
  console.error('❌ Erro: Formato inválido de TENDERLY_PRIVATE_KEY!');
  console.error('   A chave privada deve:');
  console.error('   - Começar com 0x');
  console.error('   - Ter exatamente 66 caracteres (0x + 64 caracteres hexadecimais)');
  console.error(`   Formato recebido: ${TENDERLY_PRIVATE_KEY.substring(0, 10)}... (${TENDERLY_PRIVATE_KEY.length} caracteres)`);
  process.exit(1);
}

// Extrair o ID do VirtualNet da URL
// Exemplo: https://virtual.mainnet.eu.rpc.tenderly.co/54e15302-bb51-4ea2-b124-540392e84dad
const vnetId = VNET_RPC.split('/').pop() || '';

if (!vnetId || vnetId.length < 10) {
  console.error('❌ Erro: URL da VirtualNet inválida!');
  console.error(`   VNET_RPC fornecido: ${VNET_RPC}`);
  console.error('   A URL deve ter o formato: https://virtual.mainnet.eu.rpc.tenderly.co/SEU-ID');
  process.exit(1);
}

// Configurar o Virtual Testnet conforme documentação do Tenderly
export const virtual_mainnet = defineChain({
  id: 1,
  name: 'Virtual Mainnet',
  nativeCurrency: { name: 'VETH', symbol: 'vETH', decimals: 18 },
  rpcUrls: {
    default: { http: [VNET_RPC] }
  },
  blockExplorers: {
    default: {
      name: 'Tenderly Explorer',
      url: `https://virtual.mainnet.eu.rpc.tenderly.co/${vnetId}`
    }
  },
});

// Tipos para os RPC methods do Tenderly Virtual Testnet
export type TSetBalanceRpc = {
  method: "tenderly_setBalance",
  Parameters: [addresses: Hex[], value: Hex],
  ReturnType: Hex
}

export type TSetErc20BalanceRpc = {
  method: "tenderly_setErc20Balance",
  Parameters: [erc20: Hex, to: Hex, value: Hex],
  ReturnType: Hex
}

// Converter chave privada para conta (com validação adicional)
let account;
try {
  account = privateKeyToAccount(TENDERLY_PRIVATE_KEY as `0x${string}`);
  // Validação silenciosa - só mostra aviso se DEBUG estiver ativo
  if (process.env.DEBUG === 'true') {
    const address = account.address;
    console.log(`   🔍 Debug - Endereço da conta: ${address}`);
    console.log(`   ⚠️  Certifique-se de que esta chave NÃO tem fundos na mainnet real!`);
  }
} catch (error: any) {
  console.error('❌ Erro ao criar conta a partir da chave privada:');
  console.error(`   ${error.message}`);
  console.error('   Verifique se TENDERLY_PRIVATE_KEY está no formato correto (0x + 64 hex chars)');
  console.error('');
  console.error('   Exemplo de formato correto:');
  console.error('   TENDERLY_PRIVATE_KEY=0x5c....');
  process.exit(1);
}

export { account };

export const vnetPublic = createPublicClient({
  chain: virtual_mainnet,
  transport: http(VNET_RPC)
});

export const vnetWallet = createWalletClient({
  chain: virtual_mainnet,
  transport: http(VNET_RPC),
  account
});

/**
 * Funda uma ou mais contas no Virtual Testnet usando tenderly_setBalance
 * @param addresses Array de endereços para fundar
 * @param value Valor em wei (hex string, ex: "0xDE0B6B3A7640000" = 1 ETH)
 */
export async function fundAccounts(addresses: Hex[], value: Hex): Promise<Hex> {
  return await vnetPublic.request<TSetBalanceRpc>({
    method: "tenderly_setBalance",
    params: [addresses, value],
  });
}

/**
 * Funda uma conta com ERC20 no Virtual Testnet
 * @param erc20 Endereço do contrato ERC20
 * @param to Endereço que receberá os tokens
 * @param value Quantidade em wei (hex string)
 */
export async function fundErc20(erc20: Hex, to: Hex, value: Hex): Promise<Hex> {
  return await vnetPublic.request<TSetErc20BalanceRpc>({
    method: "tenderly_setErc20Balance",
    params: [erc20, to, value],
  });
}
