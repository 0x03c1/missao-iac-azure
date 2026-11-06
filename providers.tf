# ============================================================
#  providers.tf — "Quais ferramentas o Terraform vai usar?"
# ============================================================
#  Um "provider" é o tradutor entre o Terraform e uma nuvem.
#  Aqui usamos dois:
#    - azurerm : fala com a Microsoft Azure
#    - random  : gera nomes aleatórios (nomes de storage são únicos no mundo todo)
# ============================================================

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

  # Preenchido automaticamente pelo ./embarque.sh (arquivo azure.auto.tfvars)
  subscription_id = var.subscription_id

  # Não deixa o Terraform tentar registrar dezenas de serviços na assinatura
  # (isso deixaria o primeiro apply muito lento). O ./embarque.sh já registrou
  # o único serviço que usamos nesta aula: Microsoft.Storage.
  resource_provider_registrations = "none"
}
