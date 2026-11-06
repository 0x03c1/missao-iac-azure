# shellcheck shell=bash
# shellcheck disable=SC2034  # variáveis usadas pelos scripts que carregam este arquivo
# Funções compartilhadas pelos scripts da missão. Não precisa rodar este arquivo.
# Dependências: bash, terraform, az e curl (presentes no Cloud Shell e no Codespaces).

VERMELHO=$'\e[1;31m'
VERDE=$'\e[1;32m'
AMARELO=$'\e[1;33m'
AZUL=$'\e[1;36m'
NEGRITO=$'\e[1m'
RESET=$'\e[0m'

# Mesmo nome usado em main.tf (azurerm_resource_group.missao)
RG_NOME="rg-missao-iac"

ok()     { printf '%s✔%s %s\n' "$VERDE" "$RESET" "$*"; }
aviso()  { printf '%s!%s %s\n' "$AMARELO" "$RESET" "$*"; }
erro()   { printf '%s✘%s %s\n' "$VERMELHO" "$RESET" "$*"; }
passo()  { printf '\n%s> %s%s\n' "$AZUL" "$*" "$RESET"; }
falhar() { erro "$*"; exit 1; }

# Onde o script está rodando: cloudshell, codespaces ou local.
ambiente() {
  if [ -n "${ACC_CLOUD:-}" ] || [[ "${AZUREPS_HOST_ENVIRONMENT:-}" == cloud-shell* ]]; then
    echo cloudshell
  elif [ "${CODESPACES:-}" = "true" ]; then
    echo codespaces
  else
    echo local
  fi
}

# Imprime um output do Terraform do tipo lista, um item por linha.
# Os itens (URLs e nomes de storage) não têm vírgulas, aspas nem espaços.
lista_output() {
  local bruto
  bruto=$(terraform output -json "$1" 2>/dev/null | tr -d '[]" \n')
  [ -n "$bruto" ] && printf '%s\n' "${bruto//,/$'\n'}"
  return 0
}

# Código HTTP de uma URL (200, 404...).
status_http() {
  curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$1"
}
