import { vnetWallet, vnetPublic, fundAccounts } from './viemClient.js';
import { encodeFunctionData, parseUnits } from 'viem';
import { UNISWAP_V3_SWAPROUTER, WETH, DAI } from '../constants.js';
import { UNISWAP_V3_SWAPROUTER_ABI } from '../abi/uniswapV3Router.js';

(async () => {
  try {
    if (!process.env.VNET_RPC || process.env.VNET_RPC === '') {
      console.error('❌ Erro: Configure VNET_RPC no arquivo .env');
      console.error('   A VirtualNet é uma cópia isolada da mainnet para testes seguros.');
      process.exit(1);
    }

    console.log('🌐 SIMULAÇÃO: Swap Uniswap V3 na VirtualNet\n');
    console.log('='.repeat(60));
    console.log('📚 O QUE ESTAMOS FAZENDO:');
    console.log('   Este script executa um swap REAL na VirtualNet (fork da mainnet).');
    console.log('   A VirtualNet é uma cópia isolada onde você pode testar sem riscos.\n');
    console.log('📖 DIFERENÇA:');
    console.log('   - Simulação API: Apenas simula (não executa de verdade)');
    console.log('   - VirtualNet: Executa transação real em ambiente isolado\n');
    console.log('💡 VANTAGENS DA VIRTUALNET:');
    console.log('   ✅ Comporta-se como uma rede real');
    console.log('   ✅ Retorna TX hash (pode ver no dashboard)');
    console.log('   ✅ Pode executar múltiplas transações sequenciais');
    console.log('   ✅ Não afeta a mainnet real\n');
    console.log('='.repeat(60));
    
    console.log('⏳ Passo 1: Verificando configuração...');
    const [address] = await vnetWallet.getAddresses();
    console.log(`   ✅ Endereço da carteira: ${address}\n`);
    
    console.log('⏳ Passo 2: Verificando saldo...');
    const balance = await vnetPublic.getBalance({ address });
    const minBalance = parseUnits('0.1', 18); // 0.1 ETH mínimo para o swap
    
    console.log(`   💰 Saldo atual: ${(Number(balance) / 1e18).toFixed(4)} ETH`);
    
    if (balance < minBalance) {
      console.log('\n⚠️  Saldo insuficiente!');
      console.log('   Para fundar a conta, use o Admin RPC:');
      console.log('   curl -X POST https://virtual.mainnet.eu.rpc.tenderly.co/ADMIN_RPC_URL \\');
      console.log('     -H "Content-Type: application/json" \\');
      console.log('     -d \'{"method":"tenderly_setBalance","params":[["' + address + '"],"0x8ac7230489e80000"]}\'\n');
      process.exit(1);
    }
    
    console.log('   ✅ Saldo suficiente!\n');
  
    console.log('⏳ Passo 3: Preparando swap...');
    const amountIn = parseUnits('0.02', 18);
    const deadline = BigInt(Math.floor(Date.now()/1000) + 900);
    
    const params = {
      tokenIn: WETH,
      tokenOut: DAI,
      fee: 3000, // 0.3%
      recipient: address,
      deadline,
      amountIn,
      amountOutMinimum: 0n,
      sqrtPriceLimitX96: 0n
    };

    const data = encodeFunctionData({
      abi: UNISWAP_V3_SWAPROUTER_ABI,
      functionName: 'exactInputSingle',
      args: [params]
    });

    console.log('   📋 Parâmetros do swap:');
    console.log(`      Token In: WETH (Wrapped Ether)`);
    console.log(`      Token Out: DAI (Dai Stablecoin)`);
    console.log(`      Amount In: 0.02 ETH`);
    console.log(`      Fee Tier: 0.3% (pool mais líquido)\n`);

    console.log('⏳ Passo 4: Enviando transação para VirtualNet...');
    const txHash = await vnetWallet.sendTransaction({
      to: UNISWAP_V3_SWAPROUTER as `0x${string}`,
      value: amountIn, // ETH -> WETH
      data
    });
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ TRANSAÇÃO EXECUTADA COM SUCESSO!\n');
    console.log(`📋 TX Hash na VirtualNet: ${txHash}`);
    
    // Construir URL do dashboard Tenderly para VirtualNet
    const account = process.env.TENDERLY_ACCOUNT || 'afonsodalvi';
    const project = process.env.TENDERLY_PROJECT || 'project';
    const vnetDashboardUrl = `https://dashboard.tenderly.co/${account}/${project}/virtual-network`;
    
    console.log(`\n🔗 Ver transação no Dashboard Tenderly:`);
    console.log(`   ${vnetDashboardUrl}`);
    console.log(`   (Procure pela TX hash: ${txHash})`);
    console.log('='.repeat(60));
    
    console.log('\n💡 OBSERVAÇÕES:');
    console.log('   ✅ Esta transação foi executada na sua VirtualNet, não na mainnet real.');
    console.log('   ✅ Você pode ver todos os detalhes no dashboard do Tenderly.');
    console.log('   ✅ Use faucet/Admin RPC para adicionar mais ETH se necessário.\n');
    
  } catch (error: any) {
    console.error('❌ Erro ao enviar transação:', error.message);
    if (error.cause) {
      console.error('Causa:', error.cause);
    }
    console.log('\n💡 Dica: Certifique-se de ter ETH na VirtualNet (use faucet/admin RPC).');
    process.exit(1);
  }
})();
