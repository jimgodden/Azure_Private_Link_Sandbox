@description('Azure Datacenter location that the main resouces will be deployed to.')
param location string

@description('Name of the Azure Firewall within the vHub A')
param AzFW_Name string

@description('Sku name of the Azure Firewall.  Allowed values are Basic, Standard, and Premium')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param AzFW_SKU string

@description('Name of the Azure Firewall Policy')
param AzFWPolicy_Name string

@description('Resource ID of the Azure Firewall Subnet.  Note: The subnet name must be "AzureFirewallSubnet')
param azfwSubnetID string

@description('Resource ID of the Azure Firewall Management Subnet.  Note: The subnet name must be "AzureFirewallManagementSubnet')
param azfwManagementSubnetID string

resource AzFW_PIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: '${AzFW_Name}_PIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource AzFW_Management_PIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: '${AzFW_Name}_Management_PIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource AzFW_Policy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: AzFWPolicy_Name
  location: location
  properties: {
    sku: {
      tier: AzFW_SKU
    }
  }
}

resource AzFW 'Microsoft.Network/azureFirewalls@2022-11-01' = {
  name: AzFW_Name
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: AzFW_SKU
    }
    additionalProperties: {}
    managementIpConfiguration: {
      name: 'managementipconfig'
      properties: {
        publicIPAddress: {
          id: AzFW_Management_PIP.id
        }
        subnet: {
          id: azfwManagementSubnetID
        }
      }
     }
    ipConfigurations: [
       {
         name: 'ipconfiguration'
         properties: {
          publicIPAddress: {
            id: AzFW_PIP.id
          }
           subnet: {
            id: azfwSubnetID
           }
         }
       }
    ]
    firewallPolicy: {
      id: AzFW_Policy.id
    }
  }
}
