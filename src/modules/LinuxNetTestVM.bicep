param location string

@description('Name of the Virtual Machine')
param vm_Name string

@description('Size of the VM')
param vmSize string

@description('Admin Username for the Virtual Machine')
param vm_AdminUserName string

@description('Password for the Virtual Machine Admin User')
@secure()
param vm_AdminPassword string

@description('Name of the Virtual Machines Network Interface')
param nic_Name string

@description('True enables Accelerated Networking and False disabled it.  Not all VM sizes support Accel Net')
param accelNet bool

param subnetID string

resource nic 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: nic_Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: accelNet
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
  }
}

resource linuxVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vm_Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${vm_Name}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        // managedDisk: {
        //   id: '/subscriptions/a2c8e9b2-b8d3-4f38-8a72-642d0012c518/resourceGroups/MAIN/providers/Microsoft.Compute/disks/Main-Ubn22-1-A_disk1_723e72ad87ce4572a075d5bbd7134aa1'
        // }
        deleteOption: 'Delete'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: vm_Name
      adminUsername: vm_AdminUserName
      adminPassword: vm_AdminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        // ssh: {
        //   publicKeys: [
        //     {
        //       path: '/home/jamesgodden/.ssh/authorized_keys'
        //       keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCe3LKU0hlW3S7giqGJgyn7fKZMHD8ZcJUpSY6UFmbZpxCh190EwLiyGboE9r9Kavi/VJsSg7BXZCCN2MYeDBHGfKkIKCxCZs+50rBz8d2KFiMh1OstdW61rYkAKOKbOB1ElaCP1CvxJ+6JQIjxJaCKIO3zUGYid/sPZonQCXTQ4NFljRsrZeq42SAmT+fOEGDI/apaQ9aFiJsYPRM620f4QESJmx7QE8w29MmUnWaqGnmfVHkRcCMIPAn8Plr0zg9SxIb/E5/yTUEbJpfvG36H7sxT3/DIGMVV6PAxjk4yzXuXZiJ1Xteri2Bfz0bgBwomSM5OCjhc0GT/4jd6ubj66q4DTqtPOcHfiQp9cfMhi8wgw8ksBo2jBJWpDMeAI5R7SXkAbIhu4+L0dP4AtfWOxj1Ap8gWjgSEE6ObcMfJJ7fSB+GNmFN+SCLT3+n3bjY2AfCOLMcOGo/qQ204HjLLDWj+r7y3p8M5iejIEXdrnFo4PJmmOGGp/ZP+Nt1eWlU= generated-by-azure'
        //     }
        //   ]
        // }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource vm_NetworkWatcherExtension 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  parent: linuxVM
  name: 'AzureNetworkWatcherExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
}
