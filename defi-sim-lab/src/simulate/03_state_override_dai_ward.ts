import 'dotenv/config';
import axios from 'axios';
import { keccak256, padHex } from 'viem';

const { TENDERLY_ACCOUNT, TENDERLY_PROJECT, TENDERLY_KEY } = process.env;

// exemplo didático do doc: tornar um endereço "ward" no DAI para poder mintar
const DAI = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const FAKE_WARD = '0xe2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2';
const WARDS_SLOT = 0n; // mapeamento wards no slot 0

// storage slot de wards[FAKE_WARD] = keccak256( pad(FAKE_WARD,32) ++ pad(slot,32) )
function calcStorageSlot(addr: `0x${string}`, slot: bigint): `0x${string}` {
  const addrPadded = padHex(addr, { size: 32 });
  const slotPadded = padHex(`0x${slot.toString(16)}`, { size: 32 });
  const combined = `0x${addrPadded.slice(2)}${slotPadded.slice(2)}`;
  return keccak256(combined as `0x${string}`);
}

(async () => {
  console.log('🔐 Demonstração: State Override - DAI Wards\n');
  console.log('Cenário: Tornar um endereço arbitrário "ward" (admin) via override\n');
  
  const storageKey = calcStorageSlot(FAKE_WARD as `0x${string}`, WARDS_SLOT);
  const simulateUrl = `https://api.tenderly.co/api/v1/account/${TENDERLY_ACCOUNT}/project/${TENDERLY_PROJECT}/simulate`;

  // input = mint(address,uint256) - função do DAI que requer ward
  // Função mint() do DAI: 0x40c10f19 + address (32 bytes) + amount (32 bytes)
  const mintAmount = BigInt('1000000000000000000000'); // 1000 DAI
  const input = 
    '0x40c10f19' + // função mint(address,uint256)
    FAKE_WARD.slice(2).padStart(64, '0') + // recipient address
    mintAmount.toString(16).padStart(64, '0'); // amount

  console.log(`📍 Storage slot calculado: ${storageKey}`);
  console.log(`   wards[${FAKE_WARD}] será definido como 1 (ativo)\n`);

  try {
    const res = await axios.post(simulateUrl, {
      save: true,
      save_if_fails: true,
      simulation_type: 'full',
      network_id: '1',
      from: FAKE_WARD,
      to: DAI,
      input,
      gas: 8_000_000,
      state_objects: {
        [DAI]: {
          storage: {
            [storageKey]: '0x' + '01'.padStart(64, '0') // wards[FAKE_WARD] = 1
          }
        }
      }
    }, {
      headers: { 'X-Access-Key': TENDERLY_KEY! }
    });

    console.log('=== RESULTADO DA SIMULAÇÃO ===\n');
    const transaction = res.data.transaction || res.data;
    const status = transaction.status !== false && transaction.status !== 0;
    console.log(`Status: ${status ? '✅ Sucesso' : '❌ Falhou'}`);
    console.log(`Gas usado: ${transaction.gas_used || 'N/A'}\n`);
    
    const simulation = res.data.simulation || res.data;
    const assetChanges = simulation?.asset_changes || [];
    
    if (assetChanges.length > 0) {
      console.log('Mudanças de Assets:');
      assetChanges.forEach((change: any) => {
        if (change.asset?.symbol === 'DAI') {
          console.log(`  ${change.address}: ${change.delta || '0'} DAI`);
        }
      });
    } else {
      console.log('(Nenhuma mudança de asset detectada)');
    }
    
    console.log('\n💡 Observação: Esta simulação só funciona com override!');
    console.log('   Na mainnet real, FAKE_WARD não tem permissão para mintar.\n');
    
  } catch (error: any) {
    console.error('❌ Erro na simulação:', error.response?.data || error.message);
  }
})();
