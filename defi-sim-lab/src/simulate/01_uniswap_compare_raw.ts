/**
 * Script de teste via API REST direta do Tenderly
 * Use este script se o SDK continuar dando erro 500
 * 
 * IMPORTANTE: REST usa block_number (snake_case, número) e campos no topo
 * 
 * Execute: npm run compare:raw
 */

import 'dotenv/config';
import axios from 'axios';
import { encodeFunctionData, parseUnits, getAddress, createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { UNISWAP_V2_ROUTER, WETH, DAI, DEFAULT_FROM } from '../constants.js';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';
import { toDec } from '../util/num.js';

// Cliente RPC público para obter block_number atual
const publicClient = createPublicClient({
  chain: mainnet,
  transport: http('https://eth.llamarpc.com') // RPC público
});

const ACCOUNT = process.env.TENDERLY_ACCOUNT;
const PROJECT = process.env.TENDERLY_PROJECT; // 'ufes' no seu caso
const KEY = process.env.TENDERLY_KEY;
const RAW_FROM = (process.env.FROM || DEFAULT_FROM).trim();

if (!ACCOUNT || !PROJECT || !KEY) {
  console.error('❌ Configure TENDERLY_ACCOUNT, TENDERLY_PROJECT e TENDERLY_KEY no .env');
  process.exit(1);
}

if (!RAW_FROM) {
  console.error('❌ Configure FROM no .env');
  process.exit(1);
}

// Usar endereço conhecido que funciona (Vitalik) para evitar problemas de validação
const TEST_FROM = getAddress(DEFAULT_FROM); // Vitalik address - sempre funciona

let FROM: `0x${string}`;
try {
  FROM = getAddress(RAW_FROM); // checksum → evita "From address not valid"
} catch (error) {
  console.warn(`⚠️  FROM inválido (${RAW_FROM}), usando padrão (Vitalik)...`);
  FROM = TEST_FROM;
}

(async () => {
  try {
    const url = `https://api.tenderly.co/api/v1/account/${ACCOUNT}/project/${PROJECT}/simulate`;
    const value = parseUnits('0.01', 18);
    const deadline = BigInt(Math.floor(Date.now()/1000) + 900);

    // Obter block_number atual
    console.log('⏳ Obtendo block_number atual...');
    const blockNumber = await publicClient.getBlockNumber();
    const blockNumberNum = Number(blockNumber);
    console.log(`   BlockNumber: ${blockNumberNum}\n`);

    // Usar TEST_FROM para garantir que funciona
    console.log(`⚠️  Testando com endereço: ${TEST_FROM} (Vitalik)`);
    console.log(`   (Para evitar erro de validação com ${FROM})\n`);

    const input = encodeFunctionData({
      abi: UNISWAP_V2_ROUTER_ABI,
      functionName: 'swapExactETHForTokens',
      args: [0n, [WETH, DAI], TEST_FROM, deadline]
    });

    // Converter BigInt para string decimal ANTES de montar o payload
    const valueStr = toDec(value);

    // REST: campos obrigatórios ficam no TOPO (não dentro de transaction)
    // block_number deve ser número (não "latest", não string)
    const body = {
      network_id: '1',                    // TOPO - obrigatório
      block_number: blockNumberNum,       // TOPO - obrigatório (número, não string)
      simulation_type: 'full',            // TOPO
      save_if_fails: true,               // TOPO
      from: TEST_FROM.toLowerCase(),      // TOPO - lowercase evita validações chatas
      to: UNISWAP_V2_ROUTER.toLowerCase(), // TOPO
      gas: 2_500_000,                    // TOPO - número
      gas_price: 0,                      // TOPO - número (ou '0' string)
      value: valueStr,                   // TOPO - string decimal (não hex)
      input,                             // TOPO
      state_objects: {                   // TOPO
        [TEST_FROM.toLowerCase()]: { 
          balance: toDec(parseUnits('100', 18)) // string decimal
        }
      }
    };

    console.log('🔄 Testando via API REST direta...');
    console.log(`URL: ${url}`);
    console.log(`Project: ${PROJECT}`);
    console.log(`Account: ${ACCOUNT}`);
    console.log(`From: ${TEST_FROM} (checksum EIP-55)\n`);

    if (process.env.DEBUG === 'true') {
      console.log('📦 Payload sendo enviado:');
      console.log(JSON.stringify(body, null, 2));
      console.log('');
    }

    const { data } = await axios.post(url, body, {
      headers: { 
        'X-Access-Key': KEY!,
        'Content-Type': 'application/json' 
      }
    });

    console.log('✅ Sucesso! Resposta da API:\n');
    console.log(JSON.stringify(data, null, 2));

    // Extrair informações úteis
    if (data.simulation) {
      const gasUsed = data.simulation.transaction?.gas_used;
      const assetChanges = data.simulation.asset_changes || [];
      const daiGain = assetChanges.find((c: any) =>
        c.address?.toLowerCase() === TEST_FROM.toLowerCase() && 
        c.asset?.symbol === 'DAI'
      )?.delta;

      console.log('\n📊 Resumo:');
      console.log(`  Gas usado: ${gasUsed || 'N/A'}`);
      console.log(`  DAI recebido: ${daiGain || 'N/A'}`);
    }

  } catch (error: any) {
    console.error('❌ Erro na chamada REST:');
    if (error.response) {
      console.error(`  Status: ${error.response.status}`);
      console.error(`  Data: ${JSON.stringify(error.response.data, null, 2)}`);
      
      if (error.response.data?.error?.slug === 'validation') {
        console.error('\n💡 Erro de validação:');
        console.error('   O endereço FROM pode estar inválido ou não ter checksum correto');
        console.error('   Tente com um endereço conhecido como o do Vitalik');
      }
      
      if (error.response.data?.error?.slug === 'json_unmarshal') {
        console.error('\n💡 Erro de formato (json_unmarshal):');
        console.error('   Verifique se block_number é um número (não string "latest")');
        console.error('   Verifique se value está como string decimal (não hex)');
        console.error('   Verifique se gas_price é número ou string "0"');
      }
      
      if (error.response.status === 401 || error.response.status === 403) {
        console.error('\n💡 Erro de autenticação:');
        console.error('   Verifique se TENDERLY_KEY está correto');
        console.error('   Gere um novo token em: Account Settings > Access Tokens');
      }
      
      if (error.response.status === 404) {
        console.error('\n💡 Projeto não encontrado:');
        console.error(`   Verifique se o projeto "${PROJECT}" existe na conta "${ACCOUNT}"`);
        console.error('   Verifique a URL do dashboard para confirmar o slug do projeto');
      }
      
      if (error.response.status === 500) {
        console.error('\n💡 Erro interno do servidor:');
        console.error('   Verifique se block_number é um número válido');
        console.error('   Verifique se todos os valores estão em formato correto');
      }
    } else {
      console.error(`  Erro: ${error.message}`);
      if (error.message?.includes('BigInt')) {
        console.error('\n💡 Erro de BigInt:');
        console.error('   Todos os valores BigInt devem ser convertidos para string antes de enviar');
        console.error('   Use toDec() para converter BigInt para string decimal');
      }
    }
    process.exit(1);
  }
})();