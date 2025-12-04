#!/bin/bash
# Script para executar Slither ignorando problemas na lib v4-core
# Temporariamente move o arquivo problemático, compila, e depois restaura

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBLEMATIC_FILE="$PROJECT_ROOT/lib/v4-core/src/interfaces/IPoolManager.sol"
BACKUP_FILE="$PROJECT_ROOT/lib/v4-core/src/interfaces/IPoolManager.sol.bak"

echo "🔍 Preparando ambiente para análise do Slither..."

# Verificar se o arquivo problemático existe
if [ ! -f "$PROBLEMATIC_FILE" ]; then
    echo "❌ Arquivo não encontrado: $PROBLEMATIC_FILE"
    exit 1
fi

# Fazer backup do arquivo problemático
if [ ! -f "$BACKUP_FILE" ]; then
    echo "📦 Fazendo backup do arquivo problemático..."
    cp "$PROBLEMATIC_FILE" "$BACKUP_FILE"
fi

# Criar um stub temporário que não causa erro de compilação
echo "🔧 Criando stub temporário..."
cat > "$PROBLEMATIC_FILE" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Stub temporário para permitir compilação do Slither
// Este arquivo será restaurado após a análise

import {IProtocolFees} from "./IProtocolFees.sol";
import {IERC6909Claims} from "./external/IERC6909Claims.sol";
import {IExtsload} from "./IExtsload.sol";
import {IExttload} from "./IExttload.sol";
import {Currency} from "../types/Currency.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {PoolId} from "../types/PoolId.sol";
import {IHooks} from "./IHooks.sol";

/// @notice Interface for the PoolManager (stub para análise)
interface IPoolManager is IProtocolFees, IERC6909Claims, IExtsload, IExttload {
    // Stub mínimo - apenas declaração da interface sem implementação completa
    // Isso permite que o Slither compile o projeto sem erros
}
EOF

# Compilar com Foundry primeiro
echo "🔨 Compilando projeto..."
if forge build --skip "*/test/**" --skip "*/script/**" 2>&1 | tee /tmp/forge_build.log; then
    echo "✅ Compilação bem-sucedida!"
    
    # Executar Slither usando artefatos já compilados
    echo "🔍 Executando Slither em src/ (ignorando lib/)..."
    slither . --foundry-ignore-compile --filter-paths "lib/" --exclude-dependencies 2>&1 | grep -v "lib/" || true
    
    echo ""
    echo "✅ Análise concluída!"
else
    echo "⚠️  Compilação falhou. Verificando log..."
    tail -10 /tmp/forge_build.log
    echo ""
    echo "💡 Dica: O erro está na lib v4-core, mas você pode analisar apenas src/ manualmente"
fi

# Restaurar arquivo original
echo "🔄 Restaurando arquivo original..."
if [ -f "$BACKUP_FILE" ]; then
    mv "$BACKUP_FILE" "$PROBLEMATIC_FILE"
    echo "✅ Arquivo restaurado!"
else
    echo "⚠️  Backup não encontrado, arquivo pode estar modificado"
fi

echo ""
echo "✨ Processo concluído!"

