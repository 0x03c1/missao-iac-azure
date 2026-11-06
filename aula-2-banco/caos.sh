#!/usr/bin/env bash
# Aula 2: o APAGÃO.
# Reinicia o servidor do mural e confere se as mensagens sobreviveram.
# Só rode quando o professor der o sinal.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../lib/comum.sh
source ../lib/comum.sh

URL=$(terraform output -raw endereco_do_mural 2>/dev/null)
APP=$(terraform output -raw nome_do_app 2>/dev/null)
RG=$(terraform output -raw grupo_de_recursos 2>/dev/null)
[ -n "$URL" ] && [ -n "$APP" ] || falhar "O mural ainda não existe. Você já completou a Missão 2?"

passo "Lendo o estado do mural antes do apagão"
[ "$(status_http "$URL/saude" 36)" = "200" ] || falhar "O mural não está respondendo. Espere 1 minuto e tente de novo."
ANTES=$(curl -s --max-time 20 "$URL/saude")
TOTAL_ANTES=$(campo_json "$ANTES" total)
LIGADO_ANTES=$(campo_json "$ANTES" iniciado_em)
PERSISTENTE=$(campo_json "$ANTES" persistente)
ok "Mensagens no banco: $TOTAL_ANTES (banco persistente: $PERSISTENTE)"

printf '\n%s' "$VERMELHO"
echo "  =================================================="
echo "    APAGÃO NA REDE"
echo "    O servidor do mural vai ser desligado e religado."
echo "  =================================================="
printf '%s' "$RESET"
az webapp restart --name "$APP" --resource-group "$RG" --only-show-errors \
  || falhar "Não consegui reiniciar o app. Chame o professor."

passo "Esperando o servidor voltar (até 3 minutos)"
DEPOIS=""
for _ in $(seq 1 36); do
  sleep 5
  RESPOSTA=$(curl -s --max-time 20 "$URL/saude")
  LIGADO=$(campo_json "$RESPOSTA" iniciado_em)
  if [ -n "$LIGADO" ] && [ "$LIGADO" != "$LIGADO_ANTES" ]; then DEPOIS="$RESPOSTA"; break; fi
  printf '.'
done
echo
[ -n "$DEPOIS" ] || falhar "O servidor ainda não voltou. Espere 1 minuto e abra o mural no navegador."
TOTAL_DEPOIS=$(campo_json "$DEPOIS" total)

{
  date '+%Y-%m-%d %H:%M:%S'
  echo "persistente=$PERSISTENTE antes=$TOTAL_ANTES depois=$TOTAL_DEPOIS ligado_em=$(campo_json "$DEPOIS" iniciado_em)"
} >> .apagao_registro
[ "$PERSISTENTE" = "nao" ] && cp .apagao_registro .experimento_registro

ok "Servidor religado"
printf '\n  Mensagens antes do apagão:  %s\n  Mensagens depois do apagão: %s\n\n' "$TOTAL_ANTES" "$TOTAL_DEPOIS"
if [ "${TOTAL_DEPOIS:-0}" -ge "${TOTAL_ANTES:-0}" ] && [ "${TOTAL_ANTES:-0}" -gt 0 ]; then
  printf '%sO banco sobreviveu ao apagão.%s Por quê? Pense em ONDE o arquivo do banco está.\n' "$VERDE" "$RESET"
else
  printf '%sAs mensagens sumiram!%s Onde o banco estava guardado? (dica: veja o rodapé do mural)\n' "$VERMELHO" "$RESET"
fi
echo "  Abra o mural: $URL"
echo
