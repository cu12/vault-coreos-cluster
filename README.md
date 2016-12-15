# Vault CoreOS cluster

A Vault cluster using Consul backend, provisioned with Terraform.

## Requirements

    $ brew install terraform consul-backinator cmake
    $ cp terraform.tfvars.example terraform.tfvars

## Getting started

To provision you need to fill in the details in `terraform.tfvars`

* `aws_access_key` It must belong to a user with administrator privileges under your AWS account
* `aws_secret_key` The secret key for the above user
* `aws_account` A string that helps you to identify the provisioned resources. We use AWS account name
* `prefix` We use `prod` in production, etc. You can test your provisioning process by changing this
* `domain` The internal domain name for the instances
* `vault_address` FQDN where your Vault service will be reachable from the internet
* `ssh_public_key` The public key that will be used to access the instances

## Installing

    $ terraform plan \
      -out terraform.tfplan
    $ terraform apply \
      terraform.tfplan
    $ make init
    $ make unseal # three times by default

## Infrastructure Diagram

View the [infrastructure diagram](https://raw.githubusercontent.com/cu12/vault-coreos-cluster/master/infrastructure.ascii).

## Upgrading

Upgrading Consul or Vault is simple. Just change the version in `variables.tf`, then upgrade instances one-by-one.

    $ make backup # To backup Consul
    $ terraform plan \
        -target "aws_instance.vault[0]" \
        -target "aws_route53_record.vault[0]" \
        -target "aws_elb.vault" \
        -out terraform.tfplan
    $ terraform apply \
        -target "aws_instance.vault[0]" \
        -target "aws_route53_record.vault[0]" \
        -target "aws_elb.vault" \
        terraform.tfplan
    $ make cleanup # Cleanup failed Consul peers
    $ make unseal # three times by default
    $ make healtcheck

As an additional step - when you are about to upgrade the `active` Vault node - you could make it giving up its leader position before recreating the instance. It'll take ~10 seconds on the ELB for the new `active` node to appear. Skipping this step would make the new leader appear in ~60 seconds.

    $ make bastion
    $ ssh <leader>
    $ vault auth -address=http://127.0.0.1:8200
    $ vault step-down -address=http://127.0.0.1:8200

## Maintenance

Issue `make` to see.

## Technical notes

- Using official [Consul](https://hub.docker.com/_/consul/) docker image.
- Using official [Vault](https://hub.docker.com/_/vault/) docker image.
- Uses a self-signed certificate by default for HTTPS access through loadbalancer. This is not secure. Do not store sensitive data in your repository.
- CoreOS version is hardcoded and update strategy is set to `off`. Upgrade manually.

## Todo

- Tests

## License

[MIT License](https://github.com/cu12/vault-coreos-cluster/blob/master/LICENSE) © Domonkos Cinke
