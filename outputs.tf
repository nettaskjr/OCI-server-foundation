output "instance_public_ip" {
  description = "IP Publico da instancia OCI Foundation (Acesso via ssh pra manutencao)"
  value       = oci_core_instance.foundation_vm.public_ip
}

output "instance_hostname" {
  description = "Hostname base da instancia fornecido no resolv.conf do OCI"
  value       = oci_core_instance.foundation_vm.create_vnic_details[0].hostname_label
}

output "instance_display_name" {
  description = "Nome de display da instancia na nuvem"
  value       = oci_core_instance.foundation_vm.display_name
}

output "tunnel_hostname" {
  description = "Hostname do tunel provisionado na cloudflare (ex: https://infra.nettask.com.br)"
  value       = "https://${var.foundation_subdomain}"
}

output "tunnel_id" {
  description = "Identificador unico do servidor da cloudflare associado ao app cloudflared rodante"
  value       = cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id
}

output "host_standard_paths" {
  description = "Caminhos padrões de onde salvar arquivos (contrato com devs e automacoes)"
  value = {
    apps    = "/opt/server/apps"
    data    = "/opt/server/data"
    logs    = "/opt/server/logs"
    backups = "/opt/server/backups"
    secrets = "/opt/server/secrets"
    shared  = "/opt/server/shared"
    compose = "/opt/server/compose"
  }
}
