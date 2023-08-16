@description('Azure Datacenter that the resource is deployed to')
param location string

param privateEndpointVnetName string

param privateDNSZoneLinkedVnetNamesList array

param privateDNSZoneLinkedVnetIDList array

param subnetID string

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
param storageAccount_Name string

param usingBlobPrivateEndpoints bool = true
param usingFilePrivateEndpoints bool = true


// @description('''
// Group ID of the resource the Private Endpoint connects to.
//  - Example: Blob Storage for storage account would be 'blob'
// ''')
// param groupID string = 'blob'

param privateEndpoints_Blob_Name string



// Grabs the FQDN of the Blob but removes the extra that we don't need
// Original value https://{storageAccount_Name}.blob.core.windows.net/
// Output {storageAccount_Name}.blob.core.windows.net
var blobEndpoint = storageAccount.properties.primaryEndpoints.blob
var blobEndpointNoHTTPS = substring(blobEndpoint, 7, 8)
var blobFQDN = take(blobEndpointNoHTTPS, length(blobEndpointNoHTTPS) - 1)


var privateDNSZone_Blob_Name = 'privatelink.blob.core.windows.net'
var privateDNSZone_File_Name = 'privatelink.file.core.windows.net'



resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccount_Name
  location: location
  sku: {
    name: 'Standard_LRS'
    // tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageAccount_Blob 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}

resource privateEndpoints_Blob 'Microsoft.Network/privateEndpoints@2023-04-01' = if (usingBlobPrivateEndpoints) {
  name: privateEndpoints_Blob_Name
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpoints_Blob_Name}_in_${privateEndpointVnetName}_to_${storageAccount_Name}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnetID
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        fqdn: blobFQDN //'biceptestsajames.blob.core.windows.net'
        // ipAddresses: [
        //   '10.0.0.4'
        // ]
      }
    ]
  }
}

resource privateDNSZone_StorageAccount_Blob 'Microsoft.Network/privateDnsZones@2018-09-01' = if (usingBlobPrivateEndpoints) {
  name: privateDNSZone_Blob_Name
  location: 'global'
}

resource privateDNSZone_StorageAccount_Blob_Group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  parent: privateEndpoints_Blob
  name: 'blobZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
           privateDnsZoneId: privateDNSZone_StorageAccount_Blob.id
        }
      }
    ]
  }
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [ for i in range(0, length(privateDNSZoneLinkedVnetIDList) - 1): if (usingBlobPrivateEndpoints) {
  parent: privateDNSZone_StorageAccount_Blob
  name: '${privateDNSZone_Blob_Name}_to_${privateDNSZoneLinkedVnetNamesList[i]}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: privateDNSZoneLinkedVnetIDList[i]
    }
  }
}]

// resource privateDNSZoneRecord_StorageAccount_Blob 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
//   parent: privateDNSZone_StorageAccount_Blob
//   name: 'biceptestsajames'
//   properties: {
//     ttl: 3600
//     aRecords: [
//       {
//         ipv4Address: '10.0.0.4'
//       }
//     ]
//   }
// }

// resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_blob_core_windows_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
//   parent: privateDNSZone_StorageAccount_Blob
//   name: '@'
//   properties: {
//     ttl: 3600
//     soaRecord: {
//       email: 'azureprivatedns-host.microsoft.com'
//       expireTime: 2419200
//       host: 'azureprivatedns.net'
//       minimumTtl: 10
//       refreshTime: 3600
//       retryTime: 300
//       serialNumber: 1
//     }
//   }
// }

// resource Microsoft_Storage_storageAccounts_fileServices_storageAccount_Name_default 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
//   parent: storageAccount
//   name: 'default'
//   properties: {
//     protocolSettings: {
//       smb: {}
//     }
//     cors: {
//       corsRules: []
//     }
//     shareDeleteRetentionPolicy: {
//       enabled: true
//       days: 7
//     }
//   }
// }

// resource Microsoft_Storage_storageAccounts_queueServices_storageAccount_Name_default 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
//   parent: storageAccount
//   name: 'default'
//   properties: {
//     cors: {
//       corsRules: []
//     }
//   }
// }

// resource Microsoft_Storage_storageAccounts_tableServices_storageAccount_Name_default 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
//   parent: storageAccount
//   name: 'default'
//   properties: {
//     cors: {
//       corsRules: []
//     }
//   }
// }
