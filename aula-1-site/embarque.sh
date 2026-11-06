#!/usr/bin/env bash
# Aula 1, Missão 1: prepara o terminal.
# Uso:
#   ./embarque.sh           escolhe a região automaticamente
#   ./embarque.sh westus2   força uma região
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../lib/comum.sh
source ../lib/comum.sh
# shellcheck source=../lib/embarque.sh
source ../lib/embarque.sh

embarcar "${1:-}" Microsoft.Storage
