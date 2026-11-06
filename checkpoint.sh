#!/usr/bin/env bash
# ============================================================
#  CHECKPOINT — confere se a missão foi cumprida.
#  Uso:  ./checkpoint.sh 1   (… até 6)
#  Se der certo, aparece a PALAVRA-CÓDIGO para mostrar ao professor.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=lib/comum.sh
source lib/comum.sh

MISSAO="${1:-}"
[[ "$MISSAO" =~ ^[1-6]$ ]] || falhar "Use: ./checkpoint.sh NÚMERO   (de 1 a 6)"

medalha() { # $1 = título, $2 = palavra-código
  printf '\n%s' "$VERDE"
  echo "  ★━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━★"
  echo "     🏅  MISSÃO $MISSAO COMPLETA — $1"
  echo
  echo "     🔑  Palavra-código:  $2"
  echo
  echo "     ✋  Levante a mão e mostre esta tela!"
  echo "  ★━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━★"
  printf '%s\n' "$RESET"
}

# Confere se TODOS os sites respondem 200. Recebe a quantidade mínima.
conferir_sites() {
  local minimo="$1" urls url codigo total=0 falhas=0
  urls=$(lista_output sites)
  if [ -z "$urls" ]; then
    falhar "Ainda não existe nenhum site. Você já rodou 'terraform apply' e digitou yes?"
  fi
  while read -r url; do
    total=$((total + 1))
    codigo=$(status_http "$url")
    if [ "$codigo" = "200" ]; then
      ok "Servidor #$total no ar → $url"
    else
      erro "Servidor #$total NÃO respondeu (código $codigo) → $url"
      falhas=$((falhas + 1))
    fi
  done <<< "$urls"
  if [ "$total" -lt "$minimo" ]; then
    falhar "Encontrei $total servidor(es), mas a missão pede $minimo. Mudou o terraform.tfvars e rodou apply?"
  fi
  if [ "$falhas" -gt 0 ]; then
    falhar "Algum servidor está fora do ar. Rode 'terraform plan' para investigar."
  fi
}

case "$MISSAO" in
  1)
    az account show >/dev/null 2>&1 || falhar "Sem login na Azure. Você está no Cloud Shell?"
    ok "Login na Azure"
    command -v terraform >/dev/null || falhar "Terraform não encontrado"
    ok "Terraform instalado"
    [ -f azure.auto.tfvars ] || falhar "Falta rodar ./embarque.sh"
    ok "Embarque feito ($(grep regiao azure.auto.tfvars | cut -d'"' -f2))"
    medalha "Embarque" "NUVEM"
    ;;
  2)
    conferir_sites 1
    medalha "Primeiro site no ar" "DEPLOY"
    ;;
  3)
    NOME=$(terraform output -raw nome_da_dupla 2>/dev/null)
    if [ -z "$NOME" ] || [ "$NOME" = "Dupla Misteriosa" ]; then
      falhar "O site ainda usa o nome padrão. Mude nome_da_dupla no terraform.tfvars, salve e rode terraform apply."
    fi
    conferir_sites 1
    PRIMEIRO=$(lista_output sites | head -1)
    curl -s --max-time 15 "$PRIMEIRO" | grep -qF "$NOME" \
      || falhar "O site ainda não mostra \"$NOME\". Rodou terraform apply depois de salvar?"
    ok "O site mostra \"$NOME\""
    medalha "Personalizado" "ESTILO"
    ;;
  4)
    conferir_sites 3
    medalha "Escalou" "ESCALA"
    ;;
  5)
    [ -f .caos_registro ] || falhar "O ataque ainda não aconteceu! Espere o sinal do professor e rode ./caos.sh"
    conferir_sites 1
    ok "Todos os servidores sobreviveram ao ataque"
    medalha "Sobreviveu ao caos" "FÊNIX"
    ;;
  6)
    [ -f terraform.tfstate ] || falhar "Não encontrei o estado do Terraform. Você está na pasta missao-iac-azure?"
    RESTANTES=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RESTANTES" != "0" ]; then
      falhar "Ainda existem $RESTANTES recurso(s). Rode 'terraform destroy' e digite yes."
    fi
    ok "O Terraform não gerencia mais nada"
    if [ "$(az group exists -n "$RG_NOME" 2>/dev/null)" = "true" ]; then
      falhar "O grupo $RG_NOME ainda existe na Azure. Rode 'terraform destroy' de novo."
    fi
    ok "Nada sobrou na Azure — custo zero 💸"
    medalha "Faxina completa" "FAXINA"
    ;;
esac
