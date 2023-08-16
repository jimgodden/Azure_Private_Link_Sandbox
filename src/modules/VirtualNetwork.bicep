@description('Azure Datacenter that the resource is deployed to')
param location string

@description('Name of the Virtual Network')
param vnet_Name string

@description('Address Prefix of the Virtual Network')
param vnet_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.0.0/16'

@description('Name of the Network Security Group')
param defaultNSG_Name string

@description('Name of the Route Table')
param routeTable_Name string

@description('First two octects of the vnet prefix')
param firstTwoOctetsOfVNETPrefix string

@description('Name of the Azure Virtual Network Gateway Subnet')
param subnet_Gateway_Name string = 'GatewaySubnet'

@description('Address Prefix of the Azure Virtual Network Gateway Subnet')
param subnet_Gateway_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.0.0/24'

@description('Name of the Azure Firewall Subnet')
param subnet_AzFW_Name string = 'AzureFirewallSubnet'

@description('Address Prefix of the Azure Firewall Subnet')
param subnet_AzFW_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.1.0/24'

@description('Name of the Azure Firewall Management Subnet')
param subnet_AzFW_Management_Name string = 'AzureFirewallManagementSubnet'

@description('Address Prefix of the Azure Firewall Management Subnet')
param subnet_AzFW_Management_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.2.0/24'

@description('Name of the Azure Bastion Subnet')
param subnet_Bastion_Name string = 'AzureBastionSubnet'

@description('Address Prefix of the Azure Bastion Subnet')
param subnet_Bastion_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.3.0/24'

@description('Name of the General Subnet for any other resources')
param subnet_General_Name string = 'General'

@description('Address Prefix of the General Subnet')
param subnet_General_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.4.0/24'

@description('Name of the PrivateEndpoint Subnet')
param subnet_PrivateEndpoints_Name string = 'PrivateEndpoints'

@description('Address Prefix of the PrivateEndpoint Subnet')
param subnet_PrivateEndpoints_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.5.0/24'

@description('Name of the PrivateEndpoint Subnet')
param subnet_PrivateLinkService_Name string = 'PrivateLinkService'

@description('Address Prefix of the PrivateEndpoint Subnet')
param subnet_PrivateLinkService_AddressPrefix string = '${firstTwoOctetsOfVNETPrefix}.6.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnet_Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_AddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet_Gateway_Name
        properties: {
          addressPrefix: subnet_Gateway_AddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_AzFW_Name
        properties: {
          addressPrefix: subnet_AzFW_AddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_AzFW_Management_Name
        properties: {
          addressPrefix: subnet_AzFW_Management_AddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_Bastion_Name
        properties: {
          addressPrefix: subnet_Bastion_AddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_General_Name
        properties: {
          addressPrefix: subnet_General_AddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_PrivateEndpoints_Name
        properties: {
          addressPrefix: subnet_PrivateEndpoints_AddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_PrivateLinkService_Name
        properties: {
          addressPrefix: subnet_PrivateLinkService_AddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled' // This has to be disabled for Private Link Service to be used in the subnet
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource routeTable 'Microsoft.Network/routeTables@2023-02-01' = {
  name: routeTable_Name
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: defaultNSG_Name
  location: location
  properties: {
  }
}

// resource nsgRule 'Microsoft.Network/networkSecurityGroups/securityRules@2022-09-01' = {
//   parent: nsg
//   name: defaultNSG_RuleName
//   properties: {
//     description: 'test'
//     protocol: '*'
//     sourcePortRange: '*'
//     destinationPortRange: '8080'
//     sourceAddressPrefix: '10.0.0.1/32'
//     destinationAddressPrefix: '*'
//     access: 'Allow'
//     priority: int(defaultNSG_RulePriority)
//     direction: 'Inbound'
//     sourcePortRanges: []
//     destinationPortRanges: []
//     sourceAddressPrefixes: []
//     destinationAddressPrefixes: []
//   }
// }

output gatewaySubnetID string = vnet.properties.subnets[0].id
output azfwSubnetID string = vnet.properties.subnets[1].id
output azfwManagementSubnetID string = vnet.properties.subnets[2].id
output bastionSubnetID string = vnet.properties.subnets[3].id
output generalSubnetID string = vnet.properties.subnets[4].id
output privateEndpointSubnetID string = vnet.properties.subnets[5].id
output privateLinkServiceSubnetID string = vnet.properties.subnets[6].id


output vnetName string = vnet.name
output vnetID string = vnet.id
