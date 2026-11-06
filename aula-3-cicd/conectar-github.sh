#!/usr/bin/env bash
# Aula 3, Missão 2: conecta o seu fork no GitHub ao mural da Aula 2.
# Guarda no GitHub a chave de publicação do app (segredo) e o nome do app (variável).
#
# Uso:
#   ./conectar-github.sh                 conecta
#   ./conectar-github.sh --desconectar   apaga o segredo e a variável (Missão 6)
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../lib/comum.sh
source ../lib/comum.sh

REPO_ORIGINAL="0x03c1/missao-iac-azure"

passo "1/4 Seu repositório no GitHub"
REPO=$(repo_github)
[ -n "$REPO" ] || falhar "Não encontrei o repositório git. Você clonou o seu fork?"
if [ "$REPO" = "$REPO_ORIGINAL" ]; then
  falhar "Esta pasta é o repositório do professor. Clone o SEU fork: git clone https://github.com/SEU-USUARIO/missao-iac-azure.git"
fi
ok "Repositório: $REPO"

passo "2/4 Login no GitHub"
if ! gh auth status >/dev/null 2>&1; then
  echo "  1. Aperte Enter quando o GitHub CLI pedir."
  echo "  2. Copie o código de 8 letras que vai aparecer."
  echo "  3. Abra https://github.com/login/device, cole o código e autorize."
  echo
  gh auth login --hostname github.com --git-protocol https --web || falhar "Login no GitHub não concluído."
fi
ok "Logado no GitHub como $(gh api user -q .login)"
gh repo view "$REPO" >/dev/null 2>&1 || falhar "Não encontrei $REPO no GitHub."

if [ "${1:-}" = "--desconectar" ]; then
  passo "Apagando o segredo e a variável do GitHub"
  if gh secret delete AZURE_WEBAPP_PUBLISH_PROFILE --repo "$REPO" 2>/dev/null; then
    ok "Segredo apagado"
  else
    ok "O segredo já não existia"
  fi
  if gh variable delete AZURE_WEBAPP_NAME --repo "$REPO" 2>/dev/null; then
    ok "Variável apagada"
  else
    ok "A variável já não existia"
  fi
  exit 0
fi

passo "3/4 Mural da Aula 2"
APP=$(terraform -chdir=../aula-2-banco output -raw nome_do_app 2>/dev/null)
RG=$(terraform -chdir=../aula-2-banco output -raw grupo_de_recursos 2>/dev/null)
[ -n "$APP" ] && [ -n "$RG" ] || falhar "O mural não existe. Faça a Missão 1 (terraform apply na pasta aula-2-banco)."
ok "App: $APP"

passo "4/4 Guardando a chave de publicação no GitHub"
PERFIL=$(az webapp deployment list-publishing-profiles --name "$APP" --resource-group "$RG" --xml --only-show-errors) \
  || falhar "Não consegui ler a chave de publicação do app. Chame o professor."
[ -n "$PERFIL" ] || falhar "A chave de publicação veio vazia. Chame o professor."
printf '%s' "$PERFIL" | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --repo "$REPO" \
  || falhar "Não consegui salvar o segredo no GitHub."
ok "Segredo AZURE_WEBAPP_PUBLISH_PROFILE salvo (o GitHub nunca mostra o valor)"
gh variable set AZURE_WEBAPP_NAME --repo "$REPO" --body "$APP" \
  || falhar "Não consegui salvar a variável no GitHub."
ok "Variável AZURE_WEBAPP_NAME = $APP"

printf '\n%sConectado.%s Acompanhe o pipeline em: https://github.com/%s/actions\n' "$VERDE" "$RESET" "$REPO"
printf 'Próximo passo: %s./checkpoint.sh 2%s\n\n' "$NEGRITO" "$RESET"
