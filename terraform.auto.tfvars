# -----------------------------------------------------------------------------
# Variáveis de Configuração do Ambiente Foundation
# -----------------------------------------------------------------------------

project_name = "OCI-server-foundation"
environment  = "dev"
oci_region   = "sa-saopaulo-1"
layer        = "foundation"
owner        = "nettask"

# A1.Flex é comumente parte do pacote Always Free em aarch64
instance_shape     = "VM.Standard.A1.Flex"
instance_ocpus     = 1
instance_memory_gb = 6
storage_size_gb    = 50

# Usa versão LTS (ex: 24.04 Noble Numbat ou 22.04 Jammy Jellyfish)
ubuntu_os_version = "24.04"

ssh_allowed_cidr_blocks = ["0.0.0.0/0"]

# Variáveis integradas Cloudflare 
# (Substituir pelos seus dados se usar diferente)
cloudflare_zone_name     = "nettask.com.br"
foundation_subdomain     = "infra.nettask.com.br"
cloudflare_e-mail_access = "nestor.junior@gmail.com"

# região da aws para gravação do tfstate
aws_region = "us-east-1"


