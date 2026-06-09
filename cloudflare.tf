# Localiza os dados da conta providos na zone name do tfvars
data "cloudflare_zone" "foundation_zone" {
  filter = {
    name = var.cloudflare_zone_name
  }
}

# -----------------------------------------------------------------------------
# Cloudflare Zero Trust Tunnel
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared" "foundation_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "${local.resource_prefix}-tunnel"
  config_src = "cloudflare"
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "foundation_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = var.foundation_subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# -----------------------------------------------------------------------------
# Cloudflare Access (Opcional - Exemplo de Proteção no Hostname)
# -----------------------------------------------------------------------------

locals {
  protected_apps = toset([
    var.foundation_subdomain,
    "cockpit.${var.cloudflare_zone_name}",
    "netdata.${var.cloudflare_zone_name}",
    "traefik.${var.cloudflare_zone_name}",
    "status.${var.cloudflare_zone_name}"
  ])
}

resource "cloudflare_zero_trust_access_application" "protected_apps" {
  for_each         = local.protected_apps
  account_id       = var.cloudflare_account_id
  name             = "${local.resource_prefix}-protection-${replace(each.key, ".", "-")}"
  domain           = each.key
  session_duration = "24h"
  type             = "self_hosted"

    policies = [{
      name       = "Default Allow Admin"
      decision   = "allow"
      precedence = 1
      include = [{
        email = {
          email = var.cloudflare_email_access
        }
      }]
    }]
}

# -----------------------------------------------------------------------------
# Roteamento Interno do Túnel (Ingress Rules)
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "foundation_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id

  config = {
    # Rota 1: Tudo que chegar como ssh.nettask.com.br joga pra porta 22
    ingress = [
      {
        hostname = "ssh.${var.cloudflare_zone_name}"
        service  = "ssh://localhost:22"
      },
      # Rota 2: Cockpit Server Management Panel
      {
        hostname = "cockpit.${var.cloudflare_zone_name}"
        service  = "http://localhost:9090"
      },
      # Rota 3: Netdata Observability Dashboard
      {
        hostname = "netdata.${var.cloudflare_zone_name}"
        service  = "http://localhost:19999"
      },
      # Rota 4: Traefik Dashboard
      {
        hostname = "traefik.${var.cloudflare_zone_name}"
        service  = "http://localhost:8080"
      },
      # Rota 5: O domínio curinga (Wildcard) joga pro Traefik na porta 80 (DEVE FICAR AQUI, POR ÚLTIMO ANTES DO FALLBACK)
      {
        hostname = "*.${var.cloudflare_zone_name}"
        service  = "http://localhost:80"
      },
      # Rota 6: Fallback obrigatório no final
      {
        service = "http_status:404"
      }
    ]
  }
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio SSH p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "ssh_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "ssh"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio Cockpit p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "cockpit_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "cockpit"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio Netdata p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "netdata_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "netdata"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Wildcard para o Traefik)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "wildcard_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "*"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Dashboard do Traefik)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "traefik_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "traefik"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Status do Uptime Kuma)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "status_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "status"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
