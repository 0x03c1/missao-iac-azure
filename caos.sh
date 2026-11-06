#!/usr/bin/env bash
# ============================================================
#  MISSÃO 5 — O CAOS 🔥
#  Simula um ataque: apaga a página de UM servidor aleatório
#  "por fora" do Terraform (direto na Azure).
#  Só rode quando o professor der o sinal!
# ============================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=lib/comum.sh
source lib/comum.sh

CONTAS=()
SITES=()
while IFS= read -r linha; do [ -n "$linha" ] && CONTAS+=("$linha"); done < <(lista_output contas_de_armazenamento)
while IFS= read -r linha; do [ -n "$linha" ] && SITES+=("$linha"); done < <(lista_output sites)

if [ "${#CONTAS[@]}" -eq 0 ]; then
  falhar "Nenhum servidor para atacar… Você já completou as missões 2 a 4?"
fi

ALVO_IDX=$((RANDOM % ${#CONTAS[@]}))
ALVO="${CONTAS[$ALVO_IDX]}"
URL="${SITES[$ALVO_IDX]:-}"
NUMERO=$((ALVO_IDX + 1))

printf '%s' "$VERMELHO"
cat <<'EOF'

   ██████████████████████████████████████████████
   ██                                          ██
   ██   🚨  ALERTA DE SEGURANÇA  🚨              ██
   ██   Atividade suspeita detectada na nuvem! ██
   ██                                          ██
   ██████████████████████████████████████████████

EOF
for i in 3 2 1; do
  printf '   Invasão em %s...\n' "$i"
  sleep 1
done
printf '%s' "$RESET"

# shellcheck disable=SC2016  # '$web' é literal (nome do contêiner)
if ! az storage blob delete \
      --account-name "$ALVO" \
      --container-name '$web' \
      --name index.html \
      --auth-mode key \
      --only-show-errors >/dev/null 2>&1; then
  falhar "O ataque falhou (a página talvez já tenha sido apagada). Rode 'terraform plan' para ver o estado."
fi

{
  date '+%Y-%m-%d %H:%M:%S'
  echo "alvo=$ALVO servidor=$NUMERO"
} >> .caos_registro

printf '\n%s💀 O SERVIDOR #%s FOI DERRUBADO!%s\n' "$VERMELHO" "$NUMERO" "$RESET"
[ -n "$URL" ] && printf '   Veja o estrago (Ctrl+clique):  %s\n' "$URL"
printf '\n%s🛠️  SUA MISSÃO:%s\n' "$AMARELO" "$RESET"
echo "   1. Descubra o que sumiu:   terraform plan"
echo "   2. Conserte tudo:          terraform apply"
echo "   3. Confirme:               ./checkpoint.sh 5"
echo
