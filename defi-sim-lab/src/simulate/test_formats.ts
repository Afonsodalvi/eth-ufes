/**
 * Teste simplificado para encontrar o formato correto da simulação
 * Vamos testar diferentes abordagens até encontrar uma que funcione
 */

import 'dotenv/config';
import { tenderly } from '../tenderly.js';
import { getAddress, parseUnits, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { toDec } from '../util/num.js';
import { getGasPriceString } from '../util/gas.js';
import { UNISWAP_V2_ROUTER, WETH, DAI, DEFAULT_FROM } from '../constants.js';
import { encodeFunctionData } from 'viem';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';

const FROM = getAddress(DEFAULT_FROM); // Vitalik - sempre funciona

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com')
});

async function testSimulation(approach: string, payload: any) {
  console.log(`\n🧪 Testando: ${approach}`);
  console.log('📦 Payload:', JSON.stringify(payload, null, 2));
  
  try {
    const res = await tenderly.simulator.simulateTransaction(payload);
    console.log(`✅ ${approach} FUNCIONOU!`);
    console.log('📋 Resposta:', JSON.stringify(res, null, 2).substring(0, 500));
    return { success: true, res };
  } catch (error: any) {
    console.log(`❌ ${approach} falhou:`, error.message);
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', JSON.stringify(error.response.data, null, 2).substring(0, 300));
    }
    return { success: false, error };
  }
}

(async () => {
  console.log('🔍 Testando diferentes formatos de simulação...\n');
  
  const [blockNumber, gasPriceStr] = await Promise.all([
    publicClient.getBlockNumber(),
    getGasPriceString()
  ]);
  const blockNumberNum = Math.max(Number(blockNumber) - 100, 1); // Usar bloco mais antigo
  
  console.log(`BlockNumber: ${blockNumber} → usando ${blockNumberNum} (100 blocos atrás)`);
  console.log(`Gas Price: ${gasPriceStr} wei\n`);

  const amountIn = parseUnits('0.01', 18);
  const deadline = BigInt(Math.floor(Date.now()/1000) + 900);
  
  const input = encodeFunctionData({
    abi: UNISWAP_V2_ROUTER_ABI,
    functionName: 'swapExactETHForTokens',
    args: [0n, [WETH, DAI], FROM, deadline]
  });

  const amountInStr = toDec(amountIn);
  
  // Teste 1: Formato atual (com gas_price como string decimal)
  await testSimulation('1. Formato atual (gas_price string)', {
    blockNumber: blockNumberNum,
    simulation_type: 'full',
    save_if_fails: true,
    transaction: {
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      gas_price: gasPriceStr,
      value: amountInStr,
      input
    },
    state_objects: {
      [FROM.toLowerCase()]: { 
        balance: toDec(parseUnits('100', 18))
      }
    }
  });

  // Teste 2: Sem gas_price (deixar Tenderly calcular)
  await testSimulation('2. Sem gas_price', {
    blockNumber: blockNumberNum,
    simulation_type: 'full',
    save_if_fails: true,
    transaction: {
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      value: amountInStr,
      input
    },
    state_objects: {
      [FROM.toLowerCase()]: { 
        balance: toDec(parseUnits('100', 18))
      }
    }
  });

  // Teste 3: gas_price como número (não string)
  await testSimulation('3. gas_price como número', {
    blockNumber: blockNumberNum,
    simulation_type: 'full',
    save_if_fails: true,
    transaction: {
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      gas_price: Number(gasPriceStr),
      value: amountInStr,
      input
    },
    state_objects: {
      [FROM.toLowerCase()]: { 
        balance: toDec(parseUnits('100', 18))
      }
    }
  });

  // Teste 4: Usar "latest" ao invés de número
  await testSimulation('4. blockNumber "latest"', {
    blockNumber: 'latest',
    simulation_type: 'full',
    save_if_fails: true,
    transaction: {
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      gas_price: gasPriceStr,
      value: amountInStr,
      input
    },
    state_objects: {
      [FROM.toLowerCase()]: { 
        balance: toDec(parseUnits('100', 18))
      }
    }
  });

  // Teste 5: Formato mais simples possível
  await testSimulation('5. Formato mínimo', {
    blockNumber: blockNumberNum,
    transaction: {
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      value: amountInStr,
      input
    }
  });

  console.log('\n✅ Testes concluídos!');
})();

