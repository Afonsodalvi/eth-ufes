import { providerManager } from '../src/utils/provider.js';
import { CounterSimpleContract } from '../src/contracts/CounterSimpleContract.js';
import { config } from '../src/config/index.js';

/**
 * Exemplo usando sistema de polling manual (sem filtros)
 * Solução definitiva para o erro "filter not found"
 */
async function simpleEventsExample() {
  try {
    console.log('=== Exemplo de Eventos com Polling Manual ===\n');
    
    // Inicializa o provider
    await providerManager.initialize();
    
    if (!config.contracts.counter) {
      console.log('Endereço do contrato Counter não configurado');
      return;
    }
    
    const counter = new CounterSimpleContract(config.contracts.counter);
    await counter.initialize();
    
    console.log('Informações do contrato:', counter.getContractInfo());
    
    // Configura listener para eventos usando polling manual
    console.log('\n1. Configurando listener com polling manual...');
    
    let eventCount = 0;
    const maxEvents = 3;
    
    await counter.onNumberSet((args, event) => {
      eventCount++;
      const newNumber = args[0];
      console.log(`🎉 Evento NumberSet #${eventCount} recebido: ${newNumber}`);
      console.log(`   Bloco: ${event.blockNumber}, TX: ${event.transactionHash}`);
      
      // Para de escutar após receber o número máximo de eventos
      if (eventCount >= maxEvents) {
        console.log(`\n📊 Recebidos ${maxEvents} eventos. Parando de escutar...`);
        counter.stopListeningNumberSet().catch(console.error);
      }
    });
    
    // Executa operações que geram eventos
    console.log('\n2. Executando operações que geram eventos...');
    
    const operations = [
      () => counter.setNumber(1000),
      () => counter.increment(),
      () => counter.setNumber(2000),
      () => counter.increment(),
      () => counter.setNumber(3000)
    ];
    
    for (let i = 0; i < operations.length; i++) {
      console.log(`\nOperação ${i + 1}:`);
      try {
        await operations[i]();
        
        // Aguarda um pouco entre operações para os eventos serem processados
        await new Promise(resolve => setTimeout(resolve, 4000));
        
        // Lê o estado atual
        const currentNumber = await counter.getNumber();
        console.log(`Estado atual: ${currentNumber}`);
        
      } catch (error) {
        console.error(`Erro na operação ${i + 1}:`, error.message);
      }
    }
    
    // Aguarda um pouco mais para garantir que todos os eventos foram processados
    console.log('\n3. Aguardando processamento de eventos...');
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Limpa recursos
    console.log('\n4. Limpando recursos...');
    await counter.cleanup();
    
    console.log('\n=== Exemplo de polling manual concluído ===');
    
  } catch (error) {
    console.error('Erro no exemplo de polling manual:', error);
  }
}

/**
 * Exemplo de demonstração simples
 */
async function simpleDemoExample() {
  try {
    console.log('\n=== Demonstração Simples ===\n');
    
    await providerManager.initialize();
    
    if (!config.contracts.counter) {
      console.log('Endereço do contrato Counter não configurado');
      return;
    }
    
    const counter = new CounterSimpleContract(config.contracts.counter);
    await counter.initialize();
    
    // Configura listener
    await counter.onNumberSet((args, event) => {
      const newNumber = args[0];
      console.log(`🎉 Evento recebido: ${newNumber} (Bloco: ${event.blockNumber})`);
    });
    
    // Executa algumas operações
    console.log('Executando operações...');
    await counter.setNumber(5000);
    await counter.increment();
    await counter.setNumber(6000);
    
    // Aguarda processamento
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Limpa recursos
    await counter.cleanup();
    
    console.log('\n=== Demonstração simples concluída ===');
    
  } catch (error) {
    console.error('Erro na demonstração simples:', error);
  }
}

// Executa os exemplos se este arquivo for executado diretamente
if (import.meta.url === `file://${process.argv[1]}`) {
  simpleEventsExample()
    .then(() => simpleDemoExample())
    .catch(console.error);
}

export { simpleEventsExample, simpleDemoExample };
