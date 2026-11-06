# Missão: Servidores sob Ataque

Aula prática de Infraestrutura como Código (IaC) com Terraform na Microsoft Azure.

Disciplina de Cloud Computing, Tecnólogo em Análise e Desenvolvimento de Sistemas, Faculdade Senac.

> Na aula passada, vocês criaram uma máquina virtual clicando no portal. Hoje vão criar, escalar, recuperar e destruir infraestrutura só com código.

## Para alunos

Abra o [GUIA-DO-ALUNO.md](GUIA-DO-ALUNO.md) e siga as missões. Você não precisa instalar nada. Existem duas formas de rodar:

| Caminho | Onde | Login na Azure |
|---|---|---|
| **A** (usado em aula) | Azure Cloud Shell: o terminal do próprio portal da Azure | Automático |
| **B** (alternativa) | GitHub Codespaces | `az login --use-device-code` |

## Para professores

| Arquivo | Para quê |
|---|---|
| [CHECKLIST-VESPERA.md](CHECKLIST-VESPERA.md) | Mensagem para a turma, ensaio completo e conferência do laboratório |
| [ROTEIRO-DO-PROFESSOR.md](ROTEIRO-DO-PROFESSOR.md) | Roteiro minuto a minuto, com falas, resultados esperados e planos B |
| [extras/vm-da-aula-passada/main.tf](extras/vm-da-aula-passada/main.tf) | A VM da aula anterior escrita em Terraform, para projetar no fechamento |

## As 6 missões

| # | Missão | Conceito |
|---|---|---|
| 1 | Embarque | Terminal na nuvem, autenticação, regiões |
| 2 | Primeiro site no ar | `init`, `plan`, `apply`, código declarativo, idempotência |
| 3 | Personalize | Variáveis, mudança incremental |
| 4 | Escale para 3 | `count`, escalabilidade |
| 5 | Caos | Estado, drift, recuperação de desastre |
| 6 | Faxina | `destroy`, custo na nuvem |

## O que é criado na Azure

Cada "servidor" é uma conta de armazenamento (Storage Account) com site estático habilitado e duas páginas HTML: a principal e a de erro. Tudo fica dentro do grupo de recursos `rg-missao-iac`.

O custo é de centavos, desde que tudo seja destruído no fim da aula, que é justamente a Missão 6.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `main.tf` | O que existe na nuvem |
| `variables.tf` | Os "botões de ajuste" |
| `terraform.tfvars` | O único arquivo que os alunos editam |
| `outputs.tf` | O que aparece no fim do apply (links dos sites) |
| `providers.tf` | Providers Azure e random |
| `site/` | Modelos das páginas: principal e de erro |
| `embarque.sh` | Prepara o terminal e escolhe uma região permitida para a conta |
| `checkpoint.sh` | Confere cada missão e mostra a palavra-código |
| `caos.sh` | Derruba um servidor aleatório |
| `resgate.sh` | Limpa tudo se o estado do Terraform se perder |
| `.devcontainer/` | Ambiente do Codespaces (Terraform e Azure CLI) |
| `extras/` | Material só para projetar |
