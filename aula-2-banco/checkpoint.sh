#!/usr/bin/env bash
# Confere se a missão da Aula 2 foi cumprida e mostra a palavra-código.
# Uso: ./checkpoint.sh 1   (de 1 a 6)
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../lib/comum.sh
source ../lib/comum.sh

RG_NOME="rg-missao-banco"  # o mesmo nome de main.tf
MISSAO="${1:-}"
[[ "$MISSAO" =~ ^[1-6]$ ]] || falhar "Use: ./checkpoint.sh NÚMERO (de 1 a 6)"

URL=$(terraform output -raw endereco_do_mural 2>/dev/null)

# Lê /saude, esperando o app "acordar" (até 3 minutos).
ler_saude() {
  [ -n "$URL" ] || falhar "O mural ainda não existe. Você já rodou 'terraform apply' e digitou yes?"
  local codigo
  codigo=$(status_http "$URL/saude" 36)
  [ "$codigo" = "200" ] || falhar "O mural não respondeu (código $codigo). Espere 1 minuto e rode o checkpoint de novo."
  SAUDE=$(curl -s --max-time 20 "$URL/saude")
  TOTAL=$(campo_json "$SAUDE" total)
  PERSISTENTE=$(campo_json "$SAUDE" persistente)
  ok "Mural no ar: $URL"
  ok "Mensagens no banco: $TOTAL (banco persistente: $PERSISTENTE)"
}

case "$MISSAO" in
  1)
    az account show >/dev/null 2>&1 || falhar "Sem login na Azure. Rode ./embarque.sh e siga as instruções."
    ok "Login na Azure"
    command -v terraform >/dev/null || falhar "Terraform não encontrado."
    ok "Terraform instalado"
    [ -f azure.auto.tfvars ] || falhar "Falta rodar ./embarque.sh"
    ok "Embarque feito (região $(grep regiao azure.auto.tfvars | cut -d'"' -f2))"
    medalha "$MISSAO" "Embarque" "CONEXÃO"
    ;;
  2)
    ler_saude
    medalha "$MISSAO" "Mural no ar" "MURAL"
    ;;
  3)
    ler_saude
    [ "${TOTAL:-0}" -ge 3 ] || falhar "O banco tem $TOTAL mensagem(ns). A missão pede pelo menos 3. Escrevam no mural!"
    medalha "$MISSAO" "Dados gravados" "MEMÓRIA"
    ;;
  4)
    [ -f .apagao_registro ] || falhar "O apagão ainda não aconteceu. Espere o sinal do professor e rode ./caos.sh"
    ler_saude
    grep -q "persistente=sim" .apagao_registro || falhar "Rode o ./caos.sh com o banco persistente (banco_persistente = true)."
    [ "${TOTAL:-0}" -ge 3 ] || falhar "O banco tem $TOTAL mensagem(ns). Escreva até ter 3 e rode ./caos.sh de novo."
    ok "As mensagens sobreviveram ao apagão"
    medalha "$MISSAO" "Sobreviveu ao apagão" "PERSISTE"
    ;;
  5)
    [ -f .experimento_registro ] \
      || falhar "Falta o experimento: mude banco_persistente para false, rode terraform apply, escreva uma mensagem e rode ./caos.sh"
    ok "Experimento com o banco em /tmp registrado"
    ler_saude
    [ "$PERSISTENTE" = "sim" ] \
      || falhar "Agora volte banco_persistente para true no terraform.tfvars e rode terraform apply."
    [ "${TOTAL:-0}" -ge 3 ] || falhar "O banco tem $TOTAL mensagem(ns). As mensagens antigas deveriam ter voltado. Chame o professor."
    ok "As mensagens antigas voltaram: o arquivo em /home estava lá o tempo todo"
    medalha "$MISSAO" "Experimento concluído" "ARQUIVO"
    ;;
  6)
    [ -f terraform.tfstate ] || falhar "Estado do Terraform não encontrado. Você está na pasta aula-2-banco?"
    RESTANTES=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    [ "$RESTANTES" = "0" ] || falhar "Ainda existem $RESTANTES recurso(s). Rode 'terraform destroy' e digite yes."
    ok "O Terraform não gerencia mais nada"
    if [ "$(az group exists -n "$RG_NOME" 2>/dev/null)" = "true" ]; then
      falhar "O grupo $RG_NOME ainda existe na Azure. Rode 'terraform destroy' de novo."
    fi
    ok "Nada sobrou na Azure"
    medalha "$MISSAO" "Faxina completa" "FAXINA"
    ;;
esac
