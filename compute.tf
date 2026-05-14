# -----------------------------------------------------------------------------
# Fonte de Dados Lookup (Localizar Availability Domain e Imagem Ubuntu)
# -----------------------------------------------------------------------------

# Retorna uma lista de Availability Domains da regiao atual
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_compartment_ocid
}

# Escolhe a última imagem do Ubuntu LTS Baseada baseada na regex
data "oci_core_images" "ubuntu_image" {
  compartment_id           = var.oci_compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.ubuntu_os_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-${var.ubuntu_os_version}-.*$"]
    regex  = true
  }
}

# -----------------------------------------------------------------------------
# Recurso Computacional (Compute Instance)
# -----------------------------------------------------------------------------

resource "oci_core_instance" "foundation_vm" {
  # Usa AD explicito, ou se em branco mapeia automaticamente pro ad-1 da lista de ADs devolvidos pelo localizador
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.oci_compartment_ocid
  display_name        = "${local.resource_prefix}-vm"
  shape               = var.instance_shape

  # Configuração pro shape Flex
  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.foundation_public_subnet.id
    display_name     = "Primaryvnic"
    assign_public_ip = true
    hostname_label   = local.resource_prefix
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_image.images[0].id
    boot_volume_size_in_gbs = var.storage_size_gb
  }

  metadata = {
    # Suporta tanto passar o percurso do arquivo (ex: ~/.ssh/id_rsa.pub) quanto a string direta
    ssh_authorized_keys = length(regexall("^(ssh-|ecdsa-)", var.ssh_public_key)) > 0 ? var.ssh_public_key : file(pathexpand(var.ssh_public_key))

    # Define o template file em shell script com injecao do token gerado pela cloudflare tf
    user_data = base64encode(templatefile("${path.module}/userdata/cloud-init.yaml.tftpl", {
      tunnel_token        = cloudflare_zero_trust_tunnel_cloudflared.foundation_tunnel.tunnel_token
      cockpit_url         = "cockpit.${var.cloudflare_zone_name}"
      ubuntu_os_password  = var.ubuntu_os_password
      base_domain         = var.cloudflare_zone_name
      discord_webhook_url = var.discord_webhook_url
      portal_url          = var.foundation_subdomain

      # Arquivos Externos Carregados
      traefik_compose_yml       = file("${path.module}/userdata/files/traefik-compose.yml.tftpl")
      cockpit_conf              = templatefile("${path.module}/userdata/files/cockpit.conf.tftpl", { cockpit_url = "cockpit.${var.cloudflare_zone_name}" })
      loki_config_yaml          = file("${path.module}/userdata/files/loki-config.yaml.tftpl")
      promtail_config_yaml      = file("${path.module}/userdata/files/promtail-config.yaml.tftpl")
      grafana_datasource_loki   = file("${path.module}/userdata/files/grafana-datasource-loki.yaml.tftpl")
      grafana_provider_yaml     = file("${path.module}/userdata/files/grafana-dashboard.yml.tftpl")
      grafana_logs_json         = file("${path.module}/userdata/files/grafana-logs.json.tftpl")
      grafana_contactpoints     = templatefile("${path.module}/userdata/files/grafana-contactpoints.yaml.tftpl", { discord_webhook_url = var.discord_webhook_url })
      observability_compose_yml = templatefile("${path.module}/userdata/files/observability-compose.yml.tftpl", { ubuntu_os_password = var.ubuntu_os_password, base_domain = var.cloudflare_zone_name })
      uptime_kuma_compose_yml   = templatefile("${path.module}/userdata/files/uptime-kuma-compose.yml.tftpl", { base_domain = var.cloudflare_zone_name })
      portal_html               = templatefile("${path.module}/userdata/files/portal.html.tftpl", { base_domain = var.cloudflare_zone_name })
      portal_compose_yml        = templatefile("${path.module}/userdata/files/portal-compose.yml.tftpl", { portal_url = var.foundation_subdomain })
    }))
  }

  freeform_tags = local.common_tags

  lifecycle {
    ignore_changes = [metadata]
  }
}
