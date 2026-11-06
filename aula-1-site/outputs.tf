# O que o Terraform mostra no final do apply.

output "sites" {
  description = "Endereços dos sites. Segure Ctrl (ou Cmd) e clique para abrir."
  value       = [for conta in azurerm_storage_account.site : conta.primary_web_endpoint]
}

output "contas_de_armazenamento" {
  description = "Nomes das contas de armazenamento (os servidores)."
  value       = azurerm_storage_account.site[*].name
}

output "grupo_de_recursos" {
  description = "Grupo onde tudo foi criado (procure este nome no portal)."
  value       = azurerm_resource_group.missao.name
}

output "nome_da_dupla" {
  description = "Nome publicado no site."
  value       = var.nome_da_dupla
}
