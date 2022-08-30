# Environments

*last update: 30/08/2022*

> For a detailed description of the current configuration, please see the [mod-dev README.md](mod-dev/README.md) file.

The current directory used to hold the configurations that were meant for Production and Development environments, called **legacy-prod** and **legacy-env**, respectively.

While legacy-* modules are currently discontinued, **dev-mod** is the environment working best and currently deployed to the `ornate-reef-342810` GCP project.

The table below reflects the state of the current codebase:

| Traits | *dev-mod* | legacy-dev | legacy-prod |
| :--- | :---: | :---: | :---: | 
| Fully Working        | :white_check_mark: |:x: |:x: |
| Shared Files         | | :white_check_mark: | :white_check_mark: |
| Meant for deployment | :arrow_right: | :wheelchair: | :wheelchair: |
| VM configuration     | :white_check_mark: | :white_check_mark: | :white_check_mark: |

## Explanation

**Fully working**: Tested and applied with terraform to the `ornate-reef-342810` GCP project. 

**Shared Files**: these reflect the presence of symlinks (or [symbolic links](https://en.wikipedia.org/wiki/Symbolic_link)) targeting a shared directory). These terraform files specify resources to be deployed onto dev and prod alike. These are:
  
- main.tf 
- outputs.tf
- providers.tf
- variables.tf

Each environment directory also contains files called `terraform.tfvars` overriding the default values specified in `varibales.tf`, wherever it is necessary. 

The only **VM configuration** working is on *minimal-prod-env*, which should become the new dev.

The fields **meant for deployment** are legacy terms associated with the legacy setups, which raised problems in deployment.
The future developer/mantainer of this repo should consider using **dev-mod** as starting point for future configurations.
make 
Note that, when one configuration is worked on, no other configurations should be touched. This is because the state-tflock file is synced with the GCP storage bucket in the GCP Project.
