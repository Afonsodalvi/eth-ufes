import { ethers } from 'ethers';
import { providerManager } from '../utils/provider.js';

/**
 * Classe base para interações com contratos
 */
export class BaseContract {
  constructor(contractAddress, abi, contractName = 'Contract') {
    this.contractAddress = contractAddress;
    this.abi = abi;
    this.contractName = contractName;
    this.contract = null;
    this.contractWithSigner = null;
    this.eventListeners = new Map(); // Para rastrear listeners ativos
  }

  /**
   * Inicializa o contrato
   */
  async initialize() {
    try {
      const provider = providerManager.getProvider();
      this.contract = new ethers.Contract(this.contractAddress, this.abi, provider);
      
      // Se há um signer disponível, cria uma instância com signer
      try {
        const signer = providerManager.getSigner();
        this.contractWithSigner = this.contract.connect(signer);
      } catch (error) {
        console.log('Signer não disponível - apenas operações de leitura permitidas');
      }
      
      console.log(`${this.contractName} inicializado no endereço: ${this.contractAddress}`);
      return true;
    } catch (error) {
      console.error(`Erro ao inicializar ${this.contractName}:`, error);
      throw error;
    }
  }

  /**
   * Executa uma função de leitura (view/pure)
   */
  async read(functionName, ...args) {
    try {
      if (!this.contract) {
        throw new Error('Contrato não inicializado');
      }
      
      const result = await this.contract[functionName](...args);
      console.log(`${this.contractName}.${functionName}(${args.join(', ')}) = ${result}`);
      return result;
    } catch (error) {
      console.error(`Erro ao executar ${functionName}:`, error);
      throw error;
    }
  }

  /**
   * Executa uma função de escrita (transação)
   */
  async write(functionName, ...args) {
    try {
      if (!this.contractWithSigner) {
        throw new Error('Signer não disponível para operações de escrita');
      }
      
      console.log(`Enviando transação: ${this.contractName}.${functionName}(${args.join(', ')})`);
      
      const tx = await this.contractWithSigner[functionName](...args);
      console.log(`Transação enviada: ${tx.hash}`);
      
      const receipt = await tx.wait();
      console.log(`Transação confirmada no bloco: ${receipt.blockNumber}`);
      
      return { transaction: tx, receipt };
    } catch (error) {
      console.error(`Erro ao executar ${functionName}:`, error);
      throw error;
    }
  }

  /**
   * Escuta eventos do contrato usando polling manual (sem filtros)
   */
  async listenToEvent(eventName, callback) {
    try {
      if (!this.contract) {
        throw new Error('Contrato não inicializado');
      }
      
      // Cria um wrapper para o callback que trata erros
      const wrappedCallback = async (...args) => {
        try {
          await callback(...args);
        } catch (error) {
          console.error(`Erro no callback do evento ${eventName}:`, error);
        }
      };
      
      // Remove listener anterior se existir
      if (this.eventListeners.has(eventName)) {
        this.contract.off(eventName, this.eventListeners.get(eventName));
      }
      
      // Adiciona o novo listener
      this.contract.on(eventName, wrappedCallback);
      this.eventListeners.set(eventName, wrappedCallback);
      
      console.log(`Escutando evento: ${eventName} (sem filtros automáticos)`);
    } catch (error) {
      console.error(`Erro ao escutar evento ${eventName}:`, error);
      throw error;
    }
  }

  /**
   * Para de escutar eventos
   */
  async stopListening(eventName = null) {
    try {
      if (eventName) {
        if (this.eventListeners.has(eventName)) {
          const callback = this.eventListeners.get(eventName);
          this.contract.off(eventName, callback);
          this.eventListeners.delete(eventName);
          console.log(`Parou de escutar evento: ${eventName}`);
        } else {
          console.log(`Nenhum listener ativo para o evento: ${eventName}`);
        }
      } else {
        // Remove todos os listeners
        for (const [event, callback] of this.eventListeners) {
          try {
            this.contract.off(event, callback);
          } catch (error) {
            console.warn(`Erro ao remover listener do evento ${event}:`, error.message);
          }
        }
        this.eventListeners.clear();
        console.log('Parou de escutar todos os eventos');
      }
    } catch (error) {
      console.error('Erro ao parar de escutar eventos:', error);
      throw error;
    }
  }

  /**
   * Limpa todos os recursos do contrato
   */
  async cleanup() {
    try {
      // Para todos os listeners
      await this.stopListening();
      
      // Limpa referências
      this.contract = null;
      this.contractWithSigner = null;
      this.eventListeners.clear();
      
      console.log(`${this.contractName} limpo com sucesso`);
    } catch (error) {
      console.error(`Erro ao limpar ${this.contractName}:`, error);
    }
  }

  /**
   * Obtém informações do contrato
   */
  getContractInfo() {
    return {
      name: this.contractName,
      address: this.contractAddress,
      hasSigner: !!this.contractWithSigner,
      activeListeners: Array.from(this.eventListeners.keys())
    };
  }
}
