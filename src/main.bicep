@description('Azure Datacenter location for the Hub and Spoke A resources')
param locationA string = resourceGroup().location

// @description('''
// Azure Datacenter location for the Spoke B resources.  
// Use the same region as locationA if you do not want to test multi-region
// ''')
// param locationB string

@description('Username for the admin account of the Virtual Machines')
param vm_adminUsername string

@description('Password for the admin account of the Virtual Machines')
@secure()
param vm_adminPassword string

@description('Password for the Virtual Machine Admin User')
param vmSize string = 'Standard_D2s_v3' // 'Standard_D16lds_v5'

@description('True enables Accelerated Networking and False disabled it.  Not all VM sizes support Accel Net')
param accelNet bool = true

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
param storageAccount_Name string



module hubVNET './Modules/VirtualNetwork.bicep' = {
  name: 'hubVNET'
  params: {
    defaultNSG_Name: 'hubNSG'
    firstTwoOctetsOfVNETPrefix: '10.0'
    location: locationA
    routeTable_Name: 'hubRT'
    vnet_Name: 'hubVNET'
  }
}

module spokeAVNET './Modules/VirtualNetwork.bicep' = {
  name: 'spokeAVNET'
  params: {
    defaultNSG_Name: 'dstNSG'
    firstTwoOctetsOfVNETPrefix: '10.1'
    location: locationA
    routeTable_Name: 'dstRT'
    vnet_Name: 'spokeAVNET'
  }
}

module hubToSpokeAPeering 'modules/VirtualNetworkPeering.bicep' = {
  name: 'hubToSpokeAPeering'
  params: {
    dstVNET_Name: spokeAVNET.outputs.vnetName
    originVNET_Name: hubVNET.outputs.vnetName
  }
}

module spokeBVNET './Modules/VirtualNetwork.bicep' = {
  name: 'spokeBVNET'
  params: {
    defaultNSG_Name: 'spokeBNSG'
    firstTwoOctetsOfVNETPrefix: '10.2'
    location: locationA
    routeTable_Name: 'spokeBRT'
    vnet_Name: 'spokeBVNET'
  }
}

module hubToSpokeBPeering 'modules/VirtualNetworkPeering.bicep' = {
  name: 'hubToSpokeBPeering'
  params: {
    dstVNET_Name: spokeBVNET.outputs.vnetName
    originVNET_Name: hubVNET.outputs.vnetName
  }
}


// Windows Virtual Machines
module hubVM_Windows './Modules/NetTestVM.bicep' = {
  name: 'hubVMWindows'
  params: {
    accelNet: accelNet
    location: locationA
    nic_Name: 'hubNICWindows'
    subnetID: hubVNET.outputs.generalSubnetID
    vm_AdminPassword: vm_adminPassword
    vm_AdminUserName: vm_adminUsername
    vm_Name: 'hubVMWindows'
    vmSize: vmSize
  }
}

// Windows Virtual Machines
module spokeAVM_Windows './Modules/NetTestVM.bicep' = {
  name: 'spokeAVMWindows'
  params: {
    accelNet: accelNet
    location: locationA
    nic_Name: 'spokeANICWindows'
    subnetID: spokeAVNET.outputs.generalSubnetID
    vm_AdminPassword: vm_adminPassword
    vm_AdminUserName: vm_adminUsername
    vm_Name: 'spokeAVMWindows'
    vmSize: vmSize
  }
}

// Windows Virtual Machines
module spokeBVM_Windows './Modules/NetTestVM.bicep' = {
  name: 'spokeBVMWindows'
  params: {
    accelNet: accelNet
    location: locationA

    nic_Name: 'spokeBNICWindows'
    subnetID: spokeBVNET.outputs.generalSubnetID
    vm_AdminPassword: vm_adminPassword
    vm_AdminUserName: vm_adminUsername
    vm_Name: 'spokeBVMWindows'
    vmSize: vmSize
  }
}

module storageAccount 'modules/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: locationA
    privateEndpoints_Blob_Name: '${storageAccount_Name}blob_pe'
    storageAccount_Name: storageAccount_Name
    subnetID: spokeAVNET.outputs.privateEndpointSubnetID
    privateDNSZoneLinkedVnetIDList: [hubVNET.outputs.vnetID, spokeAVNET.outputs.vnetID, spokeBVNET.outputs.vnetID]
    privateDNSZoneLinkedVnetNamesList: [hubVNET.outputs.vnetName, spokeAVNET.outputs.vnetName, spokeBVNET.outputs.vnetName]
    privateEndpointVnetName: spokeAVNET.outputs.vnetName
  }
}

module hubBastion 'modules/Bastion.bicep' = {
  name: 'hubBastion'
  params: {
    bastionSubnetID: hubVNET.outputs.bastionSubnetID
    location: locationA
  }
}
