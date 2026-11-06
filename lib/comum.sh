# shellcheck shell=bash
# Funções compartilhadas pelos scripts da missão. Não precisa rodar este arquivo.

VERMELHO=$'\e[1;31m'
VERDE=$'\e[1;32m'
AMARELO=$'\e[1;33m'
AZUL=$'\e[1;36m'
NEGRITO=$'\e[1m'
RESET=$'\e[0m'

# Mesmo nome usado em main.tf (azurerm_resource_group.missao)
RG_NOME="rg-missao-iac"

ok()     { printf '%s✔%s %s\n' "$VERDE" "$RESET" "$*"; }
aviso()  { printf '%s⚠%s %s\n' "$AMARELO" "$RESET" "$*"; }
erro()   { printf '%s✘%s %s\n' "$VERMELHO" "$RESET" "$*"; }
passo()  { printf '\n%s▶ %s%s\n' "$AZUL" "$*" "$RESET"; }
falhar() { erro "$*"; exit 1; }

# Lista (uma por linha) um output do Terraform do tipo lista.
lista_output() {
  terraform output -json "$1" 2>/dev/null \
    | python3 -c 'import json,sys
try:
    for item in json.load(sys.stdin): print(item)
except Exception:
    pass'
}

# Código HTTP de uma URL (ex.: 200, 404).
status_http() {
  curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$1"
}
