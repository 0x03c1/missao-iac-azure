#!/usr/bin/env bash
# Resgate: use somente se o professor pedir.
# Quando usar: o terminal reiniciou, o Terraform perdeu o estado e o apply
# reclama que algo "already exists".
# O que faz: apaga o grupo rg-missao-iac inteiro na Azure e limpa o estado local.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../lib/comum.sh
source ../lib/comum.sh

RG_NOME="rg-missao-iac"  # o mesmo nome de main.tf

aviso "Isto vai APAGAR o grupo ${NEGRITO}${RG_NOME}${RESET} inteiro e o estado do Terraform."
read -r -p "Digite SIM (maiúsculo) para continuar: " RESPOSTA
[ "$RESPOSTA" = "SIM" ] || { echo "Cancelado. Nada foi apagado."; exit 0; }

if [ "$(az group exists -n "$RG_NOME" 2>/dev/null)" = "true" ]; then
  passo "Apagando $RG_NOME na Azure (de 1 a 3 minutos)"
  az group delete -n "$RG_NOME" --yes --only-show-errors || falhar "Não consegui apagar. Chame o professor."
  ok "Grupo apagado"
else
  ok "O grupo $RG_NOME não existe na Azure"
fi

rm -f terraform.tfstate terraform.tfstate.backup .caos_registro
ok "Estado local limpo"

printf '\n%sResgate concluído.%s Próximo passo: %sterraform apply%s\n\n' "$VERDE" "$RESET" "$NEGRITO" "$RESET"
