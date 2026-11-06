#!/usr/bin/env bash
# Confere se a missão da Aula 3 foi cumprida e mostra a palavra-código.
# Uso: ./checkpoint.sh 1   (de 1 a 6)
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../lib/comum.sh
source ../lib/comum.sh

RG_NOME="rg-missao-banco"  # o mesmo nome de aula-2-banco/main.tf
REPO_ORIGINAL="0x03c1/missao-iac-azure"
MISSAO="${1:-}"
[[ "$MISSAO" =~ ^[1-6]$ ]] || falhar "Use: ./checkpoint.sh NÚMERO (de 1 a 6)"

REPO=$(repo_github)
URL=$(terraform -chdir=../aula-2-banco output -raw endereco_do_mural 2>/dev/null)

conferir_fork() {
  [ -n "$REPO" ] || falhar "Não encontrei o repositório git. Você clonou o seu fork?"
  [ "$REPO" != "$REPO_ORIGINAL" ] || falhar "Esta pasta é o repositório do professor. Clone o SEU fork."
  ok "Repositório: $REPO"
}

conferir_github() {
  gh auth status >/dev/null 2>&1 || falhar "Sem login no GitHub. Rode ./conectar-github.sh"
}

# Versão publicada no mural (o commit gravado pelo pipeline).
versao_no_ar() {
  [ -n "$URL" ] || falhar "O mural não existe. Faça a Missão 1."
  local codigo
  codigo=$(status_http "$URL/saude" 36)
  [ "$codigo" = "200" ] || falhar "O mural não respondeu (código $codigo). Espere 1 minuto e tente de novo."
  campo_json "$(curl -s --max-time 20 "$URL/saude")" versao
}

# Última execução do pipeline na main: "status|conclusão|commit".
# Enquanto roda, a conclusão vem vazia: por isso o separador é "|" e não espaço.
ultima_execucao() {
  gh run list --repo "$REPO" --workflow pipeline.yml --branch main --limit 1 \
    --json status,conclusion,headSha --jq '.[0] | "\(.status)|\(.conclusion)|\(.headSha)"' 2>/dev/null
}

case "$MISSAO" in
  1)
    conferir_fork
    [ -n "$URL" ] || falhar "O mural não existe. Rode terraform apply na pasta aula-2-banco."
    [ "$(status_http "$URL/saude" 36)" = "200" ] || falhar "O mural não respondeu. Espere 1 minuto e tente de novo."
    ok "Mural no ar: $URL"
    medalha "$MISSAO" "Base pronta" "FORK"
    ;;
  2)
    conferir_fork
    conferir_github
    gh secret list --repo "$REPO" 2>/dev/null | grep -q AZURE_WEBAPP_PUBLISH_PROFILE \
      || falhar "O segredo não está no GitHub. Rode ./conectar-github.sh"
    ok "Segredo AZURE_WEBAPP_PUBLISH_PROFILE configurado"
    APP=$(terraform -chdir=../aula-2-banco output -raw nome_do_app 2>/dev/null)
    [ "$(gh variable get AZURE_WEBAPP_NAME --repo "$REPO" 2>/dev/null)" = "$APP" ] \
      || falhar "A variável AZURE_WEBAPP_NAME não confere. Rode ./conectar-github.sh de novo."
    ok "Variável AZURE_WEBAPP_NAME = $APP"
    medalha "$MISSAO" "GitHub conectado à Azure" "CONECTADO"
    ;;
  3|5)
    conferir_fork
    conferir_github
    IFS="|" read -r STATUS CONCLUSAO COMMIT <<< "$(ultima_execucao)"
    [ -n "${COMMIT:-}" ] || falhar "Nenhuma execução do pipeline ainda. Faça o commit no arquivo config.py."
    [ "$STATUS" = "completed" ] || falhar "O pipeline ainda está rodando. Acompanhe na aba Actions e tente de novo."
    [ "$CONCLUSAO" = "success" ] || falhar "A última execução terminou com '$CONCLUSAO'. Veja o erro na aba Actions."
    ok "Pipeline verde no commit ${COMMIT:0:7}"
    VERSAO=$(versao_no_ar)
    [ "$VERSAO" = "${COMMIT:0:7}" ] \
      || falhar "O mural ainda mostra a versão '$VERSAO'. O App Service pode levar 1 ou 2 minutos para reiniciar; tente de novo."
    ok "O mural está na versão ${COMMIT:0:7}"
    if [ "$MISSAO" = "3" ]; then
      medalha "$MISSAO" "Primeiro deploy automático" "PIPELINE"
    else
      FALHAS=$(gh run list --repo "$REPO" --workflow pipeline.yml --branch main --limit 20 \
                 --json conclusion --jq '[.[] | select(.conclusion == "failure")] | length' 2>/dev/null)
      [ "${FALHAS:-0}" -ge 1 ] || falhar "Não encontrei a execução que falhou. Você fez a Missão 4?"
      ok "O pipeline barrou o erro e depois publicou a correção"
      medalha "$MISSAO" "Correção publicada" "VERDE"
    fi
    ;;
  4)
    conferir_fork
    conferir_github
    IFS="|" read -r STATUS CONCLUSAO COMMIT <<< "$(ultima_execucao)"
    [ "${STATUS:-}" = "completed" ] || falhar "O pipeline ainda está rodando (ou não rodou). Acompanhe na aba Actions."
    [ "$CONCLUSAO" = "failure" ] \
      || falhar "A última execução terminou com '$CONCLUSAO'. A missão é fazer os testes falharem: mude LIMITE_DE_CARACTERES para 0."
    ok "Os testes falharam no commit ${COMMIT:0:7} (como planejado)"
    VERSAO=$(versao_no_ar)
    [ "$VERSAO" != "${COMMIT:0:7}" ] || falhar "A versão com erro foi publicada. Isso não deveria acontecer: chame o professor."
    ok "O mural continua na versão anterior ($VERSAO): o pipeline protegeu a produção"
    medalha "$MISSAO" "O pipeline barrou o erro" "GUARDIÃO"
    ;;
  6)
    [ -f ../aula-2-banco/terraform.tfstate ] || falhar "Estado do Terraform não encontrado na pasta aula-2-banco."
    RESTANTES=$(terraform -chdir=../aula-2-banco state list 2>/dev/null | wc -l | tr -d ' ')
    [ "$RESTANTES" = "0" ] || falhar "Ainda existem $RESTANTES recurso(s). Rode 'terraform destroy' na pasta aula-2-banco."
    if [ "$(az group exists -n "$RG_NOME" 2>/dev/null)" = "true" ]; then
      falhar "O grupo $RG_NOME ainda existe na Azure. Rode 'terraform destroy' de novo."
    fi
    ok "Nada sobrou na Azure"
    conferir_github
    if gh secret list --repo "$REPO" 2>/dev/null | grep -q AZURE_WEBAPP_PUBLISH_PROFILE; then
      falhar "O segredo ainda está no GitHub. Rode ./conectar-github.sh --desconectar"
    fi
    ok "Nenhuma credencial sobrou no GitHub"
    medalha "$MISSAO" "Faxina completa" "FAXINA"
    ;;
esac
