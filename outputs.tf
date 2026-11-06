# ============================================================
#  outputs.tf — "O que o Terraform mostra no final"
# ============================================================

output "sites" {
  description = "Endereços dos seus sites. Segure Ctrl (ou Cmd) e clique para abrir."
  value       = [for conta in azurerm_storage_account.site : conta.primary_web_endpoint]
}

output "contas_de_armazenamento" {
  description = "Nomes das contas de armazenamento (os 'servidores')."
  value       = azurerm_storage_account.site[*].name
}

output "grupo_de_recursos" {
  description = "Onde tudo foi criado (procure por este nome no portal da Azure)."
  value       = azurerm_resource_group.missao.name
}

output "nome_da_dupla" {
  description = "Nome atualmente publicado."
  value       = var.nome_da_dupla
}
