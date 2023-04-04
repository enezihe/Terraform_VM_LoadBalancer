output "nic_id" {
  value = azurerm_network_interface.main.id
}
output "vm_id"{
    value = azurerm_virtual_machine.vm1.id
}
