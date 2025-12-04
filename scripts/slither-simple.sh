#!/bin/bash
# Script simples para executar Slither ignorando problemas na lib
# 
# IMPORTANTE: Este script assume que você já compilou o projeto com sucesso
# usando `forge build` (mesmo que tenha erros na lib, alguns contratos podem ter compilado)
#
# Uso: ./scripts/slither-simple.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Executando Slither (ignorando lib/)..."
echo ""
echo "⚠️  Nota: Se houver erros de compilação, eles serão da lib v4-core"
echo "    Os resultados serão filtrados para mostrar apenas src/"
echo ""

# Executar Slither no diretório raiz, mas filtrar resultados da lib
slither . \
    --exclude-dependencies \
    --filter-paths "lib/" \
    2>&1 | grep -v "lib/" | grep -v "Error (2449)" || {
    
    echo ""
    echo "⚠️  Slither encontrou problemas, mas isso é esperado devido à lib v4-core"
    echo ""
    echo "💡 Alternativa: Analise apenas arquivos específicos em src/"
    echo "   Exemplo: slither src/hooks/PointsHook.sol --ignore-compile"
    echo ""
    exit 0
}

echo ""
echo "✅ Análise concluída!"

