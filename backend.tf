terraform {
  backend "s3" {
    # Bucket properties vai ser passado por paramentros no terraform init
    # ou de uma maneira pre-configurada (por exemplo com um script bash exportando essas params)
    # State salvo em "OCI-server-foundation-dev/terraform.tfstate".
    # Lock nativo do S3 (requer Terraform >= 1.10) via objeto .tflock no mesmo bucket.
    key          = "OCI-server-foundation-dev/terraform.tfstate"
    region       = "us-east-1"
    bucket       = "terraform-nettask.com.br"
    encrypt      = true
    use_lockfile = true
  }
}
