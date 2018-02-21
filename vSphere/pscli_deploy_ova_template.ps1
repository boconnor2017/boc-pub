<#
     Version: 1.0
     Author: Brendan O'Connor (VMWare Professional Services)
     Date: February 2018

     Disclaimer: this solution is not a validated or copywrite solution from VMWare.
                 This solution is an open source tool for vRealize Administrators to
                 utilize at their discression. You may copy, edit, and redistribute
                 this solution as you like.

     Purpose of this script: automate deployment of OVA files using PowerCLI

#>

<# Input Parameters #>
$vCenterServer = 'vcenter_fqdn'
$vCenter_username = 'administrator@vsphere.local'
$vCenter_password = 'password'
$ova_source = 'pathToFile.ova'
$ova_vm_name = 'nsxmgr01'
$vc_folder = 'NSX'
$esxi_Host = 'esxihost_fqdn'
$datastoreName = 'ds'


Connect-VIServer –Server $vCenterServer -Username $vCenter_username -Password $vCenter_password | Out-Null
Import-VApp -Source $ova_source -Name $ova_vm_name -VMHost $esxi_Host -Datastore $datastoreName
