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
import { getGasPriceString } from '../util/gas.js';

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

    // Obter blockNumber atual e gas price
    const [blockNumber, gasPriceStr] = await Promise.all([
      publicClient.getBlockNumber(),
      getGasPriceString()
    ]);
    console.log(`📦 BlockNumber atual: ${blockNumber}`);
    console.log(`⛽ Gas price: ${gasPriceStr} wei\n`);

    const value = parseUnits('0.001', 18); // 0.001 ETH
    
    // Usar um endereço diferente para o destinatário (0x0000...0001 é um endereço válido)
    // Self-transfers podem ter comportamento diferente em simulações
    const TO = getAddress('0x0000000000000000000000000000000000000001');
    
    // SDK usa blockNumber (camelCase, número) e NÃO precisa de network_id
    // (a network já foi passada no constructor do Tenderly)
    const payload = {
      blockNumber: Number(blockNumber),     // número (não "latest", não string)
      simulation_type: 'full',              // "full" para erros mais verbosos
      save: true,                            // Salva sempre no dashboard
      save_if_fails: true,                   // Também salva se falhar
      transaction: {
        from: FROM.toLowerCase(),           // lowercase evita validações chatas
        to: TO.toLowerCase(),                // transferência para endereço diferente
        gas: 23000,                          // gas um pouco maior para segurança
        gas_price: gasPriceStr,             // gas price obtido dinamicamente
        value: toDec(value),                 // string decimal (não hex)
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
    
    if (!res) {
      throw new Error('Resposta vazia do Tenderly');
    }

    // Verificar se a transação foi executada com sucesso
    const hasError = res.trace?.some((t: any) => t.error) || (res as any).transaction?.error;
    const status = (res as any).transaction?.status ?? res.status;
    
    // Mostrar ID da simulação se foi salva
    const simId = (res as any).simulation?.id || (res as any).id;
    if (simId) {
      const account = process.env.TENDERLY_ACCOUNT!;
      const project = process.env.TENDERLY_PROJECT!;
      const dashboardUrl = `https://dashboard.tenderly.co/${account}/${project}/simulator/${simId}`;
      console.log(`\n📊 Simulação salva no dashboard: ${dashboardUrl}`);
    }
    
    if (hasError) {
      console.log('❌ ERRO na simulação:');
    } else {
      console.log('✅ Simulação executada com sucesso!');
      console.log(`   Status da transação: ${status ? '✅ Sucesso' : '⚠️  Status false (pode ser normal para transfers simples)'}`);
      console.log(`   Gas usado: ${(res as any).transaction?.gas_used || res.gasUsed || 'N/A'}`);
    }
    
    console.log('\n📋 Detalhes completos:');
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