# Providers da Aula 2.
#   azurerm: fala com a Microsoft Azure
#   random:  gera um sufixo único para o nome do app (o endereço é único no mundo)
#   archive: empacota a pasta app/ num arquivo .zip para o deploy

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "azurerm" {
  features {}

  # Preenchido pelo ./embarque.sh no arquivo azure.auto.tfvars
  subscription_id = var.subscription_id

  # O ./embarque.sh já registra o serviço usado (Microsoft.Web).
  resource_provider_registrations = "none"
}
