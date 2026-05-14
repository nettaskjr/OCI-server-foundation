terraform {
  backend "s3" {
    # Bucket properties vai ser passado por paramentros no terraform init
    # ou de uma maneira pre-configurada (por exemplo com um script bash exportando essas params)
    # Aqui deixamos a chave generica. O state ficara salvo em um S3 path "foundation/terraform.tfstate"
    key     = "foundation/terraform.tfstate"
    region  = "us-east-1"
    bucket  = "terraform-nettask.com.br"
    encrypt = true
  }
}
