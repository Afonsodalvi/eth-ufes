#!/bin/bash

# Script para aplicar patch nas libs do Uniswap V4
# Use este script após instalar v4-core e v4-periphery se houver erros de compatibilidade

set -e

echo "🔧 Aplicando patch nas libs do Uniswap V4..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se as libs existem
if [ ! -d "lib/v4-core/src" ]; then
    echo -e "${RED}❌ Erro: lib/v4-core/src não encontrado!${NC}"
    echo "Execute primeiro: forge install Uniswap/v4-core"
    exit 1
fi

# Verificar se PoolOperation.sol existe
if [ ! -f "lib/v4-core/src/types/PoolOperation.sol" ]; then
    echo -e "${YELLOW}⚠️  Criando lib/v4-core/src/types/PoolOperation.sol...${NC}"
    mkdir -p lib/v4-core/src/types
    cat > lib/v4-core/src/types/PoolOperation.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";

// Re-export structs for compatibility with v4-periphery BaseHook
// These structs must match IPoolManager.sol exactly
// Using the same struct definitions to ensure type compatibility

// Note: These structs are defined in IPoolManager.sol as IPoolManager.ModifyLiquidityParams
// and IPoolManager.SwapParams. This file provides standalone types for BaseHook compatibility.

struct ModifyLiquidityParams {
    int24 tickLower;
    int24 tickUpper;
    int256 liquidityDelta;
    bytes32 salt;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}
EOF
    echo -e "${GREEN}✅ PoolOperation.sol criado${NC}"
fi

# Patch 1: IHooks.sol
echo -e "${YELLOW}📝 Aplicando patch em IHooks.sol...${NC}"
IHOOKS_FILE="lib/v4-core/src/interfaces/IHooks.sol"

if [ -f "$IHOOKS_FILE" ]; then
    # Backup
    cp "$IHOOKS_FILE" "${IHOOKS_FILE}.bak"
    
    # Substituir import
    sed -i '' 's/import {IPoolManager} from "\.\/IPoolManager\.sol";/import {ModifyLiquidityParams, SwapParams} from "..\/types\/PoolOperation.sol";/g' "$IHOOKS_FILE"
    
    # Substituir tipos
    sed -i '' 's/IPoolManager\.ModifyLiquidityParams/ModifyLiquidityParams/g' "$IHOOKS_FILE"
    sed -i '' 's/IPoolManager\.SwapParams/SwapParams/g' "$IHOOKS_FILE"
    
    echo -e "${GREEN}✅ IHooks.sol atualizado${NC}"
else
    echo -e "${RED}❌ Erro: $IHOOKS_FILE não encontrado!${NC}"
    exit 1
fi

# Patch 2: Hooks.sol
echo -e "${YELLOW}📝 Aplicando patch em Hooks.sol...${NC}"
HOOKS_FILE="lib/v4-core/src/libraries/Hooks.sol"

if [ -f "$HOOKS_FILE" ]; then
    # Backup
    cp "$HOOKS_FILE" "${HOOKS_FILE}.bak"
    
    # Substituir import
    sed -i '' 's/import {IPoolManager} from "\.\.\/interfaces\/IPoolManager\.sol";/import {ModifyLiquidityParams, SwapParams} from "..\/types\/PoolOperation.sol";/g' "$HOOKS_FILE"
    
    # Substituir tipos
    sed -i '' 's/IPoolManager\.ModifyLiquidityParams/ModifyLiquidityParams/g' "$HOOKS_FILE"
    sed -i '' 's/IPoolManager\.SwapParams/SwapParams/g' "$HOOKS_FILE"
    
    echo -e "${GREEN}✅ Hooks.sol atualizado${NC}"
else
    echo -e "${RED}❌ Erro: $HOOKS_FILE não encontrado!${NC}"
    exit 1
fi

# Patch 3: PoolManager.sol (mais complexo, precisa de edição manual)
echo -e "${YELLOW}⚠️  PoolManager.sol requer edição manual${NC}"
echo -e "${YELLOW}   Veja SETUP_LIBS.md para instruções detalhadas${NC}"

echo ""
echo -e "${GREEN}✅ Patch aplicado com sucesso!${NC}"
echo -e "${YELLOW}⚠️  Nota: PoolManager.sol precisa de edição manual${NC}"
echo ""
echo "Próximos passos:"
echo "1. Edite lib/v4-core/src/PoolManager.sol conforme SETUP_LIBS.md"
echo "2. Execute: forge build --skip test/ --skip script/"
echo ""

