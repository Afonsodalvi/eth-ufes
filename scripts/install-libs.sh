#!/bin/bash

# Script para instalar versões compatíveis das libs do Uniswap V4
# Este script garante que v4-core e v4-periphery sejam instalados em versões compatíveis

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Instalando bibliotecas Uniswap V4 (versões compatíveis)${NC}"
echo ""

# Versões testadas e compatíveis
# Se você encontrar versões que funcionam melhor, atualize aqui
V4_CORE_VERSION="v4.0.0"
V4_PERIPHERY_COMMIT="3779387"  # Commit específico que funciona com v4.0.0

# Verificar se estamos no diretório correto
if [ ! -f "foundry.toml" ]; then
    echo -e "${RED}❌ Erro: foundry.toml não encontrado!${NC}"
    echo "Execute este script a partir da raiz do projeto."
    exit 1
fi

# Remover libs antigas se existirem
if [ -d "lib/v4-core" ] || [ -d "lib/v4-periphery" ]; then
    echo -e "${YELLOW}⚠️  Removendo libs antigas...${NC}"
    rm -rf lib/v4-core lib/v4-periphery
    echo -e "${GREEN}✅ Libs antigas removidas${NC}"
fi

# Instalar v4-core com tag específica
echo -e "${BLUE}📦 Instalando v4-core@${V4_CORE_VERSION}...${NC}"
forge install Uniswap/v4-core@${V4_CORE_VERSION} 
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ v4-core instalado${NC}"
else
    echo -e "${RED}❌ Erro ao instalar v4-core${NC}"
    exit 1
fi

# Instalar v4-periphery com commit específico
echo -e "${BLUE}📦 Instalando v4-periphery@${V4_PERIPHERY_COMMIT}...${NC}"
forge install Uniswap/v4-periphery@${V4_PERIPHERY_COMMIT} 
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ v4-periphery instalado${NC}"
else
    echo -e "${RED}❌ Erro ao instalar v4-periphery${NC}"
    exit 1
fi

# Verificar se PoolOperation.sol existe (necessário para compatibilidade)
if [ ! -f "lib/v4-core/src/types/PoolOperation.sol" ]; then
    echo -e "${YELLOW}⚠️  Criando PoolOperation.sol para compatibilidade...${NC}"
    mkdir -p lib/v4-core/src/types
    cat > lib/v4-core/src/types/PoolOperation.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";

// Re-export structs for compatibility with v4-periphery BaseHook
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

# Tentar compilar para verificar compatibilidade
echo ""
echo -e "${BLUE}🔍 Verificando compatibilidade (compilando)...${NC}"
if forge build --skip test/ --skip script/ 2>&1 | grep -q "Compiler run failed"; then
    echo -e "${YELLOW}⚠️  Erros de compilação detectados${NC}"
    echo -e "${YELLOW}   Isso pode indicar incompatibilidade de versões${NC}"
    echo ""
    echo -e "${BLUE}💡 Solução:${NC}"
    echo "1. Execute: ./scripts/patch-libs.sh"
    echo "2. Edite PoolManager.sol conforme SETUP_LIBS.md"
    echo "3. Ou tente outras versões compatíveis"
    exit 1
else
    echo -e "${GREEN}✅ Compilação bem-sucedida! Versões são compatíveis.${NC}"
fi

echo ""
echo -e "${GREEN}✅ Instalação concluída com sucesso!${NC}"
echo ""
echo -e "${BLUE}📝 Versões instaladas:${NC}"
echo "  - v4-core: ${V4_CORE_VERSION}"
echo "  - v4-periphery: ${V4_PERIPHERY_COMMIT}"
echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo "  1. Se houver erros, execute: ./scripts/patch-libs.sh"
echo "  2. Veja SETUP_LIBS.md para mais detalhes"

