@description('Azure Datacenter location that the main resouces will be deployed to.')
param location string

@description('Name of the Azure Bastion')
param bastion_name string = 'bastion'

@description('Name of the Public IP Address attached to the Azure Bastion')
param bastion_vip_name string = 'bastion_vip'

@description('Resource ID of the subnet the Azure Bastion will be placed in.  The name of the subnet must be "AzureBastionSubnet"')
param bastionSubnetID string

@description('SKU of the Azure Bastion')
@allowed([
  'Basic'
  'Standard'
])
param bastionSKU string = 'Basic'

resource bastion 'Microsoft.Network/bastionHosts@2022-09-01' = {
  name: bastion_name
  location: location
  sku: {
    name: bastionSKU
  }
  properties: {
    scaleUnits: 2
    enableTunneling: false
    enableIpConnect: false
    disableCopyPaste: false
    enableShareableLink: false
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastion_vip.id
          }
          subnet: {
            id: bastionSubnetID
          }
        }
      }
    ]
  }
}

resource bastion_vip 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: bastion_vip_name
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
