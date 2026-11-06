# 🚀 Missão: Servidores sob Ataque — Guia do Aluno

> **Hoje você vai criar servidores na Azure sem clicar em nada no portal.**
> Só com código. E depois vai sobreviver a um ataque. 😈

---

## 👥 Regras da dupla

| Papel | O que faz |
|---|---|
| 🎮 **Piloto** | Digita os comandos |
| 🧭 **Copiloto** | Lê este guia em voz alta e confere o que aparece na tela |

🔁 **A cada missão vocês TROCAM de papel.**
🔑 Ao final de cada missão aparece uma **palavra-código**. Levante a mão e mostre ao professor para marcar no placar.

### Como colar no Cloud Shell
- **Colar:** `Ctrl + Shift + V` (ou botão direito → *Colar*)
- **Abrir um link do terminal:** segure `Ctrl` (no Mac, `Cmd`) e clique no link

---

## 🟦 MISSÃO 1 — Embarque *(10 min)*

**Objetivo:** abrir o terminal da Azure e preparar a nave.

1. Abra **https://portal.azure.com** e entre com a **conta da faculdade**.
2. No topo da tela, clique no ícone **`>_`** (Cloud Shell).
   *(Alternativa: abra **https://shell.azure.com** em outra aba.)*
3. Se perguntar **Bash ou PowerShell**, escolha **Bash**.
   *(Se abrir em PowerShell, clique em **"Alternar para Bash"** / **"Switch to Bash"** no topo do terminal.)*
4. Se perguntar sobre armazenamento, escolha **"Nenhuma conta de armazenamento necessária"** (*"No storage account required"*), selecione a assinatura e clique em **Aplicar**.
5. Quando aparecer o terminal preto, cole **uma linha por vez** e aperte `Enter`:

```bash
git clone https://github.com/0x03c1/missao-iac-azure.git
```

```bash
cd missao-iac-azure
```

```bash
./embarque.sh
```

✅ **Deve aparecer:** várias linhas com ✔ verde e no final **🚀 Nave pronta!**

6. Confira a missão:

```bash
./checkpoint.sh 1
```

🔑 **Apareceu a palavra-código? Mão para cima!** ✋

---

## 🟩 MISSÃO 2 — Primeiro site no ar *(20 min)* — 🔁 troquem de papel

**Objetivo:** criar o primeiro servidor usando só 3 comandos.

### Passo 1 — Preparar o Terraform

```bash
terraform init
```

✅ **Deve aparecer:** `Terraform has been successfully initialized!` em verde.
💡 *O `init` baixa os "tradutores" (providers) entre o Terraform e a Azure.*

### Passo 2 — Ver o que vai acontecer (sem mudar nada)

```bash
terraform plan
```

✅ **Deve aparecer no final:** `Plan: 6 to add, 0 to change, 0 to destroy.`
💡 *O `plan` é uma **prévia**: mostra o que SERIA criado. Nada foi criado ainda!*
⚠️ *Se aparecer um aviso **amarelo** "Argument is deprecated", pode ignorar: é só um aviso, não é erro.*

### Passo 3 — Criar de verdade

```bash
terraform apply
```

Quando perguntar `Enter a value:`, digite **`yes`** e aperte `Enter`.

⏳ Leva de 1 a 2 minutos.

✅ **Deve aparecer:** `Apply complete! Resources: 6 added` e, logo abaixo, `sites = [ "https://missao….web.core.windows.net/" ]`

### Passo 4 — Abrir o site

Segure `Ctrl` e **clique no link** que apareceu em `sites`. 🎉

### Passo 5 — Desafio rápido: rode o apply DE NOVO

```bash
terraform apply
```

✅ **Deve aparecer:** `No changes. Your infrastructure matches the configuration.`
💡 *O código não mudou, então nada muda. Isso se chama **idempotência**.*

```bash
./checkpoint.sh 2
```

🔑 Mão para cima! ✋

---

## 🟨 MISSÃO 3 — Personalize *(10 min)* — 🔁 troquem de papel

**Objetivo:** mudar o site **mudando o código**.

1. Abra o arquivo de configuração:

```bash
code terraform.tfvars
```

*(Abre um editor em cima do terminal. Se não abrir, veja o **Plano B** logo abaixo.)*

2. Mude **o que está entre aspas**: `nome_da_dupla`, `emoji`, `cor_de_fundo` e `lema`. Exemplo:

```hcl
nome_da_dupla = "Ana e Leo"
emoji         = "🦄"
cor_de_fundo  = "#7c3aed"
lema          = "Deploy ou nada!"
```

3. Salve com **`Ctrl + S`**.

> **Plano B (se o `code` não abrir):** rode `nano terraform.tfvars`, edite com as setas do teclado, salve com `Ctrl + O` e `Enter`, e saia com `Ctrl + X`.

4. Veja a prévia:

```bash
terraform plan
```

✅ **Repare nos símbolos:**

| Símbolo | Significa |
|---|---|
| `+` | vai **criar** |
| `~` | vai **alterar** sem recriar |
| `-/+` | vai **apagar e recriar** (substituir) |
| `-` | vai **apagar** |

5. Aplique:

```bash
terraform apply
```

Digite **`yes`**.

6. Volte na aba do site e recarregue com **`Ctrl + Shift + R`**. 🎨

```bash
./checkpoint.sh 3
```

🔑 Mão para cima! ✋

---

## 🟧 MISSÃO 4 — Escale ×3 *(13 min)* — 🔁 troquem de papel

**Objetivo:** ter **3 servidores** mudando **um número**.

1. Abra o arquivo de novo:

```bash
code terraform.tfvars
```

2. Mude a última linha de `1` para `3` e salve (`Ctrl + S`):

```hcl
quantidade_de_servidores = 3
```

3. Veja a prévia:

```bash
terraform plan
```

✅ **Deve aparecer:** `Plan: 10 to add, 0 to change, 0 to destroy.`
💡 *O servidor 1 continua intacto. O Terraform só cria o que FALTA.*

4. Aplique:

```bash
terraform apply
```

Digite **`yes`**.

✅ **Deve aparecer:** 3 links em `sites`. Abra os 3!

5. **Bônus:** no portal da Azure, procure por **Grupos de recursos** → **rg-missao-iac**. Estão lá os servidores que vocês criaram **sem clicar em nada**.

```bash
./checkpoint.sh 4
```

🔑 Mão para cima! ✋

---

## 🟥 MISSÃO 5 — 🔥 CAOS! *(15 min)* — 🔁 troquem de papel

**⛔ SÓ COMECE QUANDO O PROFESSOR DER O SINAL!**

1. No sinal, rode:

```bash
./caos.sh
```

💀 **Um dos seus servidores foi derrubado!** Clique no link que apareceu para ver o estrago.

2. Investigue: o que o Terraform percebeu?

```bash
terraform plan
```

✅ **Deve aparecer:** `Plan: 1 to add` (a página que o "hacker" apagou).
💡 *O Terraform compara o **código** com a **realidade**. Quando a realidade muda "por fora", isso se chama **drift** (desvio).*

3. Conserte:

```bash
terraform apply
```

Digite **`yes`**. Recarregue o site com **`Ctrl + Shift + R`**. 🦅

```bash
./checkpoint.sh 5
```

🔑 Mão para cima! A primeira dupla a chegar aqui vence a rodada do caos! ✋

---

## ⬛ MISSÃO 6 — Faxina *(7 min)* — 🔁 troquem de papel

**Objetivo:** apagar tudo. **Na nuvem, recurso esquecido é conta pra pagar.** 💸

```bash
terraform destroy
```

Digite **`yes`**. ⏳ Leva de 1 a 3 minutos.

✅ **Deve aparecer:** `Destroy complete! Resources: 16 destroyed.`

```bash
./checkpoint.sh 6
```

🔑 Última palavra-código! ✋ **Missão cumprida!** 🏆

---

## 🆘 Deu erro? Procure aqui antes de chamar o professor

| Apareceu isto… | Faça isto |
|---|---|
| Aviso **amarelo** `Argument is deprecated` | Nada. É só um aviso, não um erro. Pode seguir. |
| `RequestDisallowedByAzure` | Sua conta não pode usar essa região. Rode `./embarque.sh westus2` (troque `westus2` por uma região da lista que o embarque mostrou) e depois rode `terraform apply` de novo. |
| `Permission denied` ao rodar `./algo.sh` | Rode com `bash` na frente: `bash embarque.sh` |
| `No such file or directory` | Você está fora da pasta. Rode `cd ~/missao-iac-azure` |
| `No changes` mesmo depois de editar o arquivo | Você não salvou. Volte no editor e aperte `Ctrl + S`. |
| O site mostra a versão antiga | Recarregue com `Ctrl + Shift + R` ou abra numa aba anônima. |
| `Invalid value for variable` | Leia a mensagem. A cor deve ser `"#RRGGBB"` e o nome não pode ter `< > % & ? /`. |
| O terminal fechou ou reconectou e a pasta sumiu | Chame o professor. Provavelmente vai ser preciso rodar o `./resgate.sh`. |
| `already exists` | Chame o professor. Provavelmente vai ser preciso rodar o `./resgate.sh`. |

---

## 📚 Cola rápida

| Comando | O que faz |
|---|---|
| `terraform init` | Prepara a pasta e baixa os providers |
| `terraform plan` | **Prévia**: mostra o que vai mudar, sem mudar nada |
| `terraform apply` | **Executa** as mudanças |
| `terraform destroy` | **Apaga** tudo que o código criou |
| `terraform output` | Mostra de novo os links dos sites |
