# Aula 3: Pipeline

## Guia do Aluno

Até agora, toda mudança passou pelas mãos de vocês: editar, rodar `apply`, conferir. Hoje vão montar um **pipeline de CI/CD** no GitHub: a cada mudança no código, o GitHub **testa** sozinho e, se os testes passarem, **publica** na Azure sozinho. E, se alguém errar, o pipeline segura o erro antes que ele chegue ao ar.

**Pré-requisito:** cada dupla precisa de **uma conta no GitHub** (https://github.com/signup).

---

## Regras da dupla

| Papel | O que faz |
|---|---|
| **Piloto** | Digita os comandos e faz os commits |
| **Copiloto** | Lê este guia em voz alta e acompanha a aba **Actions** do GitHub |

- A cada missão, vocês **trocam de papel**.
- Ao final de cada missão aparece uma **palavra-código**. Levante a mão e mostre ao professor.
- **Só o computador do piloto abre o Cloud Shell.**
- **Não feche a aba do terminal** até o fim da aula.

---

## Missão 1: A base (25 min)

**Objetivo:** ter o seu próprio repositório e o mural da Aula 2 no ar.

### Passo 1: faça um fork (cópia sua do repositório)

1. Entre no GitHub com a conta da dupla.
2. Abra **https://github.com/0x03c1/missao-iac-azure**.
3. Clique em **Fork** (canto superior direito) e depois em **Create fork**.

Agora existe `https://github.com/SEU-USUARIO/missao-iac-azure`. É **o repositório de vocês**.

### Passo 2: ligue o GitHub Actions no fork

1. No **seu fork**, clique na aba **Actions**.
2. Clique no botão verde **I understand my workflows, go ahead and enable them**.

### Passo 3: suba o mural da Aula 2

1. Abra **https://shell.azure.com** numa aba própria (Bash, sem armazenamento).
2. Clone **o seu fork**, trocando `SEU-USUARIO` pelo usuário do GitHub da dupla:

```bash
git clone https://github.com/SEU-USUARIO/missao-iac-azure.git
```

> **Se aparecer `already exists`**, apague a pasta antiga com `rm -rf missao-iac-azure` e rode o `git clone` de novo.

3. Prepare e crie o mural, como na Aula 2:

```bash
cd missao-iac-azure/aula-2-banco
```

```bash
./embarque.sh
```

```bash
terraform init
```

```bash
terraform apply
```

Digite **`yes`** e espere de 3 a 6 minutos.

4. Vá para a pasta desta aula e confira:

```bash
cd ../aula-3-cicd
```

```bash
./checkpoint.sh 1
```

Levante a mão.

---

## Missão 2: Conecte o GitHub à Azure (10 min)

Troquem de papel.

**Objetivo:** dar ao GitHub permissão para publicar no mural.

```bash
./conectar-github.sh
```

O script vai pedir login no GitHub:

1. Aperte `Enter` quando ele pedir.
2. Copie o **código de 8 letras** que aparecer.
3. Abra **https://github.com/login/device**, cole o código e clique em **Authorize**.

Depois, o script guarda no seu fork:

| O quê | Tipo | Para quê |
|---|---|---|
| `AZURE_WEBAPP_PUBLISH_PROFILE` | **Segredo** | A chave para publicar no app. O GitHub guarda criptografado e **nunca mostra** o valor, nem para vocês. |
| `AZURE_WEBAPP_NAME` | **Variável** | O nome do app. Não é segredo. |

Confira no GitHub: no seu fork, **Settings**, **Secrets and variables**, **Actions**.

```bash
./checkpoint.sh 2
```

Levante a mão.

---

## Missão 3: O primeiro deploy automático (20 min)

Troquem de papel.

**Objetivo:** mudar o mural **sem usar o terminal**: só com um commit.

1. No **seu fork** no GitHub, abra a pasta `aula-2-banco`, depois `app` e o arquivo **`config.py`**.
2. Clique no **lápis** (Edit this file).
3. Mude o texto entre aspas de `MENSAGEM_DE_BOAS_VINDAS`. Exemplo:

```python
MENSAGEM_DE_BOAS_VINDAS = "Transmissão publicada pelo pipeline da Ana e do Leo!"
```

4. Clique em **Commit changes...**, mantenha **Commit directly to the main branch** e clique em **Commit changes**.
5. Abra a aba **Actions**. Vai aparecer uma execução de **Pipeline do mural** rodando:
   - **1. Testes automáticos**: roda os testes do mural;
   - **2. Publicar na Azure**: só começa se os testes passarem.
6. Quando as duas etapas ficarem verdes (de 2 a 4 minutos), abra o mural e recarregue.
   - A mensagem nova aparece no topo.
   - No rodapé, **Versão** mostra os 7 primeiros caracteres do seu commit.

```bash
./checkpoint.sh 3
```

Levante a mão.

> **Bônus:** abra o arquivo `.github/workflows/pipeline.yml` no seu fork. É o "roteiro" que o GitHub segue: também é código.

---

## Missão 4: Quebre de propósito (15 min)

Troquem de papel.

**Objetivo:** ver o pipeline barrar um erro antes que ele chegue ao ar.

1. Edite o `config.py` de novo e mude o limite para **0**:

```python
LIMITE_DE_CARACTERES = 0
```

2. Faça o commit direto na `main`.
3. Na aba **Actions**, acompanhe:
   - **1. Testes automáticos** fica **vermelho**;
   - **2. Publicar na Azure** **não roda** (fica cinza, *skipped*).
4. Clique na etapa vermelha e procure a mensagem do teste: `O limite precisa ser pelo menos 1.`
5. Abra o mural e recarregue: ele **continua funcionando**, na versão anterior.

```bash
./checkpoint.sh 4
```

Levante a mão.

> **A lição:** sem o pipeline, esse erro iria direto para o ar e ninguém conseguiria escrever no mural. O teste automático protegeu a produção.

---

## Missão 5: Conserte (10 min)

Troquem de papel.

1. Edite o `config.py` e volte o limite para um valor válido, de 1 a 280:

```python
LIMITE_DE_CARACTERES = 140
```

2. Faça o commit e acompanhe na aba **Actions** até ficar tudo verde.
3. Recarregue o mural: a **Versão** no rodapé mudou para o commit da correção.

```bash
./checkpoint.sh 5
```

Levante a mão.

---

## Missão 6: Faxina (10 min)

Troquem de papel.

1. Apague a infraestrutura:

```bash
cd ../aula-2-banco
```

```bash
terraform destroy
```

Digite **`yes`**.

2. Apague a credencial do GitHub. Uma chave de publicação esquecida é um risco de segurança, mesmo que o app não exista mais.

```bash
cd ../aula-3-cicd
```

```bash
./conectar-github.sh --desconectar
```

```bash
./checkpoint.sh 6
```

Última palavra-código. Missão cumprida.

---

## Deu erro? Procure aqui antes de chamar o professor

| Apareceu isto | Faça isto |
|---|---|
| O commit não disparou nada na aba **Actions** | O Actions não foi ligado no fork (Missão 1, passo 2), ou o arquivo alterado está fora da pasta `aula-2-banco/app`. |
| **2. Publicar na Azure** aparece como *skipped* mesmo com os testes verdes | A variável não está configurada. Rode `./conectar-github.sh` de novo. |
| **2. Publicar na Azure** falha com `Unauthorized` ou `401` | A chave de publicação ficou velha (por exemplo, o app foi recriado). Rode `./conectar-github.sh` de novo e, na aba **Actions**, clique em **Re-run jobs**. |
| `Esta pasta é o repositório do professor` | Vocês clonaram o repositório original. Clone o **seu fork** (Missão 1, passo 3). |
| O mural mostra a versão antiga depois do pipeline verde | O app leva 1 ou 2 minutos para reiniciar. Espere e recarregue com `Ctrl + Shift + R`. |
| O mural mostra **Application Error** | Espere 2 minutos: o plano gratuito está acordando. |
| O login do GitHub não funciona no terminal | Confira se abriu **https://github.com/login/device** com a conta certa e se colou o código exato. |

---

## Cola rápida

| Termo | Em uma frase |
|---|---|
| **CI** (integração contínua) | A cada mudança, o código é testado automaticamente. |
| **CD** (entrega contínua) | Se os testes passarem, o código é publicado automaticamente. |
| **Pipeline** | A sequência de etapas (testar, publicar) que roda a cada commit. |
| **Segredo** | Valor sensível guardado criptografado no GitHub; ninguém consegue ler depois de salvo. |
| **Fork** | A sua cópia de um repositório de outra pessoa. |
