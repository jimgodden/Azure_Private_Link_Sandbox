@description('Name of the Source Virtual Network')
param originVNET_Name string

@description('Name of the Destination Virtual Network')
param dstVNET_Name string

resource originVNET 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: originVNET_Name
}

resource dstVNET 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: dstVNET_Name
}

resource vnet_peering_origin_to_dst 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  parent: originVNET
  name: '${originVNET_Name}to${dstVNET_Name}'
  properties: {
    remoteVirtualNetwork: {
      id: dstVNET.id
    }
  }
}
