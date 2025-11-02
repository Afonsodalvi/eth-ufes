/**
 * Helper para obter fees EIP-1559 adequados para simulações Tenderly
 */

import { createPublicClient, http, parseUnits } from 'viem';
import { mainnet } from 'viem/chains';
import { toDec } from './num.js';

// Cliente RPC público para obter base fee
const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com')
});

/**
 * Obtém maxFeePerGas e maxPriorityFeePerGas baseado no baseFee atual do bloco
 * @param blockNumber Opcional - se não fornecido, usa o bloco mais recente
 * @returns Object com maxFeePerGas e maxPriorityFeePerGas como strings decimais
 */
export async function getEip1559Fees(blockNumber?: bigint): Promise<{
  maxFeePerGas: string;
  maxPriorityFeePerGas: string;
  baseFee: bigint;
}> {
  try {
    const block = blockNumber 
      ? await publicClient.getBlock({ blockNumber })
      : await publicClient.getBlock({ blockTag: 'latest' });
    
    const baseFee = block.baseFeePerGas || parseUnits('20', 9); // fallback 20 gwei
    const maxPriorityFeePerGas = parseUnits('2', 9); // 2 gwei de prioridade
    const maxFeePerGas = baseFee + maxPriorityFeePerGas; // baseFee + prioridade
    
    return {
      maxFeePerGas: toDec(maxFeePerGas),
      maxPriorityFeePerGas: toDec(maxPriorityFeePerGas),
      baseFee
    };
  } catch (e) {
    // Fallback: usar valores conservadores
    const baseFee = parseUnits('20', 9); // 20 gwei
    const maxPriorityFeePerGas = parseUnits('2', 9); // 2 gwei
    const maxFeePerGas = baseFee + maxPriorityFeePerGas;
    
    return {
      maxFeePerGas: toDec(maxFeePerGas),
      maxPriorityFeePerGas: toDec(maxPriorityFeePerGas),
      baseFee
    };
  }
}

