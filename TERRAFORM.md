# About Terraform

## Overview
This project contains Terraform scripts for creating [DNAstack Workbench](https://workbench.dnastack.com) engine
deployments in cloud environments.

This document contains an introduction to [Terraform](https://www.terraform.io/) and a general overview. For instructions installing on
one of the supported cloud environments, follow the linked instructions:
* [Cromwell on Google Cloud Platform (GCP)](gcp/README.md)

## About Terraform
Terraform is an infrastructure-as-code tool for defining cloud and on-prem resources in configuration files
that can be used to create new infrastructure and manage changes over time. To learn more, check out the
[Hashicorp documentation](https://developer.hashicorp.com/terraform/intro).

### Terraform Basics

#### Modules
Terraform configuration is organized into modules. A module is a directory that typically has these files:
* main.tf (required)
* variables.tf (optional)
* outputs.tf (optional)

Modules can be local (with source specified as a relative path) or remote (pulled from a registry). This repository
is organized into root modules for each supported cloud, each with their own submodules.

#### Installing Dependencies
Before you can run a Terraform module, you need to install its dependencies. Run this command from the module directory:
```bash
terraform init
```

Running this from a root module will also initialize any local module dependencies.

When you update dependencies, you may also need to use `terraform get`.

Initializing a module creates a `.terraform` directory in that module. You should _not_ check-in `.terraform`
directories in your source control system.

#### Applying a Configuration
From the root of a module, you can apply a configuration (to create/update resources described in that module) with:
```bash
terraform apply
```

This will prompt you to type in any required input variables. To supply those variables from a file, use:
```bash
terraform apply -var-file=my-vars.tfvars
```

#### Terraform State
Terraform stores the state of the operations it has run. It is important to use this state whenever you are updating
resources you previously created with Terraform.

By default, Terraform uses a local backend to store state in a file called `terraform.tfstate` in whatever directory
it was called. This is fine for quick tests, but any infrastructure managed by a team should use
[remote state](https://developer.hashicorp.com/terraform/language/state/remote).

#### Terraform Destroy
You can delete resources created by Terraform by running:
```bash
terraform destroy
```

You may also wish to use `-var-file` to pass in previously used variables.

Some resources (particularly stateful resources like databases and cloud buckets) have deletion protection mechanisms.
You may need to update these resources with flags allowing their removal before attempting to delete them.