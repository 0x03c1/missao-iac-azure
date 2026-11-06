#!/usr/bin/env bash
# Confere se a missão foi cumprida e mostra a palavra-código.
# Uso: ./checkpoint.sh 1   (de 1 a 6)
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=lib/comum.sh
source lib/comum.sh

MISSAO="${1:-}"
[[ "$MISSAO" =~ ^[1-6]$ ]] || falhar "Use: ./checkpoint.sh NÚMERO (de 1 a 6)"

medalha() { # $1 = título, $2 = palavra-código
  printf '\n%s' "$VERDE"
  echo "  =================================================="
  echo "    MISSÃO $MISSAO COMPLETA: $1"
  echo
  echo "    Palavra-código: $2"
  echo
  echo "    Levante a mão e mostre esta tela ao professor."
  echo "  =================================================="
  printf '%s\n' "$RESET"
}

# Confere se todos os sites respondem 200. $1 = quantidade mínima de sites.
conferir_sites() {
  local minimo="$1" urls url codigo total=0 falhas=0
  urls=$(lista_output sites)
  [ -n "$urls" ] || falhar "Nenhum site encontrado. Você já rodou 'terraform apply' e digitou yes?"
  while read -r url; do
    total=$((total + 1))
    codigo=$(status_http "$url")
    if [ "$codigo" = "200" ]; then
      ok "Servidor $total no ar: $url"
    else
      erro "Servidor $total fora do ar (código $codigo): $url"
      falhas=$((falhas + 1))
    fi
  done <<< "$urls"
  [ "$total" -ge "$minimo" ] \
    || falhar "Encontrei $total servidor(es), a missão pede $minimo. Mudou o terraform.tfvars e rodou apply?"
  [ "$falhas" -eq 0 ] || falhar "Há servidor fora do ar. Rode 'terraform plan' para investigar."
}

case "$MISSAO" in
  1)
    az account show >/dev/null 2>&1 || falhar "Sem login na Azure. Rode ./embarque.sh e siga as instruções."
    ok "Login na Azure"
    command -v terraform >/dev/null || falhar "Terraform não encontrado."
    ok "Terraform instalado"
    [ -f azure.auto.tfvars ] || falhar "Falta rodar ./embarque.sh"
    ok "Embarque feito (região $(grep regiao azure.auto.tfvars | cut -d'"' -f2))"
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
    [ -f .caos_registro ] || falhar "O ataque ainda não aconteceu. Espere o sinal do professor e rode ./caos.sh"
    conferir_sites 1
    ok "Todos os servidores sobreviveram ao ataque"
    medalha "Sobreviveu ao caos" "FÊNIX"
    ;;
  6)
    [ -f terraform.tfstate ] || falhar "Estado do Terraform não encontrado. Você está na pasta missao-iac-azure?"
    RESTANTES=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    [ "$RESTANTES" = "0" ] || falhar "Ainda existem $RESTANTES recurso(s). Rode 'terraform destroy' e digite yes."
    ok "O Terraform não gerencia mais nada"
    if [ "$(az group exists -n "$RG_NOME" 2>/dev/null)" = "true" ]; then
      falhar "O grupo $RG_NOME ainda existe na Azure. Rode 'terraform destroy' de novo."
    fi
    ok "Nada sobrou na Azure: custo zero"
    medalha "Faxina completa" "FAXINA"
    ;;
esac
