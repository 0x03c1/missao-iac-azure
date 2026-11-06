# shellcheck shell=bash
# Embarque compartilhado pelas aulas: confere login e Terraform, escolhe uma
# região permitida, registra os serviços da Azure e grava azure.auto.tfvars
# na pasta atual. Carregado pelo embarque.sh de cada aula.
#
# Uso: embarcar "<região forçada ou vazio>" Microsoft.Storage [Microsoft.Web ...]

REGIOES_PREFERIDAS="brazilsouth eastus eastus2 centralus southcentralus westus2 westus3 northeurope westeurope"

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

embarcar() {
  local regiao_forcada="$1"; shift
  local servicos=("$@") sub_id sub_nome qtd_subs permitidas regiao preferida servico estado

  printf '\n%sMISSÃO IaC AZURE%s\n' "$NEGRITO" "$RESET"
  printf 'Preparando o terminal (%s)...\n' "$(ambiente)"

  passo "1/4 Login na Azure"
  if ! sub_id=$(az account show --query id -o tsv 2>/dev/null); then
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
  sub_nome=$(az account show --query name -o tsv)
  ok "Assinatura: ${NEGRITO}${sub_nome}${RESET}"

  qtd_subs=$(az account list --query "length([?state=='Enabled'])" -o tsv 2>/dev/null || echo 1)
  if [ "${qtd_subs:-1}" -gt 1 ]; then
    aviso "Você tem $qtd_subs assinaturas. Se esta não for a da faculdade, rode:"
    echo "    az account list -o table"
    echo "    az account set --subscription \"NOME DA ASSINATURA\""
    echo "  e depois rode ./embarque.sh de novo."
  fi

  passo "2/4 Terraform"
  command -v terraform >/dev/null || falhar "Terraform não encontrado. Chame o professor."
  ok "$(terraform -version | head -1)"

  passo "3/4 Região permitida para a sua conta"
  if [ -n "$regiao_forcada" ]; then
    regiao="$regiao_forcada"
    ok "Usando a região informada: ${NEGRITO}${regiao}${RESET}"
  else
    permitidas=$(regioes_permitidas)
    permitidas="${permitidas% }"
    regiao=""
    if [ -n "$permitidas" ]; then
      ok "Regiões permitidas: $permitidas"
      for preferida in $REGIOES_PREFERIDAS; do
        if [[ " $permitidas " == *" $preferida "* ]]; then regiao="$preferida"; break; fi
      done
      [ -z "$regiao" ] && regiao="${permitidas%% *}"
    else
      regiao="eastus"
      aviso "Nenhuma restrição de região encontrada. Usando eastus."
    fi
    ok "Região escolhida: ${NEGRITO}${regiao}${RESET}"
  fi

  passo "4/4 Serviços da Azure (na primeira vez pode levar até 2 min)"
  for servico in "${servicos[@]}"; do
    estado=$(az provider show --namespace "$servico" --query registrationState -o tsv 2>/dev/null)
    if [ "$estado" = "Registered" ]; then
      ok "$servico já estava registrado"
    else
      az provider register --namespace "$servico" --wait --only-show-errors \
        || falhar "Não consegui registrar $servico. Chame o professor."
      ok "$servico registrado"
    fi
  done

  cat > azure.auto.tfvars <<EOF
# Gerado pelo ./embarque.sh. Não precisa editar.
subscription_id = "$sub_id"
regiao          = "$regiao"
EOF
  ok "Configuração salva em azure.auto.tfvars"

  printf '\n%sTerminal pronto.%s Próximo passo: %s./checkpoint.sh 1%s\n\n' "$VERDE" "$RESET" "$NEGRITO" "$RESET"
}
