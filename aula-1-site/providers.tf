# Providers: os "tradutores" entre o Terraform e cada plataforma.
#   azurerm: fala com a Microsoft Azure
#   random:  gera sufixos aleatórios (nomes de storage são únicos no mundo todo)

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
  }
}

provider "azurerm" {
  features {}

  # Preenchido pelo ./embarque.sh no arquivo azure.auto.tfvars
  subscription_id = var.subscription_id

  # O ./embarque.sh já registra o único serviço usado (Microsoft.Storage).
  # Sem esta linha, o primeiro apply tentaria registrar dezenas de serviços.
  resource_provider_registrations = "none"
}
