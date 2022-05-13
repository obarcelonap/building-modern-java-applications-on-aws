# building-modern-java-applications-on-aws
Contains exercises from [Building Modern Java Applications on AWS in Coursera](https://www.coursera.org/learn/building-modern-java-applications-on-aws)

## Infra
Infrastructure is managed using [Terraform's AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs),
all the related code is under `infra` root folder.

The first time terraform has to be initialized using the following command
```shell
building-modern-java-applications-on-aws/infra/env
$ terraform init
```
On every infrastructure modification changes can be applied with the following command
```shell
building-modern-java-applications-on-aws/infra/env
$ terraform apply
```
