output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}


output "module_vm_id"{
    value = module.vm2.vm_id
}

