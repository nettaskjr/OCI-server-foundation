# AGENTS.md — OCI-server-foundation

## Arquitetura

Mono-config do Terraform que provisiona uma VM Always-Free na OCI com Cloudflare Zero Trust, Docker, Traefik, Grafana/Loki/Promtail, Cockpit, Netdata, Uptime Kuma e uma página de portal.

Três provedores configurados em `providers.tf`:
- `oracle/oci ~> 5.0`
- `cloudflare/cloudflare ~> 5.0` (nomes de recursos v5, veja abaixo)
- `hashicorp/aws ~> 5.0` (apenas backend S3)

State no S3 (`bucket terraform-nettask.com.br`, `us-east-1`). Init requer config de backend ou script.

## Linguagem
Toda a linguagem tanto no codigo quanto nas respostas da llm devem ser em pt-br

## Comandos principais

```sh
# Init com config de backend
terraform init -backend-config="bucket=terraform-nettask.com.br" \
               -backend-config="key=OCI-server-foundation-dev/terraform.tfstate" \
               -backend-config="region=us-east-1"

# Validar, planejar, aplicar
terraform validate
terraform plan
terraform apply
```

## Mapeamento de recursos Cloudflare v5

O provedor foi migrado de v4 → v5. NÃO use os nomes antigos v4:

| v4 (errado) | v5 (correto) |
|---|---|
| `cloudflare_record` | `cloudflare_dns_record` (adicione `ttl = 1` quando `proxied = true`) |
| `cloudflare_tunnel` | `cloudflare_zero_trust_tunnel_cloudflared` |
| `cloudflare_tunnel_config` | `cloudflare_zero_trust_tunnel_cloudflared_config` (usa sintaxe de atributo `config = { ingress = [...] }`) |
| `cloudflare_access_application` | `cloudflare_zero_trust_access_application` (políticas são inline `policies = [{...}]`) |
| `cloudflare_access_policy` | Removido — mesclar no bloco `policies` do application |
| `data.cloudflare_zone.name` | `data.cloudflare_zone.filter = { name = ... }` |
| `resource.cloudflare_tunnel.secret` | `tunnel_secret` |

## Variáveis obrigatórias

- **Não sensíveis**: em `terraform.auto.tfvars` (padrões gitignore: `*.tfvars` mas NÃO `*.auto.tfvars`)
- **Segredos sensíveis**: em `terraform.tfvars` (gitignore); use `terraform.tfvars.example` como modelo
- A variável `ssh_public_key` aceita tanto caminho para um arquivo `.pub` quanto o conteúdo da chave como string (detecção automática em `compute.tf:58`)
- `tunnel_secret` deve ter ≥32 chars base64; gere com `openssl rand -base64 32`

## Fluxo de provisionamento

1. Terraform cria VCN + subnet + security list + internet gateway + route table na OCI
2. Cria tunnel Cloudflare, registros DNS CNAME (apontando para `${tunnel_id}.cfargotunnel.com`) e aplicações Access
3. Cria instância de compute na OCI com cloud-init que:
   - Instala Docker, cloudflared, Cockpit, Netdata
   - Configura cloudflared como serviço systemd
   - Inicia Traefik, Grafana/Loki/Promtail, Uptime Kuma, Portal via docker-compose
4. `lifecycle.ignore_changes = [metadata]` está definido na instância — alterações em user_data não disparam recriação

## Modelo de acesso

- Nenhuma porta SSH aberta na security list (apenas ICMP, ingress SSH comentado)
- Acesso SSH via `ssh ubuntu@ssh.<zone>` através do Cloudflare Tunnel + política de Access
- Todos os serviços web atrás do Cloudflare Access (autenticação por email)
- Cockpit, Netdata, Traefik, Status via subdomínios CNAME separados

## Notas

- Região OCI padrão: `sa-saopaulo-1`, shape A1.Flex (ARM64)
- Binário cloudflared é ARM64 (`cloudflared-linux-arm64.deb`)
- `terraform.auto.tfvars` contém defaults não sensíveis; nunca commitar `terraform.tfvars` sensível
- `scripts/init.sh` fornece um comando de init conveniente (usa uma chave de backend ligeiramente diferente de `backend.tf`)
- `scripts/teste_webhook.sh` espera um arquivo `.env` ao lado com `DISCORD_WEBHOOK_URL`

## Estrutura de pastas criadas que deveram ser seguidas a risca

- /opt/server/apps
- /opt/server/data
- /opt/server/logs
- /opt/server/backups
- /opt/server/secrets
- /opt/server/shared
- /opt/server/compose
