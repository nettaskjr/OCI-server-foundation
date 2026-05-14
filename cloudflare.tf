# Localiza os dados da conta providos na zone name do tfvars
data "cloudflare_zone" "foundation_zone" {
  name = var.cloudflare_zone_name
}

# -----------------------------------------------------------------------------
# Cloudflare Zero Trust Tunnel
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared" "foundation_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "${local.resource_prefix}-tunnel"
  secret     = var.tunnel_secret
  config_src = "cloudflare"
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "foundation_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = var.foundation_subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
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

  # Aplicação do tipo self_hosted que será interceptada pela tela de login da CF
  type = "self_hosted"
}

resource "cloudflare_zero_trust_access_policy" "protected_apps_policy" {
  for_each       = cloudflare_zero_trust_access_application.protected_apps
  account_id     = var.cloudflare_account_id
  application_id = each.value.id
  precedence     = 1
  name           = "Default Allow Admin"
  decision       = "allow"

  # Exemplo mínimo: Restringe o acesso ao domínio definido na policy apenas para um admin
  include {
    email = [var.cloudflare_e-mail_access]
  }
}

# -----------------------------------------------------------------------------
# Roteamento Interno do Túnel (Ingress Rules)
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "foundation_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id

  config {
    # Rota 1: Tudo que chegar como ssh.nettask.com.br joga pra porta 22
    ingress_rule {
      hostname = "ssh.${var.cloudflare_zone_name}"
      service  = "ssh://localhost:22"
    }

    # Rota 2: Cockpit Server Management Panel
    ingress_rule {
      hostname = "cockpit.${var.cloudflare_zone_name}"
      service  = "http://localhost:9090"
    }

    # Rota 3: Netdata Observability Dashboard
    ingress_rule {
      hostname = "netdata.${var.cloudflare_zone_name}"
      service  = "http://localhost:19999"
    }

    # Rota 4: Traefik Dashboard
    ingress_rule {
      hostname = "traefik.${var.cloudflare_zone_name}"
      service  = "http://localhost:8080"
    }

    # Rota 5: O domínio curinga (Wildcard) joga pro Traefik na porta 80 (DEVE FICAR AQUI, POR ÚLTIMO ANTES DO FALLBACK)
    ingress_rule {
      hostname = "*.${var.cloudflare_zone_name}"
      service  = "http://localhost:80"
    }

    # Rota 6: Fallback obrigatório no final
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio SSH p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "ssh_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "ssh"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio Cockpit p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "cockpit_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "cockpit"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Aponta o Subdomínio Netdata p/ o Túnel)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "netdata_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "netdata"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Wildcard para o Traefik)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "wildcard_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "*"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Dashboard do Traefik)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "traefik_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "traefik"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# -----------------------------------------------------------------------------
# Cloudflare DNS CNAME Record (Status do Uptime Kuma)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "status_tunnel_record" {
  zone_id = data.cloudflare_zone.foundation_zone.id
  name    = "status"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
