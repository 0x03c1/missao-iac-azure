# ============================================================
#  main.tf — "O QUE eu quero que exista na nuvem"
# ============================================================
#  Repare: em nenhum lugar dizemos "clique aqui, depois ali".
#  Só DECLARAMOS o resultado final. O Terraform descobre
#  sozinho o que precisa criar, mudar ou apagar.
# ============================================================

locals {
  # Etiquetas (tags) coladas em tudo que for criado — ajudam a achar e a cobrar.
  etiquetas = {
    missao     = "iac-senac"
    dupla      = var.nome_da_dupla
    criado_por = "terraform"
  }
}

# ------------------------------------------------------------
# 1) Grupo de recursos: a "pasta" que guarda tudo da missão.
#    (Atenção: os scripts lib/comum.sh usam este mesmo nome.)
# ------------------------------------------------------------
resource "azurerm_resource_group" "missao" {
  name     = "rg-missao-iac"
  location = var.regiao
  tags     = local.etiquetas
}

# ------------------------------------------------------------
# 2) Um sufixo aleatório para cada servidor.
#    Nomes de storage precisam ser únicos NO MUNDO INTEIRO.
# ------------------------------------------------------------
resource "random_string" "sufixo" {
  count   = var.quantidade_de_servidores
  length  = 8
  upper   = false
  special = false
}

# ------------------------------------------------------------
# 3) O "servidor": uma conta de armazenamento da Azure.
#    count = quantos iguais a este queremos.
# ------------------------------------------------------------
resource "azurerm_storage_account" "site" {
  count = var.quantidade_de_servidores

  name                     = "missao${random_string.sufixo[count.index].result}"
  resource_group_name      = azurerm_resource_group.missao.name
  location                 = azurerm_resource_group.missao.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(local.etiquetas, { servidor = tostring(count.index + 1) })
}

# ------------------------------------------------------------
# 4) Liga o modo "site estático" em cada servidor.
# ------------------------------------------------------------
resource "azurerm_storage_account_static_website" "site" {
  count = var.quantidade_de_servidores

  storage_account_id = azurerm_storage_account.site[count.index].id
  index_document     = "index.html"
  error_404_document = "erro.html"
}

# ------------------------------------------------------------
# 5) A página principal (index.html) de cada servidor.
#    O conteúdo vem do modelo site/index.html.tftpl
# ------------------------------------------------------------
resource "azurerm_storage_blob" "pagina" {
  count = var.quantidade_de_servidores

  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.site[count.index].name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html; charset=utf-8"

  source_content = templatefile("${path.module}/site/index.html.tftpl", {
    nome   = var.nome_da_dupla
    emoji  = var.emoji
    cor    = var.cor_de_fundo
    lema   = var.lema
    numero = count.index + 1
    regiao = var.regiao
  })

  depends_on = [azurerm_storage_account_static_website.site]
}

# ------------------------------------------------------------
# 6) A página de erro — aparece quando o site é "derrubado".
# ------------------------------------------------------------
resource "azurerm_storage_blob" "erro" {
  count = var.quantidade_de_servidores

  name                   = "erro.html"
  storage_account_name   = azurerm_storage_account.site[count.index].name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html; charset=utf-8"

  source_content = templatefile("${path.module}/site/erro.html.tftpl", {
    nome   = var.nome_da_dupla
    numero = count.index + 1
  })

  depends_on = [azurerm_storage_account_static_website.site]
}
