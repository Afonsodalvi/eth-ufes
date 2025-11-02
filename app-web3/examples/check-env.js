import dotenv from 'dotenv';
import { config } from '../src/config/index.js';

// Carrega variáveis de ambiente explicitamente
const result = dotenv.config();

console.log('=== Verificação do Arquivo .env ===\n');

// Verifica se o arquivo .env foi encontrado
if (result.error) {
  console.error('❌ Erro ao carregar .env:', result.error.message);
  console.log('\n💡 Certifique-se de que o arquivo .env existe no diretório app-web3/');
} else {
  console.log('✅ Arquivo .env encontrado e carregado!');
  console.log(`📁 Caminho: ${result.parsed ? 'Carregado com sucesso' : 'Não pôde ser analisado'}\n`);
}

console.log('=== Variáveis de Ambiente Carregadas ===\n');

// Mostra as variáveis (sem valores sensíveis)
const envVars = {
  'RPC_URL': process.env.RPC_URL || '(não definido)',
  'PRIVATE_KEY': process.env.PRIVATE_KEY ? `${process.env.PRIVATE_KEY.substring(0, 10)}...` : '(não definido)',
  'COUNTER_CONTRACT_ADDRESS': process.env.COUNTER_CONTRACT_ADDRESS || '(não definido)',
  'CHAIN_ID': process.env.CHAIN_ID || '(não definido)',
  'GAS_LIMIT': process.env.GAS_LIMIT || '(não definido)',
  'GAS_PRICE': process.env.GAS_PRICE || '(não definido)',
};

Object.entries(envVars).forEach(([key, value]) => {
  const status = value === '(não definido)' ? '⚠️' : '✓';
  console.log(`${status} ${key}: ${value}`);
});

console.log('\n=== Configuração Carregada pelo Sistema ===\n');
console.log('RPC URL:', config.rpcUrl);
console.log('Chain ID:', config.chainId);
console.log('Gas Limit:', config.gasLimit);
console.log('Gas Price:', config.gasPrice);
console.log('Counter Contract:', config.contracts.counter || '(não configurado)');
console.log('Private Key:', config.privateKey ? 'Configurado (oculto)' : '(não configurado)');

console.log('\n=== Diagnóstico ===\n');

// Diagnóstico
const issues = [];
if (config.rpcUrl === 'http://localhost:8545') {
  issues.push('⚠️ RPC_URL está usando o padrão (localhost) - verifique se está definido no .env');
}
if (config.rpcUrl.includes('YOUR_') || config.rpcUrl.includes('YOUR_INFURA_PROJECT_ID')) {
  issues.push('⚠️ RPC_URL contém placeholder - substitua YOUR_INFURA_PROJECT_ID por uma chave válida');
}
if (config.chainId === 1 && process.env.CHAIN_ID !== '1') {
  issues.push('⚠️ Chain ID está usando padrão (1) - verifique CHAIN_ID no .env');
}

if (issues.length === 0) {
  console.log('✅ Tudo parece estar configurado corretamente!');
} else {
  issues.forEach(issue => console.log(issue));
}

