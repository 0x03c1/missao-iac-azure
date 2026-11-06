# O QUE deve existir na nuvem na Aula 2:
# um servidor de aplicação (App Service) rodando o mural em Python,
# com o banco SQLite guardado num disco que sobrevive a reinícios.

locals {
  etiquetas = {
    missao     = "iac-senac-aula-2"
    criado_por = "terraform"
  }

  # /home é o disco persistente do App Service. /tmp é apagado quando o app reinicia.
  caminho_do_banco = var.banco_persistente ? "/home/data/mural.db" : "/tmp/mural.db"

  # Impressão digital do código: muda quando algum arquivo da pasta app/ muda,
  # e isso faz o Terraform publicar o código novo.
  arquivos_do_app = fileset("${path.module}/app", "*.{py,txt}")
  hash_do_app     = sha1(join("", [for arquivo in sort(local.arquivos_do_app) : filesha1("${path.module}/app/${arquivo}")]))
}

# 1. Grupo de recursos. O nome também é usado nos scripts desta pasta.
resource "azurerm_resource_group" "aula2" {
  name     = "rg-missao-banco"
  location = var.regiao
  tags     = local.etiquetas
}

# 2. Sufixo aleatório: o endereço do app precisa ser único no mundo.
resource "random_string" "sufixo" {
  length  = 8
  upper   = false
  special = false
}

# 3. Plano do App Service: a "máquina" onde o app roda. F1 é gratuito.
resource "azurerm_service_plan" "plano" {
  name                = "plano-mural"
  resource_group_name = azurerm_resource_group.aula2.name
  location            = azurerm_resource_group.aula2.location
  os_type             = "Linux"
  sku_name            = var.plano
  tags                = local.etiquetas
}

# 4. Pacote .zip com o código da pasta app/.
data "archive_file" "app" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/.pacote/mural-${local.hash_do_app}.zip"
  excludes    = ["__pycache__", "mural.db", "VERSAO"]
}

# 5. O app web: Python 3.12, com o código publicado a partir do .zip.
resource "azurerm_linux_web_app" "mural" {
  name                = "mural-${random_string.sufixo.result}"
  resource_group_name = azurerm_resource_group.aula2.name
  location            = azurerm_resource_group.aula2.location
  service_plan_id     = azurerm_service_plan.plano.id
  https_only          = true
  zip_deploy_file     = data.archive_file.app.output_path

  # Publicação por "publish profile" (usada na Aula 3) precisa disto ligado.
  webdeploy_publish_basic_authentication_enabled = true
  ftp_publish_basic_authentication_enabled       = false

  site_config {
    always_on        = false # o plano F1 não permite "sempre ligado"
    ftps_state       = "Disabled"
    app_command_line = "gunicorn --bind=0.0.0.0 --timeout 600 app:app"

    application_stack {
      python_version = "3.12"
    }
  }

  # Variáveis de ambiente lidas pelo app.py
  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    WEBSITE_WEBDEPLOY_USE_SCM      = "true"
    CAMINHO_DO_BANCO               = local.caminho_do_banco
    BANCO_PERSISTENTE              = var.banco_persistente ? "sim" : "nao"
    NOME_DO_MURAL                  = var.nome_do_mural
    COR_NEON                       = var.cor_neon
  }

  tags = local.etiquetas
}
