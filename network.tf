resource "oci_core_vcn" "foundation_vcn" {
  compartment_id = var.oci_compartment_ocid

  cidr_blocks  = ["10.0.0.0/16"]
  display_name = "${local.resource_prefix}-vcn"
  dns_label    = "foundationvcn"

  freeform_tags = local.common_tags
}

resource "oci_core_internet_gateway" "foundation_igw" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.foundation_vcn.id

  enabled      = true
  display_name = "${local.resource_prefix}-igw"

  freeform_tags = local.common_tags
}

resource "oci_core_default_route_table" "foundation_route_table" {
  manage_default_resource_id = oci_core_vcn.foundation_vcn.default_route_table_id
  display_name               = "${local.resource_prefix}-default-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.foundation_igw.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "foundation_public_subnet" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.foundation_vcn.id

  cidr_block   = "10.0.1.0/24"
  display_name = "${local.resource_prefix}-public-subnet"
  dns_label    = "public"

  # Como a VCN usa o default route table implicitamente se não for forçado,
  # mas forçar a atribuição é boa prática.
  route_table_id = oci_core_vcn.foundation_vcn.default_route_table_id

  # Associa a SL criada no arquivo security.tf
  security_list_ids = [oci_core_security_list.foundation_sl.id]

  freeform_tags = local.common_tags
}
