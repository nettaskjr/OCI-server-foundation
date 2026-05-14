resource "oci_core_security_list" "foundation_sl" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.foundation_vcn.id

  display_name = "${local.resource_prefix}-sl"

  # Regras de Saída
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all" # Permitir todo o tráfego de saída (ex: updates, cloudflare)
    description = "Permitir todo o tráfego de saída para a internet"
  }

  # Regras de Entrada
  # SSH
  /*   dynamic "ingress_security_rules" {
    for_each = var.ssh_allowed_cidr_blocks
    content {
      source      = ingress_security_rules.value
      protocol    = "6" # TCP
      description = "Permitir acesso SSH na porta 22 (temporário para auditoria)"

      tcp_options {
        min = 22
        max = 22
      }
    }
  } */

  # ICMP comum no OCI (Ping)
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "1" # ICMP
    description = "Permitir ICMP base (Tipo 3 Cod 4 pra MTU discovery e fragments)"

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    source      = "10.0.0.0/16"
    protocol    = "1" # ICMP
    description = "Permitir ICMP interno dentro da VCN"

    icmp_options {
      type = 3
    }
  }

  freeform_tags = local.common_tags
}
