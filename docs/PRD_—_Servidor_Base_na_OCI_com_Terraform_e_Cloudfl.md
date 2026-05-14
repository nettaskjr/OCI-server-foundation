<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# PRD — Servidor Base na OCI com Terraform e Cloudflare

## Visão geral

Este PRD define a criação de um servidor base reutilizável na Oracle Cloud Infrastructure (OCI), provisionado exclusivamente com Terraform e preparado para servir como fundação para projetos futuros de aplicações. A proposta separa explicitamente a camada de infraestrutura da camada de aplicação, reduzindo acoplamento entre criação do servidor e instalação de workloads, em linha com boas práticas de organização entre infraestrutura e código de aplicação e com o uso de módulos reutilizáveis em Terraform.[^1][^2][^3]

O servidor base terá foco em infraestrutura estável, repetível e extensível, permitindo que novos projetos consumam essa fundação sem precisar recriar compute, rede, DNS, túnel, políticas básicas de acesso e convenções operacionais. Essa abordagem é compatível com estruturas GitOps e com repositórios separados para infraestrutura e aplicações, o que ajuda a manter ciclos de mudança distintos e contratos mais claros entre as camadas.[^4][^5][^1]

## Objetivo do produto

Entregar um projeto Terraform dedicado à criação de um servidor base na OCI, com integração à Cloudflare para DNS e acesso seguro por tunnel, pronto para receber aplicações futuras sem alterar a infraestrutura principal. O produto deve ser versionável, modular, orientado a reuso e capaz de servir como repositório foundation para múltiplos projetos dependentes.[^2][^1]

## Problema que o produto resolve

Hoje, misturar infraestrutura do servidor com aplicações específicas torna a evolução mais arriscada, aumenta dependências entre projetos e dificulta reaproveitamento do ambiente base. Separar o servidor foundation das aplicações reduz a necessidade de reprovisionar a infraestrutura a cada novo projeto, simplifica estados Terraform e permite evolução independente entre camadas com menos risco operacional.[^3][^6][^1]

## Escopo

Este PRD cobre a criação de um servidor único na OCI, incluindo rede básica, instância compute, parâmetros de sistema operacional, bootstrap inicial, instalação do Docker como runtime base, integração com Cloudflare Tunnel, configuração de DNS e políticas iniciais de Zero Trust, além da organização do código Terraform, convenções de nomenclatura, backend remoto de estado na AWS e separação entre variáveis sensíveis e não sensíveis.[^1][^3]

O projeto não inclui aplicações embarcadas, bancos de dados, CloudBeaver, stacks de observabilidade, rotinas específicas de backup de aplicação, Kubernetes, balanceadores, auto scaling ou componentes de negócio. O foco é entregar a base de infraestrutura sobre a qual outros repositórios possam instalar seus próprios serviços de forma independente.[^4][^1]

## Princípios da solução

- Separação entre infraestrutura base e aplicações, com contratos claros entre os repositórios.[^1][^4]
- Reuso por meio de módulos e parâmetros, evitando duplicação de código Terraform.[^7][^2]
- Imutabilidade operacional: o host deve nascer configurado por `cloud-init` e templates versionados, reduzindo mudanças manuais recorrentes.[^3]
- Estado remoto do Terraform isolado e protegido em bucket S3 previamente criado, com operação controlada para evitar concorrência entre execuções.[^3]
- Cloudflare como camada padrão de publicação e proteção de acesso para serviços expostos futuramente.[^8][^9]


## Usuários e cenários de uso

O usuário principal é o mantenedor da infraestrutura, que precisa criar uma fundação padronizada para hospedar projetos futuros em repositórios separados. O cenário esperado é: primeiro provisionar o servidor-base; depois, em um repositório de aplicação, consumir esse servidor via SSH, Docker, arquivos de configuração, pipelines ou automação complementar sem modificar a definição da infraestrutura central.[^2][^4][^1]

## Requisitos funcionais

- Provisionar uma instância OCI Compute por Terraform.[^3]
- Permitir parametrização da região OCI em `terraform.auto.tfvars`.[^3]
- Permitir parametrização do availability domain em `terraform.auto.tfvars`, ou resolução por data source quando aplicável.[^3]
- Utilizar Ubuntu LTS como sistema operacional, com versão definida em variável não sensível.[^3]
- Instalar Docker no bootstrap da instância, sem subir aplicações de negócio por padrão.[^1]
- Criar rede básica na OCI com VCN, subnet pública e regras mínimas de segurança.[^3]
- Integrar o servidor com Cloudflare Tunnel para futura publicação segura de serviços.[^10][^11]
- Criar registros DNS necessários na Cloudflare conforme parâmetros declarados.[^10]
- Permitir ativação de políticas Cloudflare Access para controlar quem pode acessar serviços publicados por hostname.[^9][^8]
- Manter a porta 22 aberta temporariamente durante a fase de validação operacional.[^3]
- Armazenar o `tfstate` remoto em bucket S3 na AWS, na região `us-east-1`, usando o bucket já existente definido nas variáveis do ambiente.[^3]


## Requisitos não funcionais

- A infraestrutura deve ser idempotente e previsível em `terraform plan` e `terraform apply`.[^3]
- O código deve ser organizado para reuso e expansão futura, preferencialmente com módulos e arquivos separados por domínio técnico.[^2][^1]
- Variáveis sensíveis devem ficar fora do versionamento Git.[^1]
- O servidor deve ser tratado como foundation estável, com mudanças manuais reduzidas ao mínimo.[^3]
- O projeto deve expor contratos úteis para repositórios consumidores, como IP, hostname, paths base e parâmetros de acesso.[^1]


## Arquitetura proposta

A solução será composta por uma instância única OCI Compute associada a uma VCN com subnet pública. A opção por subnet pública atende ao requisito de validação e simplifica bootstrap inicial, mantendo o acesso administrativo temporário por SSH, enquanto o padrão de publicação futura de serviços será feito por Cloudflare Tunnel em vez de exposição direta desnecessária na internet.[^11][^9][^3]

No bootstrap, o host instalará Docker Engine, utilitários básicos de sistema e o agente `cloudflared`, mas não executará aplicações embarcadas por padrão. Isso transforma o servidor em um runtime foundation para workloads posteriores, mantendo a base homogênea e reutilizável para diferentes projetos.[^1][^3]

A integração com a Cloudflare terá dois papéis distintos: o túnel, que estabelece conectividade do servidor com a borda Cloudflare, e as políticas Access, que controlam quem pode acessar os hostnames publicados. O túnel por si só não substitui políticas de acesso; ele resolve conectividade, enquanto Zero Trust Access adiciona autenticação e autorização na frente do serviço publicado.[^8][^9][^10]

## Availability domain

Na OCI, a região representa a localização geográfica e o availability domain representa uma zona de disponibilidade dentro dessa região. Em um cenário com uma única VM, o availability domain não muda a lógica da solução, mas pode ser necessário como parâmetro de criação da instância, razão pela qual deve ser tratado como variável do ambiente ou resolvido dinamicamente quando isso simplificar o projeto.[^12][^13]

## Organização do repositório

A estrutura sugerida do repositório é a seguinte:

```text
terraform/
├── backend.tf
├── versions.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── network.tf
├── compute.tf
├── security.tf
├── cloudflare.tf
├── outputs.tf
├── userdata/
│   └── cloud-init.yaml.tftpl
├── terraform.tfvars
├── terraform.auto.tfvars
└── README.md
```

Essa separação favorece manutenção por contexto técnico e facilita evolução modular, o que é consistente com boas práticas de organização de código Terraform e com a separação entre fundação e workloads consumidores.[^2][^1]

## Estratégia de modularização

O repositório do servidor-base deve conter apenas aquilo que define a infraestrutura comum e estável. Projetos futuros de aplicações devem assumir essa fundação como pré-requisito e atuar em camada separada, usando outputs, convenções e diretórios padrão como contrato de integração entre os repositórios.[^4][^1]

Exemplos do que pertence ao projeto foundation:

- Rede base, instância, regras mínimas de segurança e bootstrap do host.[^1]
- Docker instalado e pronto para uso, sem serviços de negócio embarcados.[^1]
- Integração base com Cloudflare Tunnel e DNS.[^11][^10]
- Outputs úteis para projetos dependentes.[^1]

Exemplos do que deve ficar fora do projeto foundation:

- Bancos de dados, UIs administrativas, APIs, stacks web e observabilidade específica.[^4][^1]
- `docker compose` de aplicações, segredos de workloads e backups específicos de serviço.[^1]


## Arquivos de variáveis

### `terraform.tfvars` — sensível

Este arquivo deve armazenar dados sensíveis e permanecer fora do versionamento Git. Ele deve conter credenciais da OCI, token e dados da Cloudflare, credenciais AWS e quaisquer segredos operacionais necessários ao bootstrap seguro do servidor.[^1]

Exemplo:

```hcl
oci_tenancy_ocid       = "ocid1.tenancy..."
oci_user_ocid          = "ocid1.user..."
oci_fingerprint        = "12:34:56:..."
oci_private_key_path   = "~/.oci/oci_api_key.pem"
oci_compartment_ocid   = "ocid1.compartment..."
cloudflare_api_token   = "<secret>"
cloudflare_account_id  = "<secret>"
aws_access_key_id      = "<secret>"
aws_secret_access_key  = "<secret>"
```


### `terraform.auto.tfvars` — não sensível

Este arquivo deve armazenar parâmetros operacionais e declarativos do ambiente, incluindo região, availability domain, shape, recursos da instância, versão do Ubuntu, nomes de bucket, domínio e subdomínios padrão para o foundation.[^1][^3]

Exemplo:

```hcl
project_name             = "nettask-foundation"
environment              = "prod"
oci_region               = "sa-saopaulo-1"
availability_domain      = "AD-1"
instance_shape           = "VM.Standard.A1.Flex"
instance_ocpus           = 1
instance_memory_gb       = 6
storage_size_gb          = 50
ubuntu_image_version     = "ubuntu-24.04"
ssh_allowed_cidr_blocks  = ["0.0.0.0/0"]
cloudflare_zone_name     = "nettask.com.br"
foundation_subdomain     = "infra.nettask.com.br"
aws_region               = "us-east-1"
tfstate_bucket_name      = "<bucket-informado>"
```


## Convenção de nomenclatura

```
A convenção recomendada é `nettask-<environment>-<component>`, padronizando recursos em OCI, AWS e Cloudflare. Exemplos: `nettask-prod-foundation-vm`, `nettask-prod-foundation-vcn`, `nettask-prod-foundation-nsg`, `nettask-prod-foundation-tunnel`, `nettask-prod-foundation-tfstate`.[^1]
```

Tags recomendadas:

- `project = nettask-foundation`
- `environment = prod`
- `managed_by = terraform`
- `owner = nettask`
- `layer = foundation`


## Bootstrap do host

O `cloud-init` deve instalar pacotes base, atualizar o sistema, instalar Docker, habilitar os serviços necessários, preparar diretórios padrão para futuros projetos e instalar/configurar `cloudflared`. O bootstrap não deve baixar nem subir aplicações específicas; sua responsabilidade termina quando o host foundation estiver pronto para receber workloads externos.[^3][^1]

Diretórios base sugeridos:

- `/opt/foundation/bin`
- `/opt/foundation/apps`
- `/opt/foundation/shared`
- `/opt/foundation/logs`
- `/opt/foundation/compose`

Esses paths ajudam a criar um contrato operacional previsível para repositórios futuros de aplicações.[^1]

## Segurança

A segurança deve seguir uma abordagem mínima, porém consistente. A porta 22 pode permanecer aberta temporariamente para validação inicial, mas essa abertura é transitória e deve ser restringida depois da homologação. Serviços futuros não devem ser expostos diretamente por IP público sempre que houver possibilidade de publicação segura via Cloudflare Tunnel.[^9][^11][^3]

O uso de Cloudflare Access é recomendado para proteger hostnames publicados no túnel, permitindo aplicar regras por identidade, e-mail, domínio corporativo ou outro método compatível. Isso é diferente de apenas instalar o `cloudflared`; o agente cria o túnel, enquanto as políticas Access definem quem entra no recurso protegido.[^8][^9]

## Backend remoto do Terraform

O estado do Terraform deve ser mantido na AWS, região `us-east-1`, em bucket S3 já existente e informado nas variáveis do ambiente. O uso de tabela DynamoDB deixa de ser obrigatório neste projeto; o backend remoto deve se apoiar no bucket previamente criado e na disciplina operacional do processo para evitar concorrência de execução.[^3]

## Outputs esperados

O projeto foundation deve publicar outputs suficientes para consumo por projetos dependentes. Exemplos:

- IP público da instância.[^1]
- Hostname foundation associado ao servidor.[^1]
- Nome da instância e identificadores principais.[^1]
- Caminhos padrão sugeridos para deploys futuros.[^1]
- Nome do tunnel e hostnames provisionados.[^1]


## Critérios de aceitação

| ID | Critério |
| :-- | :-- |
| AC-01 | `terraform init`, `plan` e `apply` executam com backend remoto em S3 usando o bucket previamente criado.[^3] |
| AC-02 | A região OCI é definida por `terraform.auto.tfvars`.[^3] |
| AC-03 | O availability domain é parametrizado ou resolvido por data source conforme a implementação escolhida.[^13][^12] |
| AC-04 | A instância OCI com Ubuntu LTS é criada com sucesso.[^3] |
| AC-05 | O bootstrap instala Docker e `cloudflared`, sem aplicações de negócio por padrão.[^1][^3] |
| AC-06 | O projeto cria integração com Cloudflare para DNS e tunnel.[^10][^11] |
| AC-07 | O projeto permite aplicar políticas Access para proteger hostnames publicados.[^8][^9] |
| AC-08 | O arquivo `terraform.tfvars` concentra apenas segredos e fica fora do Git.[^1] |
| AC-09 | O arquivo `terraform.auto.tfvars` concentra apenas dados não sensíveis do ambiente.[^1] |
| AC-10 | O repositório entrega outputs e convenções suficientes para projetos futuros consumirem o servidor-base.[^1][^4] |

## Riscos e mitigação

| Risco | Impacto | Mitigação |
| :-- | :-- | :-- |
| Misturar foundation e aplicação no mesmo repositório | Acoplamento alto e manutenção difícil | Definir claramente escopo do foundation e contratos de integração.[^1][^4] |
| Exposição indevida de serviços futuros | Risco de segurança | Publicar via tunnel e proteger com Access sempre que possível.[^8][^9] |
| Drift por alterações manuais no servidor | Inconsistência operacional | Priorizar bootstrap declarativo e mudanças via código versionado.[^3] |
| Estado Terraform compartilhado com muitas responsabilidades | Complexidade e risco de apply | Manter o foundation em estado próprio e separar stacks dependentes.[^1][^6] |
| Repositórios consumidores sem contrato claro | Integração frágil | Padronizar outputs, paths, nomes e documentação operacional.[^1] |

## Entregáveis esperados

- Repositório Terraform dedicado ao servidor-base OCI + Cloudflare.[^1]
- Backend remoto de estado na AWS configurado em `us-east-1`, usando o bucket S3 previamente criado.[^3]
- Templates de bootstrap via `cloud-init`.[^3]
- Integração com Cloudflare Tunnel e DNS.[^10][^11]
- Documentação clara de inputs, outputs, convenções e pontos de extensão para projetos futuros.[^2][^1]


## Decisões intencionais

Este PRD adota intencionalmente uma abordagem sem aplicação embarcada. A decisão busca maximizar reuso, simplificar manutenção, preservar uma fundação estável e permitir que projetos futuros instalem seus próprios componentes sem reabrir decisões estruturais de infraestrutura a cada nova demanda.[^4][^2][^1]

<div align="center">⁂</div>

[^1]: https://support.hashicorp.com/hc/en-us/articles/45101629429523-Best-Practices-Organising-Terraform-and-Application-Code

[^2]: https://dev.to/patdevops/building-reusable-infrastructure-with-terraform-modules-625

[^3]: https://docs.cloud.google.com/docs/terraform/best-practices/operations

[^4]: https://uplatz.com/blog/gitops-for-infrastructure-a-declarative-operational-model-for-cloud-native-environments/

[^5]: https://www.harness.io/blog/gitops-repo-structure

[^6]: https://opsiocloud.com/blogs/terraform-best-practices-for-building-strong-infrastructure/

[^7]: https://dev.to/mary_mutua_9d55b3c269f343/building-reusable-infrastructure-with-terraform-modules-71d

[^8]: https://www.cloudflare.com/sase/products/access/

[^9]: https://developers.cloudflare.com/cloudflare-one/access-controls/policies/

[^10]: https://developers.cloudflare.com/api/node/resources/zero_trust/subresources/tunnels/

[^11]: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/private-net/cloudflared/connect-private-hostname/

[^12]: https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm

[^13]: https://docs.oracle.com/en/solutions/design-ha/plan-high-availability-compute-instances1.html

