# 🚀 Missão: Servidores sob Ataque

Aula prática de **Infraestrutura como Código (IaC)** com **Terraform** na **Microsoft Azure**.
Disciplina de Cloud Computing · Tecnólogo em Análise e Desenvolvimento de Sistemas · Faculdade Senac.

> Na aula passada, vocês criaram uma máquina virtual **clicando** no portal.
> Hoje vocês vão criar, escalar, recuperar e destruir infraestrutura **só com código**.

## 👩‍🎓 Sou aluno(a)

Abra o **[GUIA-DO-ALUNO.md](GUIA-DO-ALUNO.md)** e siga as missões.

Para esta aula, você só precisa:
- da conta Azure da faculdade;
- de um navegador.

**Não é preciso instalar nada:** tudo roda no Azure Cloud Shell.

## 👨‍🏫 Sou professor(a)

| Arquivo | Para quê |
|---|---|
| [CHECKLIST-VESPERA.md](CHECKLIST-VESPERA.md) | Preparação: mensagem para a turma, ensaio e conferência do laboratório |
| [ROTEIRO-DO-PROFESSOR.md](ROTEIRO-DO-PROFESSOR.md) | Roteiro minuto a minuto, com falas, resultados esperados e planos B |
| [extras/vm-da-aula-passada/main.tf](extras/vm-da-aula-passada/main.tf) | A VM da aula anterior escrita em Terraform, para projetar no fechamento |

## 🎮 As 6 missões

| # | Missão | Conceito |
|---|---|---|
| 1 | Embarque | Cloud Shell, autenticação, regiões |
| 2 | Primeiro site no ar | `init` → `plan` → `apply`, declarativo, idempotência |
| 3 | Personalize | Variáveis, mudança incremental (`~` e `-/+`) |
| 4 | Escale ×3 | `count`, escalabilidade |
| 5 | 🔥 Caos | Estado, *drift*, recuperação de desastre |
| 6 | Faxina | `destroy`, custo na nuvem |

## 🧱 O que é criado na Azure

Para cada "servidor", são criados:
- uma **conta de armazenamento** (Storage Account) com **site estático** habilitado;
- duas páginas HTML: a principal e a de erro.

Tudo fica dentro do grupo de recursos `rg-missao-iac`.

**Custo:** centavos de real, se tudo for destruído no fim da aula, o que a Missão 6 garante.

## 📁 Estrutura

```
.
├── main.tf               # O QUE existe na nuvem
├── variables.tf          # Os "botões de ajuste"
├── terraform.tfvars      # ← o ÚNICO arquivo que os alunos editam
├── outputs.tf            # O que aparece no fim do apply (links dos sites)
├── providers.tf          # Azure + random
├── site/                 # Modelos das páginas (index e erro)
├── embarque.sh           # Missão 1: prepara o Cloud Shell e escolhe uma região permitida
├── checkpoint.sh         # Confere cada missão e mostra a palavra-código
├── caos.sh               # Missão 5: derruba um servidor aleatório 😈
├── resgate.sh            # Plano B: limpa tudo se o estado se perder
└── extras/               # Material só para projetar
```
