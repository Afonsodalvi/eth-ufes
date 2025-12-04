#!/bin/bash

# Script wrapper para compilar ignorando PoolManager da lib
# Este script move temporariamente o PoolManager da lib para evitar erros de compilação

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

POOL_MANAGER_LIB="lib/v4-core/src/PoolManager.sol"
POOL_MANAGER_BACKUP="lib/v4-core/src/PoolManager.sol.backup"

echo -e "${BLUE}🔨 Compilando projeto (ignorando PoolManager da lib)...${NC}"

# Verificar se PoolManager existe na lib
if [ -f "$POOL_MANAGER_LIB" ]; then
    echo -e "${YELLOW}⚠️  Movendo PoolManager da lib temporariamente...${NC}"
    mv "$POOL_MANAGER_LIB" "$POOL_MANAGER_BACKUP"
    
    # Criar arquivo stub que re-exporta nossa versão do PoolManager
    cat > "$POOL_MANAGER_LIB" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Este arquivo é um stub que re-exporta nossa versão customizada do PoolManager
// O PoolManager original foi movido temporariamente para evitar erros de compilação
// Use: import {PoolManager} from "src/core/PoolManager.sol";

// Re-export da nossa versão customizada
import {PoolManager} from "../../../src/core/PoolManager.sol";
EOF
fi

# Executar forge build com os argumentos passados
if forge build "$@"; then
    echo -e "${GREEN}✅ Compilação bem-sucedida!${NC}"
    SUCCESS=true
else
    echo -e "${YELLOW}❌ Compilação falhou${NC}"
    SUCCESS=false
fi

# Restaurar PoolManager original
if [ -f "$POOL_MANAGER_BACKUP" ]; then
    echo -e "${YELLOW}🔄 Restaurando PoolManager original...${NC}"
    rm -f "$POOL_MANAGER_LIB"
    mv "$POOL_MANAGER_BACKUP" "$POOL_MANAGER_LIB"
fi

# Retornar código de saída apropriado
if [ "$SUCCESS" = true ]; then
    exit 0
else
    exit 1
fi

