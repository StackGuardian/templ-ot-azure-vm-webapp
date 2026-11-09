# Azure Web App on VMs (Scale Set + App Gateway)

Runs a small nginx web app on a VM Scale Set behind an Azure Application Gateway. Each VM shows its own host name on the page, so with more than one instance, reloading the page shows the load balancing at work.

Use it to show a classic web tier on virtual machines in Azure.

## What gets created

- A resource group
- A virtual network with one subnet for the Application Gateway and one for the VMs, each with a network security group
- A NAT gateway, so the VMs can install packages
- An Application Gateway v2 with a public IP and a DNS name
- A Linux VM Scale Set (Ubuntu 24.04 LTS) running nginx
- A Log Analytics workspace with the gateway's access logs

## Before you start

- A workflow with an Azure cloud connector for the target subscription
- Permissions to create resource groups, networks, Application Gateways and VM Scale Sets
- An SSH key pair. You paste the public key into the form. No SSH port is opened, the key is only required by Azure
- Optional: the EncryptionAtHost feature registered in the subscription, if you want encryption at host

## Form fields

| Field | What it does | Default |
|---|---|---|
| SSH public key | **Required.** Your public SSH key, for example `ssh-ed25519 AAAA...` | none |
| Name prefix | Prefix for all resource names. 2 to 16 lowercase letters, digits or hyphens, starting with a letter | `demo` |
| Location | Azure region | Germany West Central |
| VM size | Size of each VM. All listed sizes support Trusted Launch | B2s v2 (2 vCPU, 8 GiB) |

**Advanced Settings** (tick "Show advanced settings" to change them):

| Field | What it does | Default |
|---|---|---|
| VNet cidr | IP range of the new network | `10.0.0.0/16` |
| Admin username | Name of the admin user on the VMs | `azureuser` |
| Instance count | Number of VMs, 1 to 5 | `1` |
| Encryption at host enabled | Also encrypts temp disk and caches on the host. Needs the subscription feature | off |
| Allowed CIDR | IP ranges that may reach the web app. Public by default | `0.0.0.0/0` |
| Log retention days | How long access logs are kept | `90` |
| Tags | Extra tags added to all resources | none |

To show load balancing, set Instance count to 2 or more.

## After the run

The workflow outputs show:

- `url`: open it in a browser. The first response can take a few minutes while nginx is installed
- `public_ip`, `scale_set_name`, `application_gateway_name` and `resource_group_name`

Creating the Application Gateway takes about 5 to 10 minutes.

## Security defaults

- VMs have no public IPs and no SSH or RDP access from the internet
- VMs accept HTTP only from the Application Gateway
- Trusted Launch: Secure Boot and vTPM on. VM extensions disabled. Disks encrypted at rest
- Gateway access logs go to Log Analytics

## Cost and cleanup

The Application Gateway, the NAT gateway and the VMs are billed per hour, also when idle. Destroy the resources from the workflow when the demo is over.

## Limits

- HTTP only. HTTPS needs a certificate in Key Vault and is not part of this template
- No shell access from the internet. Add Azure Bastion if you need it
