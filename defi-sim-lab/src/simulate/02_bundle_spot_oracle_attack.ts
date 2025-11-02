import 'dotenv/config';
import { encodeFunctionData, parseUnits } from 'viem';
import { tenderly, MAINNET } from '../tenderly.js';
import { UNISWAP_V2_ROUTER, WETH } from '../constants.js';
import { UNISWAP_V2_ROUTER_ABI } from '../abi/uniswapV2Router.js';

// Altere para um par raso: [WETH, TOKEN_RARO]
// Para demonstração, usando um token de baixa liquidez conhecido
// Em produção, escolha um pool raso de preferência ou use VirtualNet com faucet
const FROM = process.env.FROM!;
const TOKEN_RARO = '0x6B175474E89094C44Da98b954EedeAC495271d0F'; // DAI como exemplo (substitua por token raro real)
const amountBigEth = parseUnits('5', 18); // grande p/ mexer bastante no preço
const deadline = BigInt(Math.floor(Date.now()/1000) + 600);

(async () => {
  try {
    if (!FROM || FROM === '0xSEU_ENDERECO_EOA' || FROM === '') {
      console.error('❌ Erro: Configure FROM no arquivo .env com um endereço EOA válido');
      process.exit(1);
    }

    console.log('🚨 Simulando Bundle: Spot Oracle Attack\n');
    console.log('Cenário:');
    console.log('  TX1: Ataque faz swap MUITO grande (manipula spot)');
    console.log('  TX2: Vítima faz swap dependente desse spot\n');
    
    const swapAtaque = encodeFunctionData({
    abi: UNISWAP_V2_ROUTER_ABI,
    functionName: 'swapExactETHForTokens',
    args: [0n, [WETH, TOKEN_RARO], FROM, deadline]
  });

  const swapVitima = encodeFunctionData({
    abi: UNISWAP_V2_ROUTER_ABI,
    functionName: 'swapExactETHForTokens',
    args: [0n, [WETH, TOKEN_RARO], FROM, deadline]
  });

  const res = await tenderly.simulator.simulateBundle({
    network_id: MAINNET,
    // mesma altura/bloco — executa sequencialmente
    bundle: [
      {
        from: FROM,
        to: UNISWAP_V2_ROUTER,
        gas: 3_000_000,
        gas_price: '0',
        value: amountBigEth.toString(),
        input: swapAtaque
      },
      {
        from: FROM,
        to: UNISWAP_V2_ROUTER,
        gas: 3_000_000,
        gas_price: '0',
        value: parseUnits('0.1', 18).toString(),
        input: swapVitima
      }
    ],
    save_if_fails: true
  });

    console.log('=== RESULTADOS DO BUNDLE ===\n');
    
    const simulations = res.simulations || res.bundle_simulations || [];
    
    if (simulations.length >= 2) {
      const tx1 = simulations[0];
      const tx2 = simulations[1];
      
      console.log('TX1 (Ataque - Swap Grande):');
      const tx1Status = tx1.transaction?.status ?? tx1.status;
      console.log(`  Status: ${tx1Status ? '✅ Sucesso' : '❌ Falhou'}`);
      console.log(`  Gas usado: ${tx1.transaction?.gas_used || tx1.gas_used || 'N/A'}`);
      
      const tx1AssetChanges = tx1.simulation?.asset_changes || tx1.asset_changes || [];
      if (tx1AssetChanges.length > 0) {
        tx1AssetChanges.forEach((change: any) => {
          if (change.address?.toLowerCase() === FROM.toLowerCase()) {
            console.log(`  ${change.asset?.symbol || 'Token'}: ${change.delta || '0'}`);
          }
        });
      } else {
        console.log('  (Nenhuma mudança de asset detectada)');
      }
      
      console.log('\nTX2 (Vítima - Swap Pequeno):');
      const tx2Status = tx2.transaction?.status ?? tx2.status;
      console.log(`  Status: ${tx2Status ? '✅ Sucesso' : '❌ Falhou'}`);
      console.log(`  Gas usado: ${tx2.transaction?.gas_used || tx2.gas_used || 'N/A'}`);
      
      const tx2AssetChanges = tx2.simulation?.asset_changes || tx2.asset_changes || [];
      if (tx2AssetChanges.length > 0) {
        tx2AssetChanges.forEach((change: any) => {
          if (change.address?.toLowerCase() === FROM.toLowerCase()) {
            console.log(`  ${change.asset?.symbol || 'Token'}: ${change.delta || '0'}`);
          }
        });
      } else {
        console.log('  (Nenhuma mudança de asset detectada)');
      }
      
      console.log('\n💡 Observe como a TX2 (vítima) recebe preço pior após a manipulação da TX1!');
    } else {
      console.log('⚠️  Resultado inesperado. Estrutura da resposta:');
      console.log(JSON.stringify(res, null, 2));
    }
    
    console.log('\n📋 JSON completo salvo acima para análise detalhada.');
    // Mostre em aula: "assetChanges" da 2ª tx antes/depois do ataque no mesmo bloco.
  } catch (error: any) {
    console.error('❌ Erro na simulação:', error.message);
    if (error.response?.data) {
      console.error('Detalhes:', JSON.stringify(error.response.data, null, 2));
    }
    process.exit(1);
  }
})();
