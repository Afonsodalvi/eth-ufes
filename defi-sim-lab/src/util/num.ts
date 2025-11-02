/**
 * Helper para conversão de BigInt para string decimal
 * Necessário porque axios/JSON.stringify não serializa BigInt nativamente
 */
export const toDec = (x: bigint | number | string): string => {
  if (typeof x === 'bigint') {
    return x.toString();
  }
  return String(x);
};

// Mantido para compatibilidade (usa toDec internamente)
export const asDec = toDec;