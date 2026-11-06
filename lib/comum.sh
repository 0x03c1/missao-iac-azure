# shellcheck shell=bash
# shellcheck disable=SC2034  # variáveis usadas pelos scripts que carregam este arquivo
# Funções compartilhadas pelos scripts das aulas. Não precisa rodar este arquivo.
# Dependências: bash, terraform, az, curl e gh (presentes no Cloud Shell).

VERMELHO=$'\e[1;31m'
VERDE=$'\e[1;32m'
AMARELO=$'\e[1;33m'
AZUL=$'\e[1;36m'
NEGRITO=$'\e[1m'
RESET=$'\e[0m'

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
# Os itens (URLs e nomes de recursos) não têm vírgulas, aspas nem espaços.
lista_output() {
  local bruto
  bruto=$(terraform output -json "$1" 2>/dev/null | tr -d '[]" \n')
  [ -n "$bruto" ] && printf '%s\n' "${bruto//,/$'\n'}"
  return 0
}

# Código HTTP de uma URL (200, 404...).
# Um site recém-criado ou "acordando" pode demorar a responder (000, 502, 503, 504):
# nesse caso tenta de novo a cada 5 segundos. $2 = número de tentativas (padrão 6).
status_http() {
  local url="$1" tentativas="${2:-6}" codigo tentativa
  for ((tentativa = 1; tentativa <= tentativas; tentativa++)); do
    codigo=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$url")
    case "$codigo" in
      000|502|503|504) [ "$tentativa" -lt "$tentativas" ] && sleep 5 ;;
      *) break ;;
    esac
  done
  echo "$codigo"
}

# Lê um campo simples (texto ou número) de um JSON de uma linha, sem jq.
# Uso: campo_json '{"total":3}' total   ->  3
campo_json() {
  local valor
  valor=$(printf '%s' "$1" | grep -o "\"$2\": *\"\{0,1\}[^\",}]*" | head -1 | sed -E "s/\"$2\": *\"?//")
  printf '%s' "$valor"
}

# Quadro de missão cumprida. $1 = número, $2 = título, $3 = palavra-código.
medalha() {
  printf '\n%s' "$VERDE"
  echo "  =================================================="
  echo "    MISSÃO $1 COMPLETA: $2"
  echo
  echo "    Palavra-código: $3"
  echo
  echo "    Levante a mão e mostre esta tela ao professor."
  echo "  =================================================="
  printf '%s\n' "$RESET"
}

# Repositório GitHub (dono/nome) de onde esta pasta foi clonada.
repo_github() {
  git -C "$(dirname "${BASH_SOURCE[0]}")/.." remote get-url origin 2>/dev/null \
    | sed -E 's#^(https://github.com/|git@github.com:)##; s#\.git$##'
}
