import { SimpleEventContract } from './SimpleEventContract.js';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const CounterABI = JSON.parse(readFileSync(join(__dirname, '../abis/Counter.json'), 'utf8'));

/**
 * Classe específica para o contrato Counter com polling manual
 * Evita completamente o erro "filter not found"
 */
export class CounterSimpleContract extends SimpleEventContract {
  constructor(contractAddress) {
    super(contractAddress, CounterABI, 'Counter');
  }

  /**
   * Obtém o número atual
   */
  async getNumber() {
    return await this.read('number');
  }

  /**
   * Define um novo número
   */
  async setNumber(newNumber) {
    return await this.write('setNumber', newNumber);
  }

  /**
   * Incrementa o número
   */
  async increment() {
    return await this.write('increment');
  }

  /**
   * Escuta eventos NumberSet usando polling manual
   */
  async onNumberSet(callback) {
    return await this.listenToEvent('NumberSet', callback);
  }

  /**
   * Para de escutar eventos NumberSet
   */
  async stopListeningNumberSet() {
    return await this.stopListening('NumberSet');
  }

  /**
   * Demonstra todas as funcionalidades do contrato
   */
  async demonstrate() {
    console.log('\n=== Demonstração do Contrato Counter (Polling Manual) ===');
    
    try {
      // Lê o número atual
      console.log('\n1. Lendo número atual...');
      const currentNumber = await this.getNumber();
      console.log(`Número atual: ${currentNumber}`);
      
      // Define um novo número
      console.log('\n2. Definindo número para 42...');
      await this.setNumber(42);
      
      // Lê novamente para confirmar
      const newNumber = await this.getNumber();
      console.log(`Novo número: ${newNumber}`);
      
      // Incrementa o número
      console.log('\n3. Incrementando número...');
      await this.increment();
      
      // Lê o número final
      const finalNumber = await this.getNumber();
      console.log(`Número final: ${finalNumber}`);
      
      console.log('\n=== Demonstração concluída ===');
      
    } catch (error) {
      console.error('Erro na demonstração:', error);
      throw error;
    }
  }
}
