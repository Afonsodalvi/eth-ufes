import { config } from '../src/config/index.js';
import https from 'https';
import http from 'http';

/**
 * Testa a conectividade com o RPC endpoint
 */
async function testRpcConnection() {
  console.log('=== Teste de Conectividade RPC ===\n');
  console.log(`RPC URL: ${config.rpcUrl}\n`);
  
  const rpcUrl = config.rpcUrl;
  const url = new URL(rpcUrl);
  
  // Prepara a requisição JSON-RPC
  const jsonRpcRequest = {
    jsonrpc: '2.0',
    method: 'eth_blockNumber',
    params: [],
    id: 1
  };
  
  const requestOptions = {
    hostname: url.hostname,
    port: url.port || (url.protocol === 'https:' ? 443 : 80),
    path: url.pathname + url.search,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    timeout: 10000 // 10 segundos
  };
  
  return new Promise((resolve, reject) => {
    const client = url.protocol === 'https:' ? https : http;
    const req = client.request(requestOptions, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (response.result) {
            console.log('✅ Conexão bem-sucedida!');
            console.log(`Resposta: ${JSON.stringify(response, null, 2)}`);
            resolve(response);
          } else if (response.error) {
            console.log('⚠️ Servidor respondeu com erro:');
            console.log(`Erro: ${response.error.message}`);
            resolve(response);
          } else {
            console.log('⚠️ Resposta inesperada:');
            console.log(data);
            resolve(response);
          }
        } catch (error) {
          console.log('⚠️ Erro ao parsear resposta:', error.message);
          console.log('Resposta recebida:', data.substring(0, 200));
          reject(error);
        }
      });
    });
    
    req.on('error', (error) => {
      console.error('❌ Erro na requisição:', error.message);
      console.error('\n💡 Possíveis causas:');
      console.error('   1. URL do RPC incorreta');
      console.error('   2. Problemas de conectividade');
      console.error('   3. Firewall ou proxy bloqueando');
      console.error('   4. Chave API inválida ou expirada');
      reject(error);
    });
    
    req.on('timeout', () => {
      req.destroy();
      console.error('❌ Timeout na requisição');
      console.error('\n💡 A requisição demorou mais de 10 segundos.');
      reject(new Error('Request timeout'));
    });
    
    req.write(JSON.stringify(jsonRpcRequest));
    req.end();
  });
}

// Executa o teste
testRpcConnection()
  .then(() => {
    console.log('\n✅ Teste concluído com sucesso!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Teste falhou:', error.message);
    process.exit(1);
  });

