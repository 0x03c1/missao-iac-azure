# Variáveis: os "botões de ajuste" da Aula 2.
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

variable "nome_do_mural" {
  description = "Título exibido no mural."
  type        = string
  default     = "Mural da Dupla Misteriosa"

  validation {
    condition     = length(var.nome_do_mural) >= 1 && length(var.nome_do_mural) <= 40
    error_message = "Use de 1 a 40 caracteres."
  }
}

variable "cor_neon" {
  description = "Cor neon de destaque do mural, no formato #RRGGBB."
  type        = string
  default     = "#00f0ff"

  validation {
    condition     = can(regex("^#[0-9a-fA-F]{6}$", var.cor_neon))
    error_message = "A cor precisa estar no formato #RRGGBB, por exemplo \"#ff2a6d\"."
  }
}

variable "banco_persistente" {
  description = "true: o SQLite fica em /home (sobrevive a reinícios). false: fica em /tmp (some ao reiniciar)."
  type        = bool
  default     = true
}

variable "plano" {
  description = "Plano do App Service: F1 é gratuito; B1 é pago (use só se o professor pedir)."
  type        = string
  default     = "F1"

  validation {
    condition     = contains(["F1", "B1"], var.plano)
    error_message = "Use \"F1\" (gratuito) ou \"B1\"."
  }
}
