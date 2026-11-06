# Variáveis: os "botões de ajuste" da infraestrutura.
# Não edite este arquivo. Para mudar valores, edite o terraform.tfvars.

variable "subscription_id" {
  description = "ID da assinatura Azure (definido pelo ./embarque.sh)."
  type        = string
}

variable "regiao" {
  description = "Região da Azure (o ./embarque.sh escolhe uma permitida para a conta)."
  type        = string
  default     = "eastus"
}

variable "nome_da_dupla" {
  description = "Nome exibido no site."
  type        = string
  default     = "Dupla Misteriosa"

  validation {
    condition     = can(regex("^[^<>%&\\\\?/]{1,40}$", var.nome_da_dupla))
    error_message = "Use de 1 a 40 caracteres, sem < > % & \\ ? /"
  }
}

variable "emoji" {
  description = "Emoji que representa a dupla."
  type        = string
  default     = "🚀"
}

variable "cor_de_fundo" {
  description = "Cor de fundo do site no formato #RRGGBB."
  type        = string
  default     = "#1e3a8a"

  validation {
    condition     = can(regex("^#[0-9a-fA-F]{6}$", var.cor_de_fundo))
    error_message = "A cor precisa estar no formato #RRGGBB, por exemplo \"#e11d48\"."
  }
}

variable "lema" {
  description = "Frase de efeito da dupla."
  type        = string
  default     = "Nossa infra é código!"
}

variable "quantidade_de_servidores" {
  description = "Quantos sites idênticos criar."
  type        = number
  default     = 1

  validation {
    condition     = var.quantidade_de_servidores >= 1 && var.quantidade_de_servidores <= 5
    error_message = "Escolha um número de 1 a 5."
  }
}
