# Aula 2: Memória da Rede

## Guia do Aluno

Na Aula 1, vocês criaram sites estáticos: páginas que não guardam nada. Hoje vão provisionar um **servidor de aplicação** com um **banco de dados SQLite**, publicar um mural de mensagens e descobrir onde os dados precisam morar para sobreviver a um apagão.

---

## Regras da dupla

| Papel | O que faz |
|---|---|
| **Piloto** | Digita os comandos |
| **Copiloto** | Lê este guia em voz alta e confere o que aparece na tela |

- A cada missão, vocês **trocam de papel**.
- Ao final de cada missão aparece uma **palavra-código**. Levante a mão e mostre ao professor.
- **Só o computador do piloto abre o terminal.** O copiloto não abre o Cloud Shell, porque a faculdade tem um limite de terminais abertos ao mesmo tempo.

**Dicas do terminal**

- **Colar:** `Ctrl + V` (no Mac, `Cmd + V`). Se não funcionar, use o botão direito e *Colar*.
- **Abrir um link:** segure `Ctrl` (no Mac, `Cmd`) e clique no link.
- **Não aperte `Ctrl + C` enquanto um comando estiver rodando:** sem texto selecionado, isso interrompe o comando.

> **Importante:** não feche a aba do terminal até o fim da aula e não fique mais de 15 minutos sem digitar nada nele. Se o Cloud Shell fechar, ele apaga os arquivos e o Terraform perde o registro do que criou.

---

## Missão 1: Embarque (10 min)

**Objetivo:** abrir o terminal e preparar a pasta da Aula 2.

1. Abra uma **aba nova** só para o terminal e acesse **https://shell.azure.com**, com a conta da faculdade.
2. Se perguntar, escolha **Bash** e **Nenhuma conta de armazenamento necessária** (No storage account required), e clique em **Aplicar**.
3. Cole uma linha por vez e aperte `Enter`:

```bash
git clone https://github.com/0x03c1/missao-iac-azure.git
```

```bash
cd missao-iac-azure/aula-2-banco
```

```bash
./embarque.sh
```

```bash
./checkpoint.sh 1
```

> **Se aparecer `already exists` no `git clone`**, a pasta da aula passada ainda existe. Rode `cd missao-iac-azure && git pull && cd aula-2-banco` e siga com o `./embarque.sh`.
>
> **Usando o Codespaces (Caminho B da Aula 1)?** Rode `az login --use-device-code`, depois `cd aula-2-banco` e `./embarque.sh`.

Levante a mão.

---

## Missão 2: Mural no ar (25 min)

Troquem de papel.

**Objetivo:** provisionar um servidor de aplicação com banco de dados, só com código.

### Passo 1: personalize antes de criar

```bash
code terraform.tfvars
```

Mude `nome_do_mural` e `cor_neon`. Exemplo:

```hcl
nome_do_mural = "Mural da Ana e do Leo"
cor_neon      = "#ff2a6d"
```

Salve com `Ctrl + S` e feche o editor com `Ctrl + Q`. *Se o `code` não abrir, use `nano terraform.tfvars` (salvar: `Ctrl + O` e `Enter`; sair: `Ctrl + X`).*

### Passo 2: init e plan

```bash
terraform init
```

```bash
terraform plan
```

**Deve aparecer:** `Plan: 4 to add, 0 to change, 0 to destroy.`

| Recurso | O que é |
|---|---|
| `azurerm_resource_group` | A "pasta" da aula na Azure |
| `random_string` | Um sufixo para o endereço ser único no mundo |
| `azurerm_service_plan` | O **plano**: a máquina onde o app roda (F1, gratuito) |
| `azurerm_linux_web_app` | O **app**: Python rodando o mural, com o banco SQLite |

### Passo 3: apply

```bash
terraform apply
```

Digite **`yes`**. Leva de 3 a 6 minutos: o Terraform cria o servidor e publica o código.

**Deve aparecer:** `Apply complete! Resources: 4 added` e o `endereco_do_mural`.

### Passo 4: abra o mural

Segure `Ctrl` e clique no `endereco_do_mural`.

> **O primeiro acesso pode levar até 2 minutos.** O plano gratuito "dorme" quando ninguém usa e precisa acordar. Se aparecer erro, espere e recarregue a página.

```bash
./checkpoint.sh 2
```

Levante a mão.

---

## Missão 3: Grave no banco (10 min)

Troquem de papel.

**Objetivo:** escrever dados que ficam gravados no banco.

1. No mural, cada pessoa da dupla escreve **pelo menos uma mensagem**, até ter **3 mensagens ou mais**.
2. Repare no rodapé do mural: **Mensagens no banco** e **Banco persistente: SIM (/home)**.
3. Abra o endereço do mural com `/api/mensagens` no final, por exemplo `https://mural-abc123.azurewebsites.net/api/mensagens`. São os mesmos dados, em formato **JSON**: é assim que outros sistemas leem o banco.

```bash
./checkpoint.sh 3
```

Levante a mão.

---

## Missão 4: Apagão (15 min)

Troquem de papel.

> **Atenção:** só comece quando o professor der o sinal.

1. No sinal, rode:

```bash
./caos.sh
```

O script desliga e religa o servidor do mural. Espere até ele mostrar quantas mensagens havia **antes** e **depois** do apagão.

2. Recarregue o mural. Repare que **Servidor ligado em** mudou, mas as mensagens continuam lá.

**Por quê?** O arquivo do banco (`mural.db`) está na pasta `/home`, que é um **disco persistente**: ele fica guardado fora do servidor e é reconectado quando o servidor volta.

```bash
./checkpoint.sh 4
```

Levante a mão.

---

## Missão 5: O experimento (20 min)

Troquem de papel.

**Objetivo:** descobrir o que acontece quando o banco mora no lugar errado.

1. Abra o `terraform.tfvars` e mude a última linha para `false`. Salve.

```hcl
banco_persistente = false
```

2. Veja a prévia e aplique:

```bash
terraform plan
```

**Deve aparecer:** `1 to change`. O Terraform só muda a configuração do app: o banco passa para `/tmp`.

```bash
terraform apply
```

3. Recarregue o mural (pode demorar até 1 minuto). **O mural está vazio!** O rodapé mostra **Banco persistente: NÃO (/tmp)**. Escreva **uma mensagem nova**.
4. Rode o apagão de novo:

```bash
./caos.sh
```

**As mensagens sumiram.** A pasta `/tmp` fica **dentro** do servidor e é apagada quando ele reinicia.

5. Agora volte a última linha do `terraform.tfvars` para `true`, salve e aplique:

```hcl
banco_persistente = true
```

```bash
terraform apply
```

6. Recarregue o mural. **As mensagens antigas voltaram!** O arquivo em `/home` estava guardado o tempo todo.

```bash
./checkpoint.sh 5
```

Levante a mão.

> **A lição:** servidores são descartáveis; dados não. Em produção, o banco costuma ficar num serviço gerenciado (como Azure SQL ou PostgreSQL), separado do servidor da aplicação.

---

## Missão 6: Faxina (5 min)

Troquem de papel.

```bash
terraform destroy
```

Digite **`yes`**. **Deve aparecer:** `Destroy complete! Resources: 4 destroyed.`

```bash
./checkpoint.sh 6
```

Última palavra-código. Missão cumprida.

---

## Deu erro? Procure aqui antes de chamar o professor

| Apareceu isto | Faça isto |
|---|---|
| Aviso amarelo de `deprecated` | Nada. É um aviso, não um erro. |
| `RequestDisallowedByAzure` | Região não permitida. Rode `./embarque.sh westus2`, trocando `westus2` por uma região da lista que o embarque mostrou, e depois `terraform apply` de novo. |
| Erro de **quota** ou de plano `F1` indisponível no `apply` | Chame o professor. Ele pode pedir para tentar outra região ou usar o plano `B1`. |
| O mural mostra **Application Error** ou não abre | Espere 2 minutos e recarregue: o servidor gratuito está acordando. Se passar de 5 minutos, chame o professor. |
| O mural ainda mostra o nome antigo | Recarregue com `Ctrl + Shift + R`. |
| `Tenant User Over Quota` ao abrir o Cloud Shell | Limite de terminais da faculdade. Feche outros Cloud Shell abertos e tente em 1 minuto. |
| O terminal reiniciou e a pasta sumiu, ou apareceu `already exists` | Chame o professor. Provavelmente será preciso rodar o `./resgate.sh`. |

---

## Cola rápida

| Endereço | O que mostra |
|---|---|
| `/` | O mural |
| `/api/mensagens` | As mensagens em JSON |
| `/saude` | O estado do app: total de mensagens, caminho do banco, versão |

| Comando | O que faz |
|---|---|
| `terraform plan` | Prévia: mostra o que vai mudar, sem mudar nada |
| `terraform apply` | Executa as mudanças |
| `terraform destroy` | Apaga tudo que o código criou |
| `terraform output` | Mostra de novo o endereço do mural |
