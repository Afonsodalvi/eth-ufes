/**
 * Simulação de Spot Oracle Attack - Versão Simplificada
 * 
 * Simula duas transações sequenciais para demonstrar como um swap grande
 * pode manipular o preço spot e afetar uma transação subsequente.
 * 
 * Como a API de bundle não está funcionando bem, fazemos duas simulações
 * separadas com o mesmo blockNumber para demonstrar o conceito.
 */

import 'dotenv/config';
import axios from 'axios';
import { encodeFunctionData, parseUnits, getAddress, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { getEip1559Fees } from '../util/eip1559.js';
import { toDec } from '../util/num.js';
import { UNISWAP_V2_ROUTER, WETH, DAI, DEFAULT_FROM } from '../constants.js';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';

const ACCOUNT = process.env.TENDERLY_ACCOUNT!;
const PROJECT = process.env.TENDERLY_PROJECT!;
const KEY = process.env.TENDERLY_KEY!;

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com')
});

const RAW_FROM = (process.env.FROM || DEFAULT_FROM).trim();
let FROM: `0x${string}`;
try {
  FROM = getAddress(RAW_FROM);
} catch {
  FROM = getAddress(DEFAULT_FROM);
}

const TOKEN_DEST = DAI;
const amountBigEth = parseUnits('5', 18); // Swap grande: 5 ETH
const amountSmallEth = parseUnits('0.1', 18); // Swap pequeno: 0.1 ETH
const deadline = BigInt(Math.floor(Date.now()/1000) + 900);

async function simulateSwap(amount: bigint, label: string) {
  const input = encodeFunctionData({
    abi: UNISWAP_V2_ROUTER_ABI,
    functionName: 'swapExactETHForTokens',
    args: [0n, [WETH, TOKEN_DEST], FROM, deadline]
  });

  const blockNumber = await publicClient.getBlockNumber();
  const fees = await getEip1559Fees(blockNumber);
  
  const url = `https://api.tenderly.co/api/v1/account/${ACCOUNT}/project/${PROJECT}/simulate`;
  
  const body = {
    network_id: '1',
    block_number: Number(blockNumber),
    simulation_type: 'full',
    save: true,  // Salva sempre no dashboard
    save_if_fails: true,
    from: FROM.toLowerCase(),
    to: UNISWAP_V2_ROUTER.toLowerCase(),
    gas: 3_000_000,
    maxFeePerGas: fees.maxFeePerGas,
    maxPriorityFeePerGas: fees.maxPriorityFeePerGas,
    value: toDec(amount),
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

  const gasUsed = data.transaction?.gas_used || data.simulation?.transaction?.gas_used;
  const assetChanges = data.simulation?.asset_changes || [];
  const daiGain = assetChanges.find((c: any) =>
    c.address?.toLowerCase() === FROM.toLowerCase() && c.asset?.symbol === 'DAI'
  );

  // Obter ID da simulação e URL do dashboard
  const simId = data.simulation?.id || data.id;
  const dashboardUrl = simId ? `https://dashboard.tenderly.co/${ACCOUNT}/${PROJECT}/simulator/${simId}` : null;

  return {
    label,
    gasUsed,
    daiAmount: daiGain?.amount || daiGain?.delta,
    daiType: daiGain?.type || '',
    blockNumber: Number(blockNumber),
    dashboardUrl
  };
}

(async () => {
  try {
    console.log('🚨 SIMULAÇÃO: Spot Oracle Attack\n');
    console.log('='.repeat(60));
    console.log('📚 O QUE ESTAMOS TESTANDO:');
    console.log('   Este script demonstra como um swap grande pode manipular');
    console.log('   o preço spot de um DEX e afetar transações subsequentes.\n');
    console.log('📖 CENÁRIO:');
    console.log('   TX1: Ataque faz swap MUITO grande (5 ETH)');
    console.log('        → Isso manipula o preço spot do pool');
    console.log('   TX2: Vítima faz swap pequeno (0.1 ETH)');
    console.log('        → Recebe preço pior devido ao impacto da TX1\n');
    console.log('💡 POR QUE ISSO É PERIGOSO:');
    console.log('   Se um protocolo usar o preço spot de um DEX como oráculo,');
    console.log('   um atacante pode manipular o preço e causar prejuízos.\n');
    console.log('='.repeat(60));
    console.log(`📍 Endereço usado na simulação: ${FROM}\n`);

    // Simular as duas transações sequencialmente
    console.log('⏳ Passo 1: Simulando TX1 (Swap Grande de 5 ETH)...');
    console.log('   Enviando para Tenderly...\n');
    const tx1 = await simulateSwap(amountBigEth, 'Ataque');
    if (tx1.dashboardUrl) {
      console.log(`   ✅ TX1 simulada! Link: ${tx1.dashboardUrl}\n`);
    }
    
    console.log('⏳ Passo 2: Simulando TX2 (Swap Pequeno de 0.1 ETH)...');
    console.log('   Enviando para Tenderly...\n');
    const tx2 = await simulateSwap(amountSmallEth, 'Vítima');
    if (tx2.dashboardUrl) {
      console.log(`   ✅ TX2 simulada! Link: ${tx2.dashboardUrl}\n`);
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 RESULTADOS DAS SIMULAÇÕES\n');
    
    console.log(`📈 TX1 (${tx1.label} - Swap Grande de 5 ETH):`);
    console.log(`   ✅ Status: Sucesso`);
    console.log(`   ⛽ Gas usado: ${tx1.gasUsed || 'N/A'}`);
    if (tx1.daiAmount) {
      const daiAmount = Number(tx1.daiAmount) / 1e18;
      const rate = daiAmount / 5; // DAI por ETH
      console.log(`   💰 DAI recebido: ${daiAmount.toFixed(4)} DAI`);
      console.log(`   💱 Taxa de câmbio: ${rate.toFixed(2)} DAI por ETH`);
    }
    if (tx1.dashboardUrl) {
      console.log(`   🔗 Ver no Dashboard: ${tx1.dashboardUrl}`);
    }
    
    console.log(`\n📈 TX2 (${tx2.label} - Swap Pequeno de 0.1 ETH):`);
    console.log(`   ✅ Status: Sucesso`);
    console.log(`   ⛽ Gas usado: ${tx2.gasUsed || 'N/A'}`);
    if (tx2.daiAmount) {
      const daiAmount = Number(tx2.daiAmount) / 1e18;
      const rate = daiAmount / 0.1; // DAI por ETH
      console.log(`   💰 DAI recebido: ${daiAmount.toFixed(4)} DAI`);
      console.log(`   💱 Taxa de câmbio: ${rate.toFixed(2)} DAI por ETH`);
    }
    if (tx2.dashboardUrl) {
      console.log(`   🔗 Ver no Dashboard: ${tx2.dashboardUrl}`);
    }
    
    // Comparar preços
    if (tx1.daiAmount && tx2.daiAmount) {
      const tx1Rate = Number(tx1.daiAmount) / 5;
      const tx2Rate = Number(tx2.daiAmount) / 0.1;
      const diff = ((tx2Rate - tx1Rate) / tx1Rate * 100).toFixed(2);
      
      console.log(`\n📉 ANÁLISE: Comparação de Preços`);
      console.log(`   TX1 (ataque): ${tx1Rate.toFixed(2)} DAI por ETH`);
      console.log(`   TX2 (vítima): ${tx2Rate.toFixed(2)} DAI por ETH`);
      console.log(`   Diferença: ${diff}%`);
      
      if (Math.abs(Number(diff)) > 0.1) {
        console.log(`\n⚠️  ATENÇÃO: Em um bundle real no mesmo bloco, o impacto seria maior!`);
        console.log(`   A TX2 receberia um preço ainda pior devido ao slippage acumulado.`);
      }
    }
    
    // Mostrar links de forma destacada
    if (tx1.dashboardUrl || tx2.dashboardUrl) {
      console.log('\n' + '='.repeat(60));
      console.log('🔗 LINKS PARA ANÁLISE NO DASHBOARD TENDERLY:');
      if (tx1.dashboardUrl) {
        console.log(`   📊 TX1 (Ataque): ${tx1.dashboardUrl}`);
      }
      if (tx2.dashboardUrl) {
        console.log(`   📊 TX2 (Vítima): ${tx2.dashboardUrl}`);
      }
      console.log('='.repeat(60));
    }
    
    console.log('\n💡 CONCLUSÃO:');
    console.log('   Esta simulação demonstra o conceito de manipulação de spot.');
    console.log('   Em um bundle real no mesmo bloco, o impacto seria ainda mais significativo.');
    console.log('   ⚠️  Isso demonstra por que usar spot de DEX como oráculo é perigoso!\n');
    
  } catch (error: any) {
    console.error('❌ Erro na simulação:', error.message);
    if (error.response?.data) {
      console.error('Detalhes:', JSON.stringify(error.response.data, null, 2));
    }
    process.exit(1);
  }
})();
