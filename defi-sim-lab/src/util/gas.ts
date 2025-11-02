/**
 * Helper para obter gas_price adequado para simulações Tenderly
 */

import { createPublicClient, http, parseUnits } from 'viem';
import { mainnet } from 'viem/chains';

// Cliente RPC público para obter gas price
const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com')
});

/**
 * Obtém o gas price atual da rede, com fallback para 1 gwei
 * @returns Gas price em wei (BigInt)
 */
export async function getGasPrice(): Promise<bigint> {
  try {
    // Usar getGasPrice ou tentar obter do último bloco
    const gasPrice = await publicClient.getGasPrice();
    return gasPrice;
  } catch (e) {
    // Fallback: 1 gwei = 1_000_000_000 wei
    return parseUnits('1', 9);
  }
}

/**
 * Obtém gas price como string decimal (para uso em payloads Tenderly)
 * @returns Gas price como string decimal
 */
export async function getGasPriceString(): Promise<string> {
  const gasPrice = await getGasPrice();
  return gasPrice.toString();
}

