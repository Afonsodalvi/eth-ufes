import { config } from '../src/config/index.js';

/**
 * Demonstração offline do sistema
 * Mostra como usar o sistema sem conexão real com a blockchain
 */
async function demoOffline() {
  console.log('🎯 Demonstração Offline do Sistema ETH-UFES Web3\n');
  
  console.log('📋 Configurações atuais:');
  console.log(`   RPC URL: ${config.rpcUrl}`);
  console.log(`   Chain ID: ${config.chainId}`);
  console.log(`   Private Key: ${config.privateKey ? 'Configurado' : 'Não configurado'}`);
  console.log(`   Contrato Counter: ${config.contracts.counter || 'Não configurado'}`);
  
  console.log('\n📁 Estrutura do projeto:');
  console.log('   ✅ src/config/index.js - Configurações');
  console.log('   ✅ src/utils/provider.js - Gerenciamento de conexões');
  console.log('   ✅ src/contracts/BaseContract.js - Classe base');
  console.log('   ✅ src/contracts/CounterContract.js - Contrato Counter');
  console.log('   ✅ src/abis/Counter.json - ABI do contrato');
  
  console.log('\n🚀 Como usar:');
  console.log('   1. Configure suas variáveis no arquivo .env');
  console.log('   2. Execute: npm start');
  console.log('   3. Teste os exemplos: node examples/basic-usage.js');
  
  console.log('\n📚 Exemplos disponíveis:');
  console.log('   - basic-usage.js - Uso básico do sistema');
  console.log('   - simple-events.js - Eventos com polling manual (recomendado)');
  console.log('   - demo-offline.js - Esta demonstração');
  
  console.log('\n🔧 Para conectar à rede real:');
  console.log('   1. Configure RPC_URL (ex: Infura, Alchemy)');
  console.log('   2. Configure PRIVATE_KEY (opcional)');
  console.log('   3. Configure endereços dos contratos');
  
  console.log('\n✨ Sistema pronto para uso!');
}

// Executa a demonstração
demoOffline();
