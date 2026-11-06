#!/usr/bin/env bash
# ============================================================
#  MISSÃO 1 — EMBARQUE
#  Prepara o Azure Cloud Shell para a aula:
#    1. confere o login na Azure
#    2. confere o Terraform
#    3. descobre uma região PERMITIDA para a sua conta
#    4. registra o serviço de armazenamento
#    5. grava tudo em azure.auto.tfvars
#
#  Uso:  ./embarque.sh            (escolhe a região sozinho)
#        ./embarque.sh westus2    (força uma região)
# ============================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=lib/comum.sh
source lib/comum.sh

REGIAO_FORCADA="${1:-}"

printf '%s' "$AZUL"
cat <<'EOF'

        .-""""-.
       /  ☁️   \      M I S S Ã O :  S E R V I D O R E S
      |  IaC    |     ─────────────────────────────────
       \       /      Preparando a nave... 🚀
        '-....-'
EOF
printf '%s' "$RESET"

# ------------------------------------------------------------
passo "1/4  Conferindo seu login na Azure"
SUB_ID=$(az account show --query id -o tsv 2>/dev/null) \
  || falhar "Não encontrei login na Azure. Você está no Azure Cloud Shell (shell.azure.com)?"
SUB_NOME=$(az account show --query name -o tsv)
ok "Assinatura: ${NEGRITO}${SUB_NOME}${RESET}"
QTD_SUBS=$(az account list --query "length([?state=='Enabled'])" -o tsv 2>/dev/null || echo 1)
if [ "${QTD_SUBS:-1}" -gt 1 ]; then
  aviso "Você tem $QTD_SUBS assinaturas. Se esta NÃO for a da faculdade, rode:"
  echo "      az account list -o table"
  echo "      az account set --subscription \"NOME DA ASSINATURA\""
  echo "    e depois rode ./embarque.sh de novo."
fi

# ------------------------------------------------------------
passo "2/4  Conferindo o Terraform"
command -v terraform >/dev/null || falhar "Terraform não encontrado. Chame o professor."
ok "$(terraform -version | head -1)"

# ------------------------------------------------------------
passo "3/4  Descobrindo uma região permitida para a sua conta"

descobrir_regioes_permitidas() {
  # Contas de estudante têm uma política "Allowed resource deployment regions".
  # Aqui lemos essa política e devolvemos a lista de regiões permitidas.
  {
    az policy assignment list --disable-scope-strict-match -o json 2>/dev/null \
      || az policy assignment list -o json 2>/dev/null
  } | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
regioes = set()
for a in data:
    texto = ((a.get("displayName") or "") + " " + (a.get("name") or "")).lower()
    if not any(p in texto for p in ("location", "region", "local")):
        continue
    for p in (a.get("parameters") or {}).values():
        v = p.get("value") if isinstance(p, dict) else None
        if isinstance(v, list) and v and all(isinstance(x, str) for x in v):
            regioes.update(x.lower().replace(" ", "") for x in v)
regioes.discard("global")
print(" ".join(sorted(regioes)))
'
}

if [ -n "$REGIAO_FORCADA" ]; then
  REGIAO="$REGIAO_FORCADA"
  ok "Usando a região que você escolheu: ${NEGRITO}${REGIAO}${RESET}"
else
  PERMITIDAS=$(descobrir_regioes_permitidas)
  REGIAO=""
  if [ -n "$PERMITIDAS" ]; then
    ok "Regiões permitidas para você: $PERMITIDAS"
    for preferida in brazilsouth eastus eastus2 centralus southcentralus westus2 westus3 northeurope westeurope; do
      if [[ " $PERMITIDAS " == *" $preferida "* ]]; then REGIAO="$preferida"; break; fi
    done
    [ -z "$REGIAO" ] && REGIAO="${PERMITIDAS%% *}"
  else
    REGIAO="eastus"
    aviso "Não encontrei restrição de região. Vou usar eastus."
  fi
  ok "Região escolhida: ${NEGRITO}${REGIAO}${RESET}"
fi

# ------------------------------------------------------------
passo "4/4  Registrando o serviço de armazenamento (na 1ª vez pode levar até 2 min)"
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
# Gerado automaticamente pelo ./embarque.sh — não precisa editar.
subscription_id = "$SUB_ID"
regiao          = "$REGIAO"
EOF
ok "Configuração salva em azure.auto.tfvars"

printf '\n%s🚀 Nave pronta!%s Agora rode:  %s./checkpoint.sh 1%s\n\n' "$VERDE" "$RESET" "$NEGRITO" "$RESET"
