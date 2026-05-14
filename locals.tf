locals {
  # Convenção padrão de nomes com a padronização sugerida np PRD
  resource_prefix = "${var.project_name}-${var.environment}"

  # Etiquetas (tags) universais para facilitar custos e filtro
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    owner       = var.owner
    layer       = var.layer
  }
}
