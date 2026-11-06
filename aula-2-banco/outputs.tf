# O que o Terraform mostra no final do apply.

output "endereco_do_mural" {
  description = "Endereço do mural. Segure Ctrl (ou Cmd) e clique para abrir."
  value       = "https://${azurerm_linux_web_app.mural.default_hostname}"
}

output "nome_do_app" {
  description = "Nome do app no App Service (usado na Aula 3)."
  value       = azurerm_linux_web_app.mural.name
}

output "grupo_de_recursos" {
  description = "Grupo onde tudo foi criado (procure este nome no portal)."
  value       = azurerm_resource_group.aula2.name
}

output "caminho_do_banco" {
  description = "Onde o arquivo SQLite fica guardado no servidor."
  value       = local.caminho_do_banco
}
