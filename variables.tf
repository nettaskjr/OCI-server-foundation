# -----------------------------------------------------------------------------
# Variáveis de Configuração Gerais (Não Sensíveis)
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Nome do projeto foundation"
  type        = string
  default     = "nettask-foundation"
}

variable "owner" {
  description = "Dono ou equipe responsável pela infraestrutura"
  type        = string
  default     = "nettask"
}

variable "environment" {
  description = "Nome do ambiente (ex: prod, stg, dev)"
  type        = string
  default     = "prod"
}

variable "oci_region" {
  description = "Região da OCI a ser utilizada"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain na OCI (ex: AD-1 ou usar lookup dynamic). Em OCI Always Free, tipicamente depende da região e se existem slots."
  type        = string
  default     = ""
}

variable "instance_shape" {
  description = "Shape da instância na OCI"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Quantidade de OCPUs para a instância flex"
  type        = number
  default     = 1
}

variable "instance_memory_gb" {
  description = "Quantidade em Gb de Memória para a instância flex"
  type        = number
  default     = 6
}

variable "storage_size_gb" {
  description = "Tamanho do Block Storage do Boot Volume (GB)"
  type        = number
  default     = 50
}

variable "ubuntu_os_version" {
  description = "Versão do sistema operacional Ubuntu LTS a procurar na OCI"
  type        = string
  default     = "24.04"
}

variable "ubuntu_os_password" {
  description = "Senha do usuário ubuntu (utilizada para logar no Cockpit)"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR(s) permitidos para acessar a porta 22 (SSH). Default: 0.0.0.0/0 (transitório)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cloudflare_zone_name" {
  description = "O nome principal da Cloudflare Zone (exemplo: nettask.com.br)"
  type        = string
}

variable "cloudflare_e-mail_access" {
  description = "E-mail a ser usado para autenticação na Cloudflare"
  type        = string
}

variable "foundation_subdomain" {
  description = "Subdomínio principal a ser associado na Cloudflare (ex: infra.nettask.com.br)"
  type        = string
}

variable "aws_region" {
  description = "Região da AWS para armazenamento do backend do estado Terraform"
  type        = string
  default     = "us-east-1"
}

variable "layer" {
  description = "Layer do projeto"
  type        = string
}

# -----------------------------------------------------------------------------
# Variáveis Sensíveis (Credenciais a serem carregadas via *.tfvars)
# -----------------------------------------------------------------------------

variable "oci_tenancy_ocid" {
  description = "OCID da Tenancy"
  type        = string
  sensitive   = true
}

variable "oci_user_ocid" {
  description = "OCID do Usuário"
  type        = string
  sensitive   = true
}

variable "oci_fingerprint" {
  description = "Fingerprint da Chave de API"
  type        = string
  sensitive   = true
}

variable "oci_private_key_path" {
  description = "Caminho do arquivo de Chave Privada da API"
  type        = string
  sensitive   = true
}

variable "oci_compartment_ocid" {
  description = "OCID do Compartment na OCI"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "CloudFlare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "CloudFlare Account ID"
  type        = string
  sensitive   = true
}

variable "tunnel_secret" {
  description = "Uma senha complexa (em base64 no formato Cloudflare Tunnel Secret sugerido - min 32 chars) a ser usada para autenticar o cloudflared."
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Chave pública SSH a ser autorizada na conexão ao servidor (opcional: carregará default localmente se disponível)"
  type        = string
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "URL completa do Webhook do Discord"
  type        = string
  sensitive   = true
}
