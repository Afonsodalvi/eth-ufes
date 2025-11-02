import { ethers } from 'ethers';
import { config } from '../config/index.js';

/**
 * Classe para gerenciar conexões com a blockchain
 */
export class ProviderManager {
  constructor() {
    this.provider = null;
    this.wallet = null;
    this.signer = null;
  }

  /**
   * Inicializa o provider e wallet
   * @param {string} rpcUrl - URL do RPC
   * @param {string} privateKey - Chave privada (opcional)
   */
  async initialize(rpcUrl = config.rpcUrl, privateKey = config.privateKey) {
    try {
      console.log(`Tentando conectar ao RPC: ${rpcUrl.substring(0, 50)}...`);
      
      // Cria o provider (ethers v6)
      this.provider = new ethers.JsonRpcProvider(rpcUrl);
      
      // Testa a conexão com retry e timeout explícito
      console.log('Testando conexão com a rede...');
      
      // Verifica a conexão com retry
      let network;
      let attempts = 0;
      const maxAttempts = 3;
      const timeoutMs = 60000; // 60 segundos
      
      while (attempts < maxAttempts) {
        try {
          // Usa Promise.race para implementar timeout manual
          network = await Promise.race([
            this.provider.getNetwork(),
            new Promise((_, reject) => 
              setTimeout(() => reject(new Error(`Timeout após ${timeoutMs/1000} segundos`)), timeoutMs)
            )
          ]);
          break;
        } catch (error) {
          attempts++;
          if (attempts >= maxAttempts) {
            const errorMsg = error.message || String(error);
            throw new Error(`Falha ao conectar após ${maxAttempts} tentativas: ${errorMsg}`);
          }
          console.log(`   Tentativa ${attempts}/${maxAttempts} falhou: ${error.message || error}`);
          console.log(`   Tentando novamente em 2 segundos...`);
          await new Promise(resolve => setTimeout(resolve, 2000)); // Espera 2s antes de retry
        }
      }
      
      console.log(`✅ Conectado à rede: ${network.name} (Chain ID: ${network.chainId})`);
      
      // Se uma chave privada foi fornecida, cria o wallet
      if (privateKey) {
        this.wallet = new ethers.Wallet(privateKey, this.provider);
        this.signer = this.wallet;
        console.log(`✅ Wallet conectado: ${this.wallet.address}`);
      }
      
      return true;
    } catch (error) {
      console.error('\n❌ Erro ao inicializar provider:', error.message);
      console.error('\n💡 Dicas de solução:');
      console.error('   1. Verifique se o RPC_URL no .env está correto');
      console.error('   2. Verifique sua conexão com a internet');
      console.error('   3. Verifique se há firewall ou proxy bloqueando');
      console.error('   4. Tente usar outro endpoint RPC (ex: https://rpc-amoy.polygon.technology)');
      console.error('   5. Execute: node examples/test-rpc.js para testar a conectividade');
      throw error;
    }
  }

  /**
   * Obtém o provider atual
   */
  getProvider() {
    if (!this.provider) {
      throw new Error('Provider não inicializado. Chame initialize() primeiro.');
    }
    return this.provider;
  }

  /**
   * Obtém o signer atual
   */
  getSigner() {
    if (!this.signer) {
      throw new Error('Signer não disponível. Forneça uma chave privada.');
    }
    return this.signer;
  }

  /**
   * Obtém o endereço do wallet
   */
  getAddress() {
    if (!this.wallet) {
      throw new Error('Wallet não inicializado.');
    }
    return this.wallet.address;
  }

  /**
   * Obtém o saldo do wallet
   */
  async getBalance(address = null) {
    const targetAddress = address || this.getAddress();
    const balance = await this.provider.getBalance(targetAddress);
    return ethers.formatEther(balance);
  }

  /**
   * Obtém informações da rede
   */
  async getNetworkInfo() {
    const network = await this.provider.getNetwork();
    const blockNumber = await this.provider.getBlockNumber();
    
    return {
      name: network.name,
      chainId: Number(network.chainId),
      blockNumber
    };
  }
}

// Instância singleton
export const providerManager = new ProviderManager();
