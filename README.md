# OptScale AKS Deployment

This project deploys a complete OptScale environment on Azure Kubernetes Service (AKS) with a private API server and Azure AD RBAC.

## Prerequisites

- Azure CLI
- Terraform
- An Azure subscription
- An Azure AD group to administer AKS (you’ll need the group Object ID)

## Key Design Notes

- Private AKS cluster: API server is private; run Terraform from inside the VNet (e.g., Bastion VM).
- Azure AD + Azure RBAC: AKS is configured with managed AAD and Azure RBAC enabled.
- Kubernetes provider uses kubeconfig: Terraform authenticates to the cluster via the kubeconfig produced by `az aks get-credentials`.
- Secrets in Key Vault: The database password is stored in Azure Key Vault and the application receives the actual secret value via a Kubernetes Secret.

## Setup

1.  Clone the repository

    ```bash
    git clone <repository-url>
    cd optscale-aks-deployment
    # If submodules are needed
    git submodule update --init --recursive
    ```

2.  Log in to Azure

    ```bash
    az login
    ```

3.  Configure Terraform variables (use environment variables for sensitive data)

    Recommended environment variables:

    ```bash
    export TF_VAR_tenant_id="<your-tenant-id>"
    export TF_VAR_agent_object_id="<your-agent-object-id>"
    export TF_VAR_db_admin_password="<YourSecureDbPassword!123>"
    ```

    Notes:
    - The Bastion VM uses SSH public key auth (`bastion_admin_public_key`); no password variable is used.
    - In `terraform.tfvars`, set `admin_group_object_ids` to a list containing your AAD admin group Object ID. You can look it up via `az ad group show --group "<group-name>" --query id -o tsv`.

4.  Initialize Terraform

    ```bash
    terraform init
    ```

5.  Bootstrap apply, then configure kubeconfig, then finalize

    Because the AKS API is private and the Kubernetes provider reads `~/.kube/config`, use a two-phase apply from a host with VNet access (e.g., Bastion VM):

    a) Create AKS (and networking) first

    ```bash
    terraform apply -target=module.aks_networking -target=module.aks_cluster
    ```

    b) Get kubeconfig for the private cluster (run on the same host)

    ```bash
    az aks get-credentials \
      --resource-group <your-resource-group-name> \
      --name <your-aks-cluster-name> \
      --overwrite-existing
    ```

    c) Apply the rest (Key Vault, DB VM, cache, storage, and Kubernetes app)

    ```bash
    terraform apply
    ```

## Architecture

This project provisions the following resources:

- Azure Resource Group
- Azure Virtual Network with subnets for AKS, database, and Bastion
- Azure Kubernetes Service (private cluster, AAD + Azure RBAC)
- Azure Bastion Service and a Bastion Host VM (SSH key-based)
- PostgreSQL on a Linux VM (initialization via VM extension)
- Azure Cache for Redis
- Azure Storage Account
- Azure Key Vault for secrets

## Security

- Database password is stored in Azure Key Vault; the Kubernetes Secret uses the actual secret value (not just the secret name).
- AKS private endpoint limits exposure of the API server.
- Bastion Service provides secure access to private resources without public IPs on VMs.
- If you want the frontend to be internal-only, add the annotation `service.beta.kubernetes.io/azure-load-balancer-internal: "true"` to the Service.

## Running From the Bastion Host

Because the AKS API is private, perform Terraform operations from inside the VNet (e.g., via the Bastion Host).

1. Connect to the Bastion Host via Azure Bastion in the Azure Portal.
2. Ensure Terraform and Azure CLI are installed (e.g., `sudo apt-get install -y terraform azure-cli`).
3. Clone this repository on the Bastion Host and follow the Setup steps above.

## AAD RBAC Details

- `admin_group_object_ids` should include the AAD Group Object ID(s) that will have admin access to the AKS cluster.
- The Terraform Kubernetes provider reads `~/.kube/config`. The identity you used with `az login` must be a member of an admin group or granted the `Azure Kubernetes Service RBAC Cluster Admin` role on the AKS resource to create cluster resources.

## Notes on State Backend

- The repository includes a bootstrap to create a storage account and container for Terraform state, but the backend is not pre-configured. To use remote state, add a `terraform { backend "azurerm" { ... } }` block and run `terraform init -migrate-state`.

## Troubleshooting

### Error: `VaultAlreadyExists`

This error occurs when the Key Vault name specified in the Terraform configuration already exists in Azure. Since Key Vault names must be globally unique, this can happen if a Key Vault with the same name was recently deleted but not purged.

**Resolution:**

The `key_vault` module was modified to append a random string to the Key Vault name, ensuring that the name is unique on every deployment. The `key_vault_name` variable was also removed from the root `variables.tf` file to prevent it from being overridden.

### Error: `kubelogin failed`

This error occurs when `kubelogin` is unable to authenticate to the AKS cluster. In this case, it was because the bastion host was unable to resolve the private DNS name of the AKS private endpoint.

**Resolution:**

1.  **Linked the private DNS zone to the bastion's VNet:** The private DNS zone for the AKS cluster was linked to the virtual network of the bastion host. This allows the bastion host to resolve the private DNS name of the AKS cluster.
2.  **Refreshed Kubernetes credentials:** The `az aks get-credentials` command was run to refresh the Kubernetes credentials and update the `kubeconfig` file.