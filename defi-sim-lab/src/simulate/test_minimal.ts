/**
 * Teste mínimo para verificar o que o SDK está enviando
 * 
 * Este teste faz uma transfer simples de ETH para verificar se a conexão básica funciona
 */

import 'dotenv/config';
import { tenderly } from '../tenderly.js';
import { getAddress, parseUnits, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { toDec } from '../util/num.js';

// Vitalik (checksummed)
const FROM = getAddress('0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045');

// Cliente RPC público para obter blockNumber atual
const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com') // RPC público
});

(async () => {
  try {
    console.log('🧪 Teste mínimo (SDK)…');
    console.log(`FROM: ${FROM}`);
    console.log(`Project: ${process.env.TENDERLY_PROJECT}`);
    console.log(`Account: ${process.env.TENDERLY_ACCOUNT}\n`);

    // Obter blockNumber atual
    const blockNumber = await publicClient.getBlockNumber();
    console.log(`📦 BlockNumber atual: ${blockNumber}\n`);

    const value = parseUnits('0.001', 18); // 0.001 ETH

    // SDK usa blockNumber (camelCase, número) e NÃO precisa de network_id
    // (a network já foi passada no constructor do Tenderly)
    const payload = {
      blockNumber: Number(blockNumber),     // número (não "latest", não string)
      simulation_type: 'full',              // "full" para erros mais verbosos
      save_if_fails: true,
      transaction: {
        from: FROM.toLowerCase(),           // lowercase evita validações chatas
        to: FROM.toLowerCase(),             // transferência para si
        gas: 21000,                         // number pequeno: ok
        gas_price: '0',                     // string decimal (ou 0)
        value: toDec(value),                // string decimal (não hex)
        input: '0x'
      },
      // opcional: dá saldo na simulação
      state_objects: {
        [FROM.toLowerCase()]: { 
          balance: toDec(parseUnits('100', 18)) // string decimal
        }
      }
    } as const;

    console.log('📦 Payload:', JSON.stringify(payload, null, 2));
    console.log('\n🚀 Enviando para Tenderly...\n');

    const res = await tenderly.simulator.simulateTransaction(payload);

    console.log('✅ OK:');
    console.log(JSON.stringify(res, null, 2));

  } catch (error: any) {
    console.error('❌ Erro:', error.message);
    
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    }
    
    if (error.data) {
      console.error('Error Data:', JSON.stringify(error.data, null, 2));
    }
    
    if (error.status) {
      console.error('Status:', error.status);
    }
    
    if (error.slug) {
      console.error('Slug:', error.slug);
    }

    process.exit(1);
  }
})();