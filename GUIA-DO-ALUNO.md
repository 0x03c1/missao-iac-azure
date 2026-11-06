# Missão: Servidores sob Ataque

## Guia do Aluno

Hoje você vai criar servidores na Azure sem clicar em nada no portal, só com código. Depois, vai sobreviver a um ataque.

---

## Regras da dupla

| Papel | O que faz |
|---|---|
| **Piloto** | Digita os comandos |
| **Copiloto** | Lê este guia em voz alta e confere o que aparece na tela |

- A cada missão, vocês **trocam de papel**.
- Ao final de cada missão aparece uma **palavra-código**. Levante a mão e mostre ao professor para marcar no placar.

**Dicas do terminal**

- **Colar:** `Ctrl + Shift + V` (ou botão direito, *Colar*)
- **Abrir um link:** segure `Ctrl` (no Mac, `Cmd`) e clique no link

---

## Missão 1: Embarque (10 min)

**Objetivo:** abrir um terminal conectado à Azure e preparar o ambiente.

Existem dois caminhos. **Na aula usamos o Caminho A.** O Caminho B mostra como fazer o mesmo fora do portal da Azure, usando `az login`.

### Caminho A: Azure Cloud Shell (usado na aula)

O Cloud Shell é o terminal da própria Azure. Ele já vem logado na sua conta e com o Terraform instalado.

1. Abra **https://portal.azure.com** e entre com a **conta da faculdade**.
2. No topo da tela, clique no ícone **`>_`** (Cloud Shell). *Alternativa: abra **https://shell.azure.com** em outra aba.*
3. Se perguntar **Bash ou PowerShell**, escolha **Bash**. *Se abrir em PowerShell, clique em **Alternar para Bash** (Switch to Bash) no topo do terminal.*
4. Se perguntar sobre armazenamento, escolha **Nenhuma conta de armazenamento necessária** (No storage account required), selecione a assinatura e clique em **Aplicar**.
5. No terminal, cole **uma linha por vez** e aperte `Enter`:

```bash
git clone https://github.com/0x03c1/missao-iac-azure.git
```

```bash
cd missao-iac-azure
```

```bash
./embarque.sh
```

Siga para o passo **"Confira a missão"**, no fim desta seção.

### Caminho B: GitHub Codespaces com `az login` (alternativa)

Use este caminho para estudar em casa ou em qualquer computador fora do portal da Azure. É preciso ter conta no GitHub.

1. Abra **https://github.com/0x03c1/missao-iac-azure** logado no GitHub.
2. Clique no botão verde **Code**, depois na aba **Codespaces** e em **Create codespace on main**.
3. Aguarde de 2 a 3 minutos. Vai abrir um VS Code no navegador, com um terminal na parte de baixo. *Se o terminal não aparecer: menu (três tracinhos no canto superior esquerdo), **Terminal**, **New Terminal**.*
4. Faça login na Azure:

```bash
az login --use-device-code
```

5. O terminal vai mostrar um **código** e o endereço **https://microsoft.com/devicelogin**.
   - Abra o endereço numa nova aba.
   - Cole o código.
   - Entre com a **conta da faculdade**.
   - Volte para o terminal.
6. Se o terminal perguntar qual assinatura usar (**Select a subscription**), digite o **número** da assinatura da faculdade e aperte `Enter`.
7. Confira se ficou logado na conta certa:

```bash
az account show --query "{assinatura:name, usuario:user.name}" -o table
```

8. Prepare o ambiente:

```bash
./embarque.sh
```

### Confira a missão (os dois caminhos)

**Deve aparecer:** várias linhas com `✔` e, no final, **Terminal pronto**.

```bash
./checkpoint.sh 1
```

Apareceu a palavra-código? Levante a mão.

---

## Missão 2: Primeiro site no ar (20 min)

Troquem de papel.

**Objetivo:** criar o primeiro servidor com 3 comandos.

### Passo 1: preparar o Terraform

```bash
terraform init
```

**Deve aparecer:** `Terraform has been successfully initialized!`

O `init` baixa os providers, que são os "tradutores" entre o Terraform e a Azure.

### Passo 2: ver o que vai acontecer, sem mudar nada

```bash
terraform plan
```

**Deve aparecer no final:** `Plan: 6 to add, 0 to change, 0 to destroy.`

O `plan` é uma **prévia**: mostra o que seria criado. Nada foi criado ainda.

> Se aparecer um aviso amarelo `Argument is deprecated`, pode ignorar. É um aviso, não um erro.

### Passo 3: criar de verdade

```bash
terraform apply
```

Quando aparecer `Enter a value:`, digite **`yes`** e aperte `Enter`. Leva de 1 a 2 minutos.

**Deve aparecer:** `Apply complete! Resources: 6 added` e, logo abaixo, `sites = [ "https://missao....web.core.windows.net/" ]`

### Passo 4: abrir o site

Segure `Ctrl` e clique no link que apareceu em `sites`.

### Passo 5: rode o apply de novo

```bash
terraform apply
```

**Deve aparecer:** `No changes. Your infrastructure matches the configuration.`

Como o código não mudou, nada muda. Isso se chama **idempotência**.

```bash
./checkpoint.sh 2
```

Levante a mão.

---

## Missão 3: Personalize (10 min)

Troquem de papel.

**Objetivo:** mudar o site mudando o código.

1. Abra o arquivo de configuração:

```bash
code terraform.tfvars
```

2. Mude **o que está entre aspas** em `nome_da_dupla`, `emoji`, `cor_de_fundo` e `lema`. Exemplo:

```hcl
nome_da_dupla = "Ana e Leo"
emoji         = "🦄"
cor_de_fundo  = "#7c3aed"
lema          = "Deploy ou nada!"
```

3. Salve com **`Ctrl + S`**.

> **Se o comando `code` não abrir o editor**, use o nano:
> 1. Rode `nano terraform.tfvars`.
> 2. Edite usando as setas do teclado.
> 3. Salve com `Ctrl + O` e depois `Enter`.
> 4. Saia com `Ctrl + X`.

4. Veja a prévia:

```bash
terraform plan
```

Repare nos símbolos:

| Símbolo | Significado |
|---|---|
| `+` | vai **criar** |
| `~` | vai **alterar** sem recriar |
| `-/+` | vai **apagar e recriar** (substituir) |
| `-` | vai **apagar** |

5. Aplique e digite **`yes`**:

```bash
terraform apply
```

6. Volte na aba do site e recarregue com **`Ctrl + Shift + R`**.

```bash
./checkpoint.sh 3
```

Levante a mão.

---

## Missão 4: Escale para 3 servidores (13 min)

Troquem de papel.

**Objetivo:** ter 3 servidores mudando **um número**.

1. Abra o arquivo de novo:

```bash
code terraform.tfvars
```

2. Mude a última linha de `1` para `3` e salve com `Ctrl + S`:

```hcl
quantidade_de_servidores = 3
```

3. Veja a prévia:

```bash
terraform plan
```

**Deve aparecer:** `Plan: 10 to add, 0 to change, 0 to destroy.`

O servidor 1 continua intacto. O Terraform só cria o que falta.

4. Aplique e digite **`yes`**:

```bash
terraform apply
```

**Deve aparecer:** 3 links em `sites`. Abra os três.

5. **Bônus:** no portal da Azure, abra **Grupos de recursos** e depois **rg-missao-iac**. Os servidores que vocês criaram sem clicar em nada estão lá.

```bash
./checkpoint.sh 4
```

Levante a mão.

---

## Missão 5: Caos (15 min)

Troquem de papel.

> **Atenção:** só comece quando o professor der o sinal.

1. No sinal, rode:

```bash
./caos.sh
```

Um dos seus servidores foi derrubado. Clique no link que apareceu para ver o estrago.

2. Investigue o que o Terraform percebeu:

```bash
terraform plan
```

**Deve aparecer:** `Plan: 1 to add`, que é a página que o "hacker" apagou.

O Terraform compara o **código** com a **realidade**. Quando a realidade muda por fora do código, isso se chama **drift** (desvio).

3. Conserte e digite **`yes`**:

```bash
terraform apply
```

Recarregue o site com **`Ctrl + Shift + R`**.

```bash
./checkpoint.sh 5
```

Levante a mão. A primeira dupla a chegar aqui vence a rodada.

---

## Missão 6: Faxina (7 min)

Troquem de papel.

**Objetivo:** apagar tudo. Na nuvem, recurso esquecido vira conta para pagar.

```bash
terraform destroy
```

Digite **`yes`**. Leva de 1 a 3 minutos.

**Deve aparecer:** `Destroy complete! Resources: 16 destroyed.`

```bash
./checkpoint.sh 6
```

Última palavra-código. Missão cumprida.

> **Quem usou o Caminho B (Codespaces):** depois do checkpoint, apague o codespace para não gastar a sua cota gratuita. Abra **https://github.com/codespaces**, clique nos três pontinhos ao lado do codespace e escolha **Delete**.

---

## Deu erro? Procure aqui antes de chamar o professor

| Apareceu isto | Faça isto |
|---|---|
| Aviso amarelo `Argument is deprecated` | Nada. É um aviso, não um erro. Pode seguir. |
| `RequestDisallowedByAzure` | Sua conta não pode usar essa região. Rode `./embarque.sh westus2`, trocando `westus2` por uma região da lista que o embarque mostrou, e depois rode `terraform apply` de novo. |
| `Você ainda não está logado na Azure` | No Codespaces, rode `az login --use-device-code`. No Cloud Shell, feche e abra o terminal de novo. |
| `Permission denied` ao rodar `./algo.sh` | Rode com `bash` na frente, por exemplo `bash embarque.sh`. |
| `No such file or directory` | Você está fora da pasta. No Cloud Shell, rode `cd ~/missao-iac-azure`. No Codespaces, rode `cd /workspaces/missao-iac-azure`. |
| `No changes` mesmo depois de editar o arquivo | O arquivo não foi salvo. Volte ao editor e aperte `Ctrl + S`. |
| O site mostra a versão antiga | Recarregue com `Ctrl + Shift + R` ou abra numa aba anônima. |
| `Invalid value for variable` | Leia a mensagem. A cor deve estar no formato `"#RRGGBB"` e o nome não pode ter `< > % & ? /`. |
| O terminal reiniciou e a pasta sumiu, ou apareceu `already exists` | Chame o professor. Provavelmente será preciso rodar o `./resgate.sh`. |

---

## Cola rápida

| Comando | O que faz |
|---|---|
| `az login --use-device-code` | Faz login na Azure fora do Cloud Shell |
| `terraform init` | Prepara a pasta e baixa os providers |
| `terraform plan` | Prévia: mostra o que vai mudar, sem mudar nada |
| `terraform apply` | Executa as mudanças |
| `terraform destroy` | Apaga tudo que o código criou |
| `terraform output` | Mostra de novo os links dos sites |
