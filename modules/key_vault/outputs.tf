output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.optscale_kv.id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.optscale_kv.name
}

output "db_password_secret_name" {
  description = "The name of the database password secret."
  value       = azurerm_key_vault_secret.db_password_secret.name
}