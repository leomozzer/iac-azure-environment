# Network Address Plan

Hub-and-spoke architecture spanning multiple Azure regions with centralized DNS, flow logs, and conditional firewall deployment.

## East US (eastus)

Overall VNet space: **10.10.0.0/16**

| Resource | Terraform Name | CIDR | Type |
|---|---|---|---|
| Hub VNet | vnet-hub-eus-001 | 10.10.0.0/23 | Virtual Network |
| Hub workload subnet | snet-hub-eus-001 | 10.10.0.0/24 | Subnet |
| Hub firewall subnet | AzureFirewallSubnet | 10.10.1.0/26 | Subnet |
| Hub bastion subnet | AzureBastionSubnet | 10.10.1.64/26 | Subnet |
| Application Spoke VNet | vnet-application-spoke-eus-001 | 10.10.2.0/24 | Virtual Network |
| Application workload subnet | snet-application-spoke-eus-001 | 10.10.2.0/24 | Subnet |
| AVD Spoke VNet | vnet-avd-spoke-eus-001 | 10.10.5.0/25 | Virtual Network |
| AVD workload subnet | snet-avd-spoke-eus-001 | 10.10.5.0/25 | Subnet |

### Available ranges within 10.10.0.0/16

| CIDR | Usable Range | Notes |
|---|---|---|
| 10.10.3.0/24 | 10.10.3.0 – 10.10.3.255 | Available |
| 10.10.4.0/24 | 10.10.4.0 – 10.10.4.255 | Available |
| 10.10.6.0/23 | 10.10.6.0 – 10.10.7.255 | Available |
| 10.10.8.0/21 | 10.10.8.0 – 10.10.15.255 | Available |
| 10.10.16.0/20 | 10.10.16.0 – 10.10.31.255 | Available |
| 10.10.32.0/19 | 10.10.32.0 – 10.10.63.255 | Available |
| 10.10.64.0/18 | 10.10.64.0 – 10.10.127.255 | Available |
| 10.10.128.0/17 | 10.10.128.0 – 10.10.255.255 | Available |

## West Europe (westeurope)

Overall VNet space: **136.0.0.0/16**

| Resource | Terraform Name | CIDR | Type |
|---|---|---|---|
| Hub VNet | vnet-hub-weu-001 | 136.0.0.0/16 | Virtual Network |
| Hub workload subnet | snet-hub-weu-001 | 136.0.0.0/23 | Subnet |
| Hub firewall subnet | AzureFirewallSubnet | 136.0.2.0/26 | Subnet |

### Available ranges within 136.0.0.0/16

| CIDR | Usable Range | Notes |
|---|---|---|
| 136.0.2.64/26 | 136.0.2.64 – 136.0.2.127 | Available (after firewall /26) |
| 136.0.2.128/25 | 136.0.2.128 – 136.0.2.255 | Available |
| 136.0.3.0/24 | 136.0.3.0 – 136.0.3.255 | Available |
| 136.0.4.0/22 | 136.0.4.0 – 136.0.7.255 | Available |
| 136.0.8.0/21 | 136.0.8.0 – 136.0.15.255 | Available |
| 136.0.16.0/20 | 136.0.16.0 – 136.0.31.255 | Available |
| 136.0.32.0/19 | 136.0.32.0 – 136.0.63.255 | Available |
| 136.0.64.0/18 | 136.0.64.0 – 136.0.127.255 | Available |
| 136.0.128.0/17 | 136.0.128.0 – 136.0.255.255 | Available |
