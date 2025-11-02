import 'dotenv/config';
import { createPublicClient, http, createWalletClient } from 'viem';
import { mainnet } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// Use uma PK de teste (apenas VirtualNet - NUNCA use na mainnet!)
const TEST_PRIVATE_KEY = '0x5cb94f2b1b47125e0d10b2fc563211f3cc7cb17992ec9ac3edb27f7cc100f755' as const;

export const account = privateKeyToAccount(TEST_PRIVATE_KEY);

export const vnetPublic = createPublicClient({
  chain: mainnet,
  transport: http(process.env.VNET_RPC!)
});

export const vnetWallet = createWalletClient({
  chain: mainnet,
  transport: http(process.env.VNET_RPC!),
  account
});
