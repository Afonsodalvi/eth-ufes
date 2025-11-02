/**
 * Teste usando API REST diretamente - pode funcionar melhor que o SDK
 */

import 'dotenv/config';
import axios from 'axios';
import { encodeFunctionData, parseUnits, getAddress, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { UNISWAP_V2_ROUTER, WETH, DAI, DEFAULT_FROM } from '../constants.js';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';
import { toDec } from '../util/num.js';
import { getGasPriceString } from '../util/gas.js';

const FROM = getAddress(DEFAULT_FROM);
const ACCOUNT = process.env.TENDERLY_ACCOUNT!;
const PROJECT = process.env.TENDERLY_PROJECT!;
const KEY = process.env.TENDERLY_KEY!;

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com')
});

(async () => {
  try {
    console.log('🧪 Teste via API REST direta\n');
    
    const blockNumber = await publicClient.getBlockNumber();
    const block = await publicClient.getBlock({ blockNumber });
    const blockNumberNum = Number(blockNumber);
    
    // Obter baseFee do bloco e calcular maxFeePerGas adequado
    const baseFee = block.baseFeePerGas || parseUnits('20', 9); // fallback 20 gwei
    const maxPriorityFeePerGas = parseUnits('2', 9); // 2 gwei de prioridade
    const maxFeePerGas = baseFee + maxPriorityFeePerGas; // baseFee + prioridade
    
    console.log(`BlockNumber: ${blockNumber}`);
    console.log(`Base Fee: ${baseFee.toString()} wei`);
    console.log(`Max Fee Per Gas: ${maxFeePerGas.toString()} wei`);
    console.log(`Max Priority Fee: ${maxPriorityFeePerGas.toString()} wei\n`);

    const value = parseUnits('0.01', 18);
    const deadline = BigInt(Math.floor(Date.now()/1000) + 900);

    const input = encodeFunctionData({
      abi: UNISWAP_V2_ROUTER_ABI,
      functionName: 'swapExactETHForTokens',
      args: [0n, [WETH, DAI], FROM, deadline]
    });

    const url = `https://api.tenderly.co/api/v1/account/${ACCOUNT}/project/${PROJECT}/simulate`;

    // Usar maxFeePerGas e maxPriorityFeePerGas (EIP-1559) ao invés de gas_price
    const body = {
      network_id: '1',
      block_number: blockNumberNum,
      simulation_type: 'full',
      save_if_fails: true,
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      maxFeePerGas: toDec(maxFeePerGas), // usar maxFeePerGas ao invés de gas_price
      maxPriorityFeePerGas: toDec(maxPriorityFeePerGas),
      value: toDec(value),
      input,
      state_objects: {
        [FROM.toLowerCase()]: { 
          balance: toDec(parseUnits('100', 18))
        }
      }
    };

    console.log('📦 Enviando payload...');
    console.log(`URL: ${url}`);
    console.log(`From: ${FROM}\n`);

    const { data } = await axios.post(url, body, {
      headers: { 
        'X-Access-Key': KEY,
        'Content-Type': 'application/json' 
      }
    });

    console.log('✅ SUCESSO!');
    console.log('📋 Resposta:', JSON.stringify(data, null, 2).substring(0, 1000));

    if (data.simulation) {
      const gasUsed = data.simulation.transaction?.gas_used;
      const assetChanges = data.simulation.asset_changes || [];
      
      console.log('\n📊 Resumo:');
      console.log(`  Gas usado: ${gasUsed || 'N/A'}`);
      
      if (assetChanges.length > 0) {
        console.log('\n  Mudanças de Assets:');
        assetChanges.forEach((change: any) => {
          console.log(`    ${change.asset?.symbol || 'Token'}: ${change.delta || '0'}`);
        });
      }
    }

  } catch (error: any) {
    console.error('❌ Erro:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('Erro completo:', error);
    }
    process.exit(1);
  }
})();

