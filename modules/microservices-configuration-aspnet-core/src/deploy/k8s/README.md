# README

For the quickstart process, see the [environment-setup documentation](../../doc/environment-setup.md).

> **CONTENT**

- [Typical workflows](#typical-workflows)
  - [Azure Cloud Shell / WSL](#azure-cloud-shell--wsl)
  - [Powershell](#powershell)
    - [Update the base images in the public registry](#update-the-base-images-in-the-public-registry)
- [Bash scripts](#bash-scripts)
  - [create-aks.sh](#create-akssh)
  - [deploy-application.sh](#deploy-applicationsh)
  - [create-acr.sh](#create-acrsh)
  - [build-to-acr.sh](#build-to-acrsh)
- [PowerShell scripts](#powershell-scripts)
  - [deploy-application.ps1](#deploy-applicationps1)

## Typical workflows

### Azure Cloud Shell / WSL

- Create AKS cluster (**create-aks.sh**, run the displayed command to update the environment)
- Deploy application (**deploy-application.sh**, run the displayed command to update the environment)
- **Optional**, when updating services:
  - Create ACR (**create-acr.sh**)
  - Build to ACR - updated services only (**build-to-acr --services**)
  - Deploy application - updated services only (**deploy-application.sh --charts**)

### Powershell

- Local Kubernetes cluster created with Docker Desktop
- Deploy NGINX ingress controller (**deploy-ingress.ps1**)
- Deploy application (**deploy-application.ps1**)

#### Update the base images in the public registry

The base images for the second batch of modules (#02-07) are built from project **`module-01-final-eshopdev`**.

1. Set the environment variable REGISTRY to `eshopdev`, `eshoplearn`, or whichever you're using the following command (for `eshopdev`).

   ```powershell
   $env:REGISTRY="eshopdev"
   ```

2. Build the required services with docker-compose:

   ```powershell
   docker-compose build service1 service2 ...
   ```

3. Login to the registry (DockerHub)

   ```powershell
   docker login -u <user-name> --password-stdin
   ```

4. Push the required services with docker-compose:

   ```powershell
   docker-compose push service1 service2 ...
   ```

## Bash scripts

- The shell scripts are meant to be run from the Azure Cloud Shell.
- Have been tested locally from Windows Terminal with WSL, but you have to:
  - Create the folders `~/clouddrive/source`
  - [Install kubectl on WSL](https://devkimchi.com/2018/06/05/running-kubernetes-on-wsl/)
  - [Install az cli on WSL](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest)
- Most scripts create output environment variables
  - Saved in `~/clouddrive/source/{script-name}-exports.txt`

### create-aks.sh

Creates an AKS instance. Deploys the NGINX ingress controller.

Input environment variables:

- **ESHOP_RG**: Default resource group, can be overridden by **--resource-group**
- **ESHOP_LOCATION**: Default location, can be overridden by **--location**
- **ESHOP_NODECOUNT**: Node count, defaults to 1
- **ESHOP_AKSNAME**: AKS cluster name, defaults to "eshop-learn-aks"

Parameters:

- **--resource-group**: **[mandatory]** Name of the resource group to use or create.
- **--location**: Location, mandatory if resource-group doesn't exist.

Output environment variables (`~/clouddrive/source/create-aks-exports.txt`):

- **ESHOP_RG**: Resource group
- **ESHOP_LOCATION**: Location
- **ESHOP_AKSNAME**: AKS name
- **ESHOP_AKSNODERG**: AKS cluster resource group
- **ESHOP_LBIP**: Public IP for load balancer

### deploy-application.sh

Deploys the application to the current Kubernetes context. Optionally creates self-signed certificate.

Input environment variables:

- **REGISTRY**: Default registry, can be overridden by **$ESHOP_REGISTRY and  --registry**
- **ESHOP_REGISTRY**: Default ACR registry, can be overridden by **--registry**
- **ESHOP_LBIP**: Public IP for load balancer

Parameters:

- **--registry**: Registry to pull images from, defaults to **eshopdev**
- **--hostname**: Name of the host to access the deployed application.
- **--hostip**: IP address to access the deployed application.
- **--protocol**: http/https, defaults to **http**
- **--certificate**: none/self-signed, creates and installs self-signed certificate
- **--charts**: Comma separated list of charts to deploy

Output environment variables (`~/clouddrive/source/deploy-application-exports.txt`):

- **ESHOP_LBIP**: Public IP for load balancer
- **ESHOP_HOST**: Hostname for load balancer (or IP address if none)
- **ESHOP_REGISTRY**: ACR login server ($ESHOP_ACRNAME.azurecr.io)

### create-acr.sh

Creates an ACR instance. Grants AcrPull role to $ESHOP_AKSNAME

Input environment variables:

- **ESHOP_RG**: Default resource group, can be overridden by **--resource-group**
- **ESHOP_LOCATION**: Default location, can be overridden by **--location**
- **ESHOP_IDTAG**: ID tag used to create resources with public name (YYYYMMDDHHMMSSRRR) RRR=Random number
- **ESHOP_AKSNAME**: AKS name

Parameters:

- **--resource-group**: **[mandatory]** Name of the resource group to use or create.
- **--location**: Location, mandatory if resource-group doesn't exist.

Output environment variables (`~/clouddrive/source/create-acr-exports.txt`):

- **ESHOP_RG**: Resource group
- **ESHOP_LOCATION**: Location
- **ESHOP_AKSNAME**: AKS name
- **ESHOP_LBIP**: Public IP for load balancer
- **ESHOP_ACRNAME**: ACR name
- **ESHOP_REGISTRY**: ACR login server ($ESHOP_ACRNAME.azurecr.io)
- **ESHOP_ACRUSER**: ACR login user
- **ESHOP_ACRPASSWORD**: ACR login password
- **ESHOP_IDTAG**: ID tag used to create resources with public name (YYYYMMDDHHMMSSRRR) RRR=Random number

### build-to-acr.sh

Build and publish images using ACR tasks.

Input files:

- **build-to-acr.services**: Table of application services.
  - formatted like `{service-name}:{image-name}>{dockerfile-path}`

Input environment variables:

- **ESHOP_ACRNAME**: **[mandatory]** ACR name
- **ESHOP_REGISTRY**: **[mandatory]** ACR login server ($ESHOP_ACRNAME.azurecr.io)

Parameters:

- **--services**: Comma separated list of services to build and publish.

## PowerShell scripts

### deploy-application.ps1

Deploys the application to the current Kubernetes context.

If self-signed certificate is needed it has to be manually created in WSL with `certificates/create-self-signed-certificate.sh`

Input environment variables:

- **REGISTRY**: Default registry, can be overridden by **$ESHOP_REGISTRY and  --registry**
- **ESHOP_REGISTRY**: Default ACR registry, can be overridden by **--registry**
- **ESHOP_LBIP**: Public IP for load balancer

Parameters:

- **-deploymentType**: **[Mandatory, positional]** Deployment type (**local/aks**)
- **-protocol**: **[Mandatory, positional]** (**http/https**)
- **-hostName**: Name of the host to access the deployed application.
- **-registry**: Registry to pull images from, defaults to **eshopdev**
- **-charts**: Comma separated list of charts to deploy
