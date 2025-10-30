import { BaseContract } from './BaseContract.js';
import { providerManager } from '../utils/provider.js';

/**
 * Classe base com sistema de polling manual para eventos
 * Evita completamente o uso de filtros automáticos do Ethers.js
 */
export class SimpleEventContract extends BaseContract {
  constructor(contractAddress, abi, contractName = 'Contract') {
    super(contractAddress, abi, contractName);
    this.pollingIntervals = new Map(); // Para rastrear intervalos de polling
    this.lastBlockNumber = 0;
    this.isPolling = false;
  }

  /**
   * Escuta eventos usando polling manual (sem filtros)
   */
  async listenToEvent(eventName, callback) {
    try {
      if (!this.contract) {
        throw new Error('Contrato não inicializado');
      }

      // Para polling anterior se existir
      if (this.pollingIntervals.has(eventName)) {
        clearInterval(this.pollingIntervals.get(eventName));
      }

      // Cria um wrapper para o callback que trata erros
      const wrappedCallback = async (...args) => {
        try {
          await callback(...args);
        } catch (error) {
          console.error(`Erro no callback do evento ${eventName}:`, error);
        }
      };

      // Função de polling manual
      const pollEvents = async () => {
        try {
          const provider = providerManager.getProvider();
          const currentBlock = await provider.getBlockNumber();
          
          if (this.lastBlockNumber === 0) {
            this.lastBlockNumber = currentBlock;
            return;
          }

          // Busca eventos do último bloco verificado até o atual
          const filter = this.contract.filters[eventName]();
          const events = await this.contract.queryFilter(filter, this.lastBlockNumber, currentBlock);
          
          // Processa cada evento
          for (const event of events) {
            await wrappedCallback(event.args, event);
          }
          
          this.lastBlockNumber = currentBlock;
        } catch (error) {
          // Ignora erros de filtro e continua polling
          if (error.code === 'UNKNOWN_ERROR' && error.error?.message === 'filter not found') {
            console.warn(`⚠️  Filtro expirado para ${eventName}, continuando polling...`);
          } else {
            console.error(`Erro no polling de eventos ${eventName}:`, error.message);
          }
        }
      };

      // Inicia polling a cada 3 segundos
      const intervalId = setInterval(pollEvents, 3000);
      this.pollingIntervals.set(eventName, intervalId);
      
      // Executa polling inicial
      await pollEvents();
      
      console.log(`Escutando evento ${eventName} via polling manual`);
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
        if (this.pollingIntervals.has(eventName)) {
          clearInterval(this.pollingIntervals.get(eventName));
          this.pollingIntervals.delete(eventName);
          console.log(`Parou de escutar evento: ${eventName}`);
        } else {
          console.log(`Nenhum listener ativo para o evento: ${eventName}`);
        }
      } else {
        // Para todos os intervalos
        for (const [event, intervalId] of this.pollingIntervals) {
          clearInterval(intervalId);
        }
        this.pollingIntervals.clear();
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
      // Para todos os intervalos de polling
      for (const [event, intervalId] of this.pollingIntervals) {
        clearInterval(intervalId);
      }
      this.pollingIntervals.clear();
      
      // Chama cleanup da classe pai
      await super.cleanup();
      
      console.log(`${this.contractName} (polling manual) limpo com sucesso`);
    } catch (error) {
      console.error(`Erro ao limpar ${this.contractName}:`, error);
    }
  }
}
