# Missão IaC Azure

Aulas práticas de Cloud Computing com Terraform, Azure e GitHub Actions.

Tecnólogo em Análise e Desenvolvimento de Sistemas, Faculdade Senac.

## As aulas

| Aula | Missão | O que vocês vão construir | Guia |
|---|---|---|---|
| 1 | Servidores sob Ataque | Sites na Azure criados só com código, escalados e restaurados depois de um ataque | [aula-1-site/GUIA.md](aula-1-site/GUIA.md) |
| 2 | Memória da Rede | Um servidor de aplicação com banco de dados SQLite, e o que acontece com os dados num apagão | [aula-2-banco/GUIA.md](aula-2-banco/GUIA.md) |
| 3 | Pipeline | Um pipeline de CI/CD no GitHub que testa e publica o mural sozinho | [aula-3-cicd/GUIA.md](aula-3-cicd/GUIA.md) |

## Como rodar

Você não precisa instalar nada. Existem duas formas:

| Caminho | Onde | Login na Azure |
|---|---|---|
| **A** (usado em aula) | Azure Cloud Shell (https://shell.azure.com): o terminal do próprio portal da Azure | Automático |
| **B** (alternativa) | GitHub Codespaces | `az login --use-device-code` |

## O que é criado na Azure

| Aula | Recursos | Grupo de recursos | Custo |
|---|---|---|---|
| 1 | Contas de armazenamento com site estático | `rg-missao-iac` | Centavos |
| 2 e 3 | App Service (plano F1, gratuito) com Python 3.12 e SQLite em `/home` | `rg-missao-banco` | Zero no plano F1 |

Toda aula termina com a missão **Faxina**, que apaga tudo.

## Estrutura

| Pasta ou arquivo | Conteúdo |
|---|---|
| `aula-1-site/` | Terraform dos sites estáticos, páginas e scripts da Aula 1 |
| `aula-2-banco/` | Terraform do App Service, o app do mural (`app/`) e scripts da Aula 2 |
| `aula-3-cicd/` | Scripts que conectam o GitHub à Azure (Aula 3) |
| `.github/workflows/pipeline.yml` | O pipeline de CI/CD: testes e deploy do mural |
| `lib/` | Funções compartilhadas pelos scripts |
| `.devcontainer/` | Ambiente do Codespaces (Terraform e Azure CLI) |
| `extras/vm-da-aula-passada/` | A VM da aula de máquinas virtuais escrita em Terraform (só para leitura) |

## Rodar o mural no seu computador

Com Python 3 instalado:

```bash
cd aula-2-banco/app
python app.py              # abre em http://localhost:8000
python -m unittest -v      # roda os testes
```
