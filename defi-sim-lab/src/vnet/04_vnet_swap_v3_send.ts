import { vnetWallet, vnetPublic, fundAccounts } from './viemClient.js';
import { encodeFunctionData, parseUnits } from 'viem';
import { UNISWAP_V3_SWAPROUTER, WETH, DAI } from '../constants.js';
import { UNISWAP_V3_SWAPROUTER_ABI } from '../abi/uniswapV3Router.js';

(async () => {
  try {
    if (!process.env.VNET_RPC || process.env.VNET_RPC === '') {
      console.error('❌ Erro: Configure VNET_RPC no arquivo .env');
      process.exit(1);
    }

    console.log('🌐 Enviando swap V3 na VirtualNet...\n');
    
    const [address] = await vnetWallet.getAddresses();
    console.log(`Endereço da carteira: ${address}\n`);
    
    // Verificar saldo
    const balance = await vnetPublic.getBalance({ address });
    const minBalance = parseUnits('0.1', 18); // 0.1 ETH mínimo para o swap
    
    console.log(`💰 Saldo atual: ${(Number(balance) / 1e18).toFixed(4)} ETH`);
    
    if (balance < minBalance) {
      console.log('\n⚠️  Saldo insuficiente!');
      console.log('   Para fundar a conta, use o Admin RPC:');
      console.log('   curl -X POST https://virtual.mainnet.eu.rpc.tenderly.co/ADMIN_RPC_URL \\');
      console.log('     -H "Content-Type: application/json" \\');
      console.log('     -d \'{"method":"tenderly_setBalance","params":[["' + address + '"],"0x8ac7230489e80000"]}\'\n');
      process.exit(1);
    }
    
    console.log('');
  
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

    console.log('Parâmetros do swap:');
    console.log(`  Token In: WETH`);
    console.log(`  Token Out: DAI`);
    console.log(`  Amount In: 0.02 ETH`);
    console.log(`  Fee Tier: 0.3%\n`);

    const txHash = await vnetWallet.sendTransaction({
      to: UNISWAP_V3_SWAPROUTER as `0x${string}`,
      value: amountIn, // ETH -> WETH
      data
    });
    
    console.log('✅ Transação enviada com sucesso!');
    console.log(`📋 TX Hash na VirtualNet: ${txHash}\n`);
    console.log('💡 Esta transação foi executada na sua VirtualNet, não na mainnet real.');
    console.log('   Use faucet/Admin RPC para adicionar ETH antes se necessário.\n');
    
  } catch (error: any) {
    console.error('❌ Erro ao enviar transação:', error.message);
    if (error.cause) {
      console.error('Causa:', error.cause);
    }
    console.log('\n💡 Dica: Certifique-se de ter ETH na VirtualNet (use faucet/admin RPC).');
    process.exit(1);
  }
})();
