<#
     Version: 1.0
     Author: Brendan O'Connor (VMWare Professional Services)
     Date: June 2018
     Disclaimer: this solution is not a validated or copywrite solution from VMWare.
                 This solution is an open source tool for VMWare Administrators to
                 utilize at their discression. You may copy, edit, and redistribute
                 this solution as you like.
     Purpose of this script: power on all VMs that are powered off
#>

# Prerequisites
#   vCenter must be powered on and accessible

<# Input Parameters #>
$vCenterServer = 'vcenter_fqdn'
$vCenter_username = 'administrator@vsphere.local'
$vCenter_password = 'password'

# Connect to vCenter
Connect-VIServer –Server $vCenterServer -Username $vCenter_username -Password $vCenter_password | Out-Null

# Retrieve list of Powered Off VMs
$listOfVirtualMachines = Get-VM | Where-object {$_.powerstate -eq "poweredoff"}
$numberOfVirtualMachines = $listOfVirtualMachines.Length
echo 'Total Number of Powered Off VMs: ' $numberOfVirtualMachines
#echo $listOfVirtualMachines

# Power On VMs
foreach ($element in $listOfVirtualMachines) {
  echo 'Powering on' $element
  Start-VM -VM $element
  
}

