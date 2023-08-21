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
param vmSize string = 'Standard_B2ms' // 'Standard_D2s_v3' // 'Standard_D16lds_v5'

@description('''True enables Accelerated Networking and False disabled it.  
Not all VM sizes support Accel Net (i.e. Standard_B2ms).  
I'd recommend Standard_D2s_v3 for a cheap VM that supports Accel Net.
''')
param accelNet bool = false

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
param storageAccount_Name string

@description('Set this to true if you want to use an Azure Firewall in the Hub Virtual Network.')
param usingAzureFirewall bool = true


module hubVNET './Modules/Network/VirtualNetwork.bicep' = {
  name: 'hubVNET'
  params: {
    defaultNSG_Name: 'hubNSG'
    firstTwoOctetsOfVNETPrefix: '10.0'
    location: locationA
    routeTable_Name: 'hubRT'
    vnet_Name: 'hubVNET'
  }
}

module spokeAVNET './Modules/Network/VirtualNetwork.bicep' = {
  name: 'spokeAVNET'
  params: {
    defaultNSG_Name: 'dstNSG'
    firstTwoOctetsOfVNETPrefix: '10.1'
    location: locationA
    routeTable_Name: 'dstRT'
    vnet_Name: 'spokeAVNET'
  }
}

module hubToSpokeAPeering 'modules/Network/VirtualNetworkPeering.bicep' = {
  name: 'hubToSpokeAPeering'
  params: {
    dstVNET_Name: spokeAVNET.outputs.vnetName
    originVNET_Name: hubVNET.outputs.vnetName
  }
}

module spokeBVNET './Modules/Network/VirtualNetwork.bicep' = {
  name: 'spokeBVNET'
  params: {
    defaultNSG_Name: 'spokeBNSG'
    firstTwoOctetsOfVNETPrefix: '10.2'
    location: locationA
    routeTable_Name: 'spokeBRT'
    vnet_Name: 'spokeBVNET'
  }
}

module hubToSpokeBPeering 'modules/Network/VirtualNetworkPeering.bicep' = {
  name: 'hubToSpokeBPeering'
  params: {
    dstVNET_Name: spokeBVNET.outputs.vnetName
    originVNET_Name: hubVNET.outputs.vnetName
  }
}


// Windows Virtual Machines
module hubVM_Windows './Modules/Compute/NetTestVM.bicep' = {
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
module spokeAVM_Windows './Modules/Compute/NetTestVM.bicep' = {
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
module spokeBVM_Windows './Modules/Compute/NetTestVM.bicep' = {
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

module privateLink 'modules/Network/PrivateLink.bicep' = {
  name: 'privateLink'
  params: {
    location: locationA
    privateEndpoint_SubnetID: hubVNET.outputs.privateEndpointSubnetID
    privateLink_SubnetID: spokeBVNET.outputs.privateLinkServiceSubnetID
    slb_SubnetID: spokeBVNET.outputs.generalSubnetID
    virtualMachineNIC_Name: spokeBVM_Windows.outputs.nicName
    virtualMachineNIC_SubnetID: spokeBVNET.outputs.generalSubnetID
    virtualMachineNIC_IPConfig_Name: spokeBVM_Windows.outputs.nicIPConfig0Name
  }
}

module storageAccount 'modules/Storage/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: locationA
    privateEndpoints_Blob_Name: '${storageAccount_Name}_blob_pe'
    storageAccount_Name: storageAccount_Name
    privateEndpointSubnetID: spokeAVNET.outputs.privateEndpointSubnetID
    privateDNSZoneLinkedVnetIDList: [hubVNET.outputs.vnetID, spokeAVNET.outputs.vnetID, spokeBVNET.outputs.vnetID]
    privateDNSZoneLinkedVnetNamesList: [hubVNET.outputs.vnetName, spokeAVNET.outputs.vnetName, spokeBVNET.outputs.vnetName]
    privateEndpointVnetName: spokeAVNET.outputs.vnetName
  }
  // Added this dependancy so that the VMs can reach out to my other Storage Account to download a file
  // Since my other Storage Account has a private endpoint, the connectivity fails because I don't have an
  //  entry in my Private DNS Zone for the other Storage Account.
  dependsOn: [
    hubVM_Windows
    spokeAVM_Windows
    spokeBVM_Windows
  ]
}

module hubAzureFirewall 'modules/Network/AzureFirewall.bicep' = if (usingAzureFirewall) {
  name: 'hubAzureFirewall'
  params: {
    AzFW_Name: 'hubAzFW'
    AzFW_SKU: 'Basic'
    azfwManagementSubnetID: hubVNET.outputs.azfwManagementSubnetID
    AzFWPolicy_Name: 'hubAzFW_Policy'
    azfwSubnetID: hubVNET.outputs.azfwSubnetID
    location: locationA
  }
}

module hubBastion 'modules/Network/Bastion.bicep' = {
  name: 'hubBastion'
  params: {
    bastionSubnetID: hubVNET.outputs.bastionSubnetID
    location: locationA
  }
}
