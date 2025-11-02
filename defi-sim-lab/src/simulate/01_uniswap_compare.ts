import 'dotenv/config';
import { encodeFunctionData, parseUnits, getAddress, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { tenderly } from '../tenderly.js';
import { toDec } from '../util/num.js';
import {
  UNISWAP_V2_ROUTER, UNISWAP_V3_SWAPROUTER, WETH, DAI, DEFAULT_FROM
} from '../constants.js';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';
import { UNISWAP_V3_SWAPROUTER_ABI } from '../abi/uniswapV3Router.js';

// Cliente RPC público para obter blockNumber atual
const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com') // RPC público
});

// FROM: validar e aplicar checksum (EIP-55) para evitar "From address not valid"
const RAW_FROM = (process.env.FROM || DEFAULT_FROM).trim();
if (!RAW_FROM) {
  throw new Error('Defina FROM no .env ou use o padrão');
}

let FROM: `0x${string}`;
try {
  FROM = getAddress(RAW_FROM); // checksum → evita "From address not valid"
  if (process.env.DEBUG === 'true') {
    console.log(`📝 Usando FROM do .env: ${FROM}`);
  }
} catch (error) {
  console.warn(`⚠️  FROM do .env inválido ou causando erro (${RAW_FROM})`);
  console.warn(`   Usando endereço padrão (Vitalik) que sempre funciona...`);
  FROM = getAddress(DEFAULT_FROM);
}

// Debug: mostrar qual endereço está sendo usado
if (process.env.DEBUG === 'true') {
  console.log(`✅ FROM final (checksum EIP-55): ${FROM}`);
}

const amountIn = parseUnits('0.01', 18); // BigInt (vamos converter para string decimal)
const deadline = BigInt(Math.floor(Date.now()/1000) + 900);

async function simV2() {
  console.log('   📝 Preparando simulação V2...');
  
  const input = encodeFunctionData({
    abi: UNISWAP_V2_ROUTER_ABI,
    functionName: 'swapExactETHForTokens',
    args: [0n, [WETH, DAI], FROM, deadline]
  });

  console.log(`   ✅ Input gerado: ${input.substring(0, 20)}...`);

  if (!input || input === '0x') {
    throw new Error('Input da transação está vazio ou inválido');
  }

  try {
    console.log('   🚀 Enviando para Tenderly...');

    // Obter blockNumber atual
    const blockNumber = await publicClient.getBlockNumber();
    const blockNumberNum = Number(blockNumber);

    // Converter BigInt para string decimal ANTES de montar o payload
    const amountInStr = toDec(amountIn);

    // SDK usa blockNumber (camelCase, número) e NÃO precisa de network_id
    // (a network já foi passada no constructor do Tenderly)
    const res = await tenderly.simulator.simulateTransaction({
      blockNumber: blockNumberNum,        // número (não "latest", não string)
      simulation_type: 'full',            // "full" para erros mais verbosos
      save_if_fails: true,
      transaction: {
        from: FROM.toLowerCase(),         // lowercase evita validações chatas
        to: UNISWAP_V2_ROUTER.toLowerCase(),
        gas: 2_500_000,                   // number pequeno: ok
        gas_price: '0',                   // string decimal (ou 0)
        value: amountInStr,               // string decimal (não hex, não BigInt)
        input
      },
      // opcional: dá saldo na simulação
      state_objects: {
        [FROM.toLowerCase()]: { 
          balance: toDec(parseUnits('100', 18)) // string decimal
        }
      }
    });

    console.log('   ✅ Recebido do Tenderly!');

    const gasUsed = res.transaction?.gas_used || res.gas_used;
    const output = res.transaction?.output || res.output;
    const amountOut = output ? BigInt(output) : undefined;
    
    const assetChanges = res.simulation?.asset_changes || res.asset_changes || [];
    const daiGain = assetChanges.find((c: any) =>
      c.address?.toLowerCase() === FROM.toLowerCase() && c.asset?.symbol === 'DAI'
    )?.delta;

    return { gasUsed, amountOut, daiGain };
  } catch (error: any) {
    console.error('   ❌ Erro na chamada ao Tenderly (V2):');
    console.error(`      Mensagem: ${error.message || error}`);
    
    if (error.response) {
      console.error(`      Response Status: ${error.response.status}`);
      console.error(`      Response Data: ${JSON.stringify(error.response.data, null, 2)}`);
    }
    
    if (error.data) {
      console.error(`      Error Data: ${JSON.stringify(error.data, null, 2)}`);
    }
    
    if (error.status) {
      console.error(`      Status: ${error.status}`);
    }
    
    if (error.slug) {
      console.error(`      Slug: ${error.slug}`);
    }
    
    throw error;
  }
}

async function simV3() {
  console.log('   📝 Preparando simulação V3...');
  
  const params = {
    tokenIn: WETH,
    tokenOut: DAI,
    fee: 3000, // 0.3%
    recipient: FROM,
    deadline,
    amountIn,
    amountOutMinimum: 0n,
    sqrtPriceLimitX96: 0n
  } as const;

  const input = encodeFunctionData({
    abi: UNISWAP_V3_SWAPROUTER_ABI,
    functionName: 'exactInputSingle',
    args: [params]
  });

  console.log(`   ✅ Input gerado: ${input.substring(0, 20)}...`);

  if (!input || input === '0x') {
    throw new Error('Input da transação está vazio ou inválido');
  }

  try {
    console.log('   🚀 Enviando para Tenderly...');

    // Obter blockNumber atual
    const blockNumber = await publicClient.getBlockNumber();
    const blockNumberNum = Number(blockNumber);

    // Converter BigInt para string decimal ANTES de montar o payload
    const amountInStr = toDec(amountIn);

    // SDK usa blockNumber (camelCase, número) e NÃO precisa de network_id
    // (a network já foi passada no constructor do Tenderly)
    const res = await tenderly.simulator.simulateTransaction({
      blockNumber: blockNumberNum,        // número (não "latest", não string)
      simulation_type: 'full',            // "full" para erros mais verbosos
      save_if_fails: true,
      transaction: {
        from: FROM.toLowerCase(),         // lowercase evita validações chatas
        to: UNISWAP_V3_SWAPROUTER.toLowerCase(),
        gas: 2_500_000,                   // number pequeno: ok
        gas_price: '0',                   // string decimal (ou 0)
        value: amountInStr,               // string decimal (não hex, não BigInt)
        input
      },
      // opcional: dá saldo na simulação
      state_objects: {
        [FROM.toLowerCase()]: { 
          balance: toDec(parseUnits('100', 18)) // string decimal
        }
      }
    });

    console.log('   ✅ Recebido do Tenderly!');

    const gasUsed = res.transaction?.gas_used || res.gas_used;
    const output = res.transaction?.output || res.output;
    const amountOut = output ? BigInt(output) : undefined;
    
    const assetChanges = res.simulation?.asset_changes || res.asset_changes || [];
    const daiGain = assetChanges.find((c: any) =>
      c.address?.toLowerCase() === FROM.toLowerCase() && c.asset?.symbol === 'DAI'
    )?.delta;

    return { gasUsed, amountOut, daiGain };
  } catch (error: any) {
    console.error('   ❌ Erro na chamada ao Tenderly (V3):');
    console.error(`      Mensagem: ${error.message || error}`);
    
    if (error.response) {
      console.error(`      Response Status: ${error.response.status}`);
      console.error(`      Response Data: ${JSON.stringify(error.response.data, null, 2)}`);
    }
    
    if (error.data) {
      console.error(`      Error Data: ${JSON.stringify(error.data, null, 2)}`);
    }
    
    if (error.status) {
      console.error(`      Status: ${error.status}`);
    }
    
    if (error.slug) {
      console.error(`      Slug: ${error.slug}`);
    }
    
    throw error;
  }
}

(async () => {
  try {
    console.log('🔄 Comparando Uniswap V2 vs V3...\n');
    console.log(`Entrada: 0.01 ETH`);
    console.log(`Endereço FROM: ${FROM} (checksum EIP-55)`);
    console.log(`   (EOA da Ethereum mainnet - pode ser qualquer endereço válido)\n`);
    
    console.log('⏳ Obtendo blockNumber atual...');
    const currentBlock = await publicClient.getBlockNumber();
    console.log(`   BlockNumber: ${currentBlock}\n`);
    
    console.log('⏳ Executando simulações...\n');
    
    // Executar em paralelo para mais velocidade
    const [v2, v3] = await Promise.all([simV2(), simV3()]);
    
    console.log('=== RESULTADOS ===\n');
    console.log('📊 Uniswap V2:');
    console.log(`  Gas usado: ${v2.gasUsed || 'N/A'}`);
    console.log(`  DAI recebido: ${v2.daiGain || 'N/A'}`);
    if (v2.amountOut) {
      console.log(`  AmountOut: ${v2.amountOut.toString()}\n`);
    } else {
      console.log(`  AmountOut: N/A\n`);
    }
    
    console.log('📊 Uniswap V3:');
    console.log(`  Gas usado: ${v3.gasUsed || 'N/A'}`);
    console.log(`  DAI recebido: ${v3.daiGain || 'N/A'}`);
    if (v3.amountOut) {
      console.log(`  AmountOut: ${v3.amountOut.toString()}\n`);
    } else {
      console.log(`  AmountOut: N/A\n`);
    }
    
    // Comparação
    if (v2.gasUsed && v3.gasUsed) {
      const gasDiff = Number(v3.gasUsed) - Number(v2.gasUsed);
      const gasDiffPercent = ((gasDiff / Number(v2.gasUsed)) * 100).toFixed(2);
      console.log(`💰 Diferença de gas: ${gasDiff > 0 ? '+' : ''}${gasDiff} (${gasDiffPercent}%)\n`);
    }
    
    console.log('✅ Simulações concluídas com sucesso!');
    console.log('   Use esses números side-by-side nos slides para discutir slippage,');
    console.log('   eficiência de capital e diferenças de gas entre V2 e V3.');
    
  } catch (error: any) {
    console.error('\n❌ Erro na simulação:', error.message || error);
    
    // Mensagens de ajuda específicas para erros comuns
    if (error.message?.includes('Do not know how to serialize a BigInt')) {
      console.error('\n💡 Erro de serialização BigInt:');
      console.error('   Isso não deveria acontecer com as correções aplicadas.');
      console.error('   Verifique se todos os BigInt foram convertidos com toDec()');
    }
    
    if (error.message?.includes('From address not valid') || error.message?.includes('validation')) {
      console.error('\n💡 Erro de validação de endereço:');
      console.error('   O endereço FROM precisa estar em checksum (EIP-55)');
      console.error('   Verifique se está usando getAddress() do viem');
    }
    
    if (error.message?.includes('Internal server error') || error.message?.includes('500') || error.response?.status === 500) {
      console.error('\n💡 Possíveis causas do "Internal server error":');
      console.error('   1. blockNumber ausente ou inválido (agora está presente como número)');
      console.error('   2. network_id presente no SDK (removido - SDK já sabe a network)');
      console.error('   3. TENDERLY_PROJECT está usando o nome ao invés do slug');
      console.error('      → Verifique a URL: https://api.tenderly.co/api/v1/account/Omnes/project/[SLUG]/');
      console.error('      → Use o SLUG exatamente como aparece na URL do dashboard');
      console.error('   4. Token de acesso não tem permissões suficientes');
      console.error('      → Gere um novo token em: Account Settings > Access Tokens');
      console.error('   5. Projeto não existe ou não tem acesso');
      console.error('      → Verifique se consegue acessar o projeto no dashboard');
      console.error('   6. Limite de rate limit atingido');
      console.error('      → Aguarde alguns minutos e tente novamente');
      console.error('\n   Mais informações: defi-sim-lab/TENDERLY_SETUP.md');
    }
    
    if (error.stack) {
      console.error('\n📚 Stack trace completo:');
      console.error(error.stack);
    }
    
    process.exit(1);
  }
})();