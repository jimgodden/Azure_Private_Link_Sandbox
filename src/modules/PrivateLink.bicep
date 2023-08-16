@description('Azure Datacenter that the resource is deployed to')
param location string


param slb_Name string = 'slb'


param slb_SubnetID string


param privateEndpoint_name string = 'pe_to_pl'


param privateEndpoint_SubnetID string


param privateLink_Name string = 'pl'


param privateLink_SubnetID string

param virtualMachineNIC_Name string



param virtualMachineNIC_IPConfig_Name string



param tcpPort int = 443

// Modifies the existing Virtual Machine NIC to add it to the backend pool of the Load Balancer behind the Private Link Service
resource virtualMachineNIC 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: virtualMachineNIC_Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: virtualMachineNIC_IPConfig_Name
        properties: {
          loadBalancerBackendAddressPools: [
            {
              id: slb.properties.backendAddressPools[0].id
            }
          ]
        }
      }
    ]
  }
}

resource slb 'Microsoft.Network/loadBalancers@2022-09-01' = {
  name: slb_Name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fip'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: slb_SubnetID
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'bep'
      }
    ]
    loadBalancingRules: [
      {
        name: 'forwardAll'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', slb_Name, 'fip')
          }
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'All'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', slb_Name, 'bep')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', slb_Name, 'probe${tcpPort}')
          }
        }
      }
    ]
    probes: [
      {
        name: 'probe${tcpPort}'
        properties: {
          protocol: 'Tcp'
          port: tcpPort
          intervalInSeconds: 5
          numberOfProbes: 1
          probeThreshold: 1
        }
      }
    ]
    inboundNatRules: []
    outboundRules: []
    inboundNatPools: []
  }
}

resource privateendpoint 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpoint_name
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpoint_name
        properties: {
          privateLinkServiceId: privateLink.id
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpoint_name}-nic'
    subnet: {
      id: privateEndpoint_SubnetID

    }
  }
}

resource privateLink 'Microsoft.Network/privateLinkServices@2022-09-01' = {
  name: privateLink_Name
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: '${slb.id}/frontendIPConfigurations/fip'
      }
    ]
    ipConfigurations: [
      {
        name: 'default-1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: privateLink_SubnetID
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}
