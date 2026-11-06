# ============================================================
#  🖥️  A VM DA AULA PASSADA… EM CÓDIGO
# ============================================================
#  ⚠️  PARA PROJETAR NO FECHAMENTO — NÃO É PARA APLICAR EM AULA.
#
#  Cada bloco abaixo corresponde a uma ABA/CAMPO que vocês
#  preencheram clicando no portal da Azure ao criar a VM.
#  Compare: quantos cliques foram? Aqui são ~80 linhas que
#  qualquer pessoa da equipe pode ler, revisar e repetir.
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" { type = string }
variable "regiao" {
  type    = string
  default = "eastus"
}
variable "chave_publica_ssh" {
  description = "Conteúdo da sua chave pública SSH (ex.: ~/.ssh/id_rsa.pub)"
  type        = string
}

# Portal → aba "Básico" → "Grupo de recursos" → "Criar novo"
resource "azurerm_resource_group" "aula" {
  name     = "rg-vm-aula-passada"
  location = var.regiao
}

# Portal → aba "Rede" → "Rede virtual" → "Criar nova"
resource "azurerm_virtual_network" "rede" {
  name                = "vnet-aula"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aula.location
  resource_group_name = azurerm_resource_group.aula.name
}

# Portal → aba "Rede" → "Sub-rede"
resource "azurerm_subnet" "sub_rede" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.aula.name
  virtual_network_name = azurerm_virtual_network.rede.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Portal → aba "Rede" → "IP público"
resource "azurerm_public_ip" "ip" {
  name                = "ip-vm-aula"
  location            = azurerm_resource_group.aula.location
  resource_group_name = azurerm_resource_group.aula.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Portal → aba "Básico" → "Portas de entrada públicas" → SSH (22)
resource "azurerm_network_security_group" "firewall" {
  name                = "nsg-vm-aula"
  location            = azurerm_resource_group.aula.location
  resource_group_name = azurerm_resource_group.aula.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Criado "escondido" pelo portal: a placa de rede da VM
resource "azurerm_network_interface" "placa" {
  name                = "nic-vm-aula"
  location            = azurerm_resource_group.aula.location
  resource_group_name = azurerm_resource_group.aula.name

  ip_configuration {
    name                          = "interna"
    subnet_id                     = azurerm_subnet.sub_rede.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "liga_firewall" {
  network_interface_id      = azurerm_network_interface.placa.id
  network_security_group_id = azurerm_network_security_group.firewall.id
}

# Portal → aba "Básico" → nome, imagem, tamanho, usuário e chave SSH
#          aba "Discos" → tipo de disco do SO
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-aula-passada"
  location              = azurerm_resource_group.aula.location
  resource_group_name   = azurerm_resource_group.aula.name
  size                  = "Standard_B1s"
  admin_username        = "aluno"
  network_interface_ids = [azurerm_network_interface.placa.id]

  admin_ssh_key {
    username   = "aluno"
    public_key = var.chave_publica_ssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# Portal → tela "Visão geral" → "Endereço IP público"
output "ip_publico" {
  value = azurerm_public_ip.ip.ip_address
}
