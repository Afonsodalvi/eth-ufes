#!/bin/bash
# Script simples para executar Slither apenas nos arquivos em src/
# Ignora completamente a lib para evitar problemas de compilação

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Executando Slither apenas em src/ (ignorando lib/)..."
echo ""

# Encontrar todos os arquivos .sol em src/
SOL_FILES=$(find "$PROJECT_ROOT/src" -name "*.sol" -type f)

if [ -z "$SOL_FILES" ]; then
    echo "❌ Nenhum arquivo .sol encontrado em src/"
    exit 1
fi

echo "📁 Arquivos encontrados:"
echo "$SOL_FILES" | sed 's|^|  - |'
echo ""

# Executar Slither em cada arquivo individualmente
# Isso evita problemas de compilação com dependências da lib
for file in $SOL_FILES; do
    echo "🔍 Analisando: $file"
    slither "$file" --ignore-compile --filter-paths "lib/" 2>&1 | grep -v "lib/" || true
    echo ""
done

echo "✅ Análise concluída!"

