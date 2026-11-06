#!/usr/bin/env bash
# Missão 1: prepara o terminal para a aula.
#   1. confere o login na Azure
#   2. confere o Terraform
#   3. descobre uma região permitida para a conta
#   4. registra o serviço de armazenamento
#   5. grava a configuração em azure.auto.tfvars
#
# Uso:
#   ./embarque.sh           escolhe a região automaticamente
#   ./embarque.sh westus2   força uma região
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=lib/comum.sh
source lib/comum.sh

REGIAO_FORCADA="${1:-}"
REGIOES_PREFERIDAS="brazilsouth eastus eastus2 centralus southcentralus westus2 westus3 northeurope westeurope"

printf '\n%sMISSÃO: SERVIDORES SOB ATAQUE%s\n' "$NEGRITO" "$RESET"
printf 'Preparando o terminal (%s)...\n' "$(ambiente)"

# ------------------------------------------------------------
passo "1/4 Login na Azure"
if ! SUB_ID=$(az account show --query id -o tsv 2>/dev/null); then
  erro "Você ainda não está logado na Azure."
  if [ "$(ambiente)" = "cloudshell" ]; then
    falhar "Feche e abra o Cloud Shell novamente. Se persistir, chame o professor."
  fi
  echo "  Rode o comando abaixo, siga as instruções e depois rode ./embarque.sh de novo:"
  echo
  echo "    az login --use-device-code"
  echo
  exit 1
fi
SUB_NOME=$(az account show --query name -o tsv)
ok "Assinatura: ${NEGRITO}${SUB_NOME}${RESET}"

QTD_SUBS=$(az account list --query "length([?state=='Enabled'])" -o tsv 2>/dev/null || echo 1)
if [ "${QTD_SUBS:-1}" -gt 1 ]; then
  aviso "Você tem $QTD_SUBS assinaturas. Se esta não for a da faculdade, rode:"
  echo "    az account list -o table"
  echo "    az account set --subscription \"NOME DA ASSINATURA\""
  echo "  e depois rode ./embarque.sh de novo."
fi

# ------------------------------------------------------------
passo "2/4 Terraform"
command -v terraform >/dev/null || falhar "Terraform não encontrado. Chame o professor."
ok "$(terraform -version | head -1)"

# ------------------------------------------------------------
passo "3/4 Região permitida para a sua conta"

# Contas de estudante têm uma política que limita as regiões permitidas.
# Lemos todos os valores de parâmetros das políticas da assinatura e
# mantemos só os que são nomes de região válidos.
regioes_permitidas() {
  local candidatas validas regiao
  candidatas=$(az policy assignment list --disable-scope-strict-match true \
                 --query "[].parameters.*.value[][]" -o tsv 2>/dev/null \
               || az policy assignment list --query "[].parameters.*.value[][]" -o tsv 2>/dev/null)
  [ -z "$candidatas" ] && return 0
  validas=$(az account list-locations --query "[].name" -o tsv 2>/dev/null)
  for regiao in $candidatas; do
    regiao="${regiao,,}"
    [ "$regiao" = "global" ] && continue
    grep -qx "$regiao" <<< "$validas" && echo "$regiao"
  done | sort -u | tr '\n' ' '
}

if [ -n "$REGIAO_FORCADA" ]; then
  REGIAO="$REGIAO_FORCADA"
  ok "Usando a região informada: ${NEGRITO}${REGIAO}${RESET}"
else
  PERMITIDAS=$(regioes_permitidas)
  PERMITIDAS="${PERMITIDAS% }"
  REGIAO=""
  if [ -n "$PERMITIDAS" ]; then
    ok "Regiões permitidas: $PERMITIDAS"
    for preferida in $REGIOES_PREFERIDAS; do
      if [[ " $PERMITIDAS " == *" $preferida "* ]]; then REGIAO="$preferida"; break; fi
    done
    [ -z "$REGIAO" ] && REGIAO="${PERMITIDAS%% *}"
  else
    REGIAO="eastus"
    aviso "Nenhuma restrição de região encontrada. Usando eastus."
  fi
  ok "Região escolhida: ${NEGRITO}${REGIAO}${RESET}"
fi

# ------------------------------------------------------------
passo "4/4 Serviço de armazenamento (na primeira vez pode levar até 2 min)"
ESTADO=$(az provider show --namespace Microsoft.Storage --query registrationState -o tsv 2>/dev/null)
if [ "$ESTADO" = "Registered" ]; then
  ok "Microsoft.Storage já estava registrado"
else
  az provider register --namespace Microsoft.Storage --wait --only-show-errors \
    || falhar "Não consegui registrar Microsoft.Storage. Chame o professor."
  ok "Microsoft.Storage registrado"
fi

# ------------------------------------------------------------
cat > azure.auto.tfvars <<EOF
# Gerado pelo ./embarque.sh. Não precisa editar.
subscription_id = "$SUB_ID"
regiao          = "$REGIAO"
EOF
ok "Configuração salva em azure.auto.tfvars"

printf '\n%sTerminal pronto.%s Próximo passo: %s./checkpoint.sh 1%s\n\n' "$VERDE" "$RESET" "$NEGRITO" "$RESET"
