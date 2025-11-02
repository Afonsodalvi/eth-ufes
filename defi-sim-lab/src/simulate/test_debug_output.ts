/**
 * Teste direto para verificar o que o Tenderly retorna
 */

import 'dotenv/config';
import axios from 'axios';
import { encodeFunctionData, decodeFunctionResult, parseUnits, getAddress, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { toDec } from '../util/num.js';
import { getEip1559Fees } from '../util/eip1559.js';
import { UNISWAP_V2_ROUTER, WETH, DAI, DEFAULT_FROM } from '../constants.js';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';

const ACCOUNT = process.env.TENDERLY_ACCOUNT!;
const PROJECT = process.env.TENDERLY_PROJECT!;
const KEY = process.env.TENDERLY_KEY!;

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com')
});

const FROM = getAddress(DEFAULT_FROM);
const amountIn = parseUnits('0.01', 18);
const deadline = BigInt(Math.floor(Date.now()/1000) + 900);

(async () => {
  try {
    const input = encodeFunctionData({
      abi: UNISWAP_V2_ROUTER_ABI,
      functionName: 'swapExactETHForTokens',
      args: [0n, [WETH, DAI], FROM, deadline]
    });

    const blockNumber = await publicClient.getBlockNumber();
    const fees = await getEip1559Fees(blockNumber);
    
    const url = `https://api.tenderly.co/api/v1/account/${ACCOUNT}/project/${PROJECT}/simulate`;
    
    const body = {
      network_id: '1',
      block_number: Number(blockNumber),
      simulation_type: 'full',
      save_if_fails: true,
      from: FROM.toLowerCase(),
      to: UNISWAP_V2_ROUTER.toLowerCase(),
      gas: 2_500_000,
      maxFeePerGas: fees.maxFeePerGas,
      maxPriorityFeePerGas: fees.maxPriorityFeePerGas,
      value: toDec(amountIn),
      input,
      state_objects: {
        [FROM.toLowerCase()]: { 
          balance: toDec(parseUnits('100', 18))
        }
      }
    };

    const { data } = await axios.post(url, body, {
      headers: { 
        'X-Access-Key': KEY,
        'Content-Type': 'application/json' 
      }
    });

    console.log('📋 Resposta completa do Tenderly:\n');
    console.log('1. transaction.output:', data.transaction?.output);
    console.log('2. simulation.transaction.output:', data.simulation?.transaction?.output);
    console.log('\n3. asset_changes:', JSON.stringify(data.simulation?.asset_changes || [], null, 2));
    console.log('\n4. Gas usado:', data.transaction?.gas_used || data.simulation?.transaction?.gas_used);
    
    // Tentar decodificar output
    const output = data.transaction?.output || data.simulation?.transaction?.output;
    if (output && output !== '0x' && output !== '0x0') {
      try {
        const decoded = decodeFunctionResult({
          abi: UNISWAP_V2_ROUTER_ABI,
          functionName: 'swapExactETHForTokens',
          data: output as `0x${string}`
        });
        console.log('\n5. Decodificado:', decoded);
        if (Array.isArray(decoded)) {
          console.log('   amounts[0] (WETH):', decoded[0]?.toString());
          console.log('   amounts[1] (DAI):', decoded[1]?.toString());
        }
      } catch (e) {
        console.log('\n5. Erro ao decodificar:', e);
      }
    }
    
  } catch (error: any) {
    console.error('❌ Erro:', error.message);
    if (error.response) {
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    }
  }
})();

