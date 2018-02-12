<#
     Version: 1.1
     Author: Brendan O'Connor (VMWare Professional Services)
     Date: February 2018

     Disclaimer: this solution is not a validated or copywrite solution from VMWare.
                 This solution is an open source tool for vRealize Administrators to
                 utilize at their discression. You may copy, edit, and redistribute
                 this solution as you like.

     Purpose of this script: this solution is intended to automate the deployment of
                 Windows VMs needed for installation of vRealize Automation 7.x. For
                 specific details of the required reference architecture, please review
                 the vRealize Automation Installation and Configuration Guide.

     How it Works: this script uses PowerCLI to execute the following commands:
                 01. Connect-VIServer
                 02. Get-OSCustomizationSpec
                 03. Get-OSCustomizationNicMapping
                 04. Set-OSCustomizationNicMapping
                 05. New-VM
                 06. Set-VM
                 07. Get-HardDisk
                 08. Set-HardDisk
                 09. Start-VM
                 10. Set-NetworkAdapter
                 11. Get-VIEvent
     
     For details on each of these commands, please refer to VMWare PowerCLI Documentation. 


#>

<# 
    Procedure:
      1. Create (or use) a Windows VM template with Java installed and JAVA_HOME configured
      2. Create (or use) a Windows customization spec that performs sysprep, applies license, and registers to domain
      3. Download and install PowerCLI to a desktop or jump host with access to vCenter
      4. Save this script to a local directory
      5. Populate Input Parameters 
      6. Open powerCLI, navigate to the local directory containing this script
      7. Run ./pscli_installVRAIaaSVMs_Win12R2.ps1
      

#>

<# 
    Input Parameters:
      01. $vCenterServer: the FQDN of your vCenter (powerCLI will make a connection to this vCenter)
      02. $vCenterUsername: a vCenter user or service account with administrative rights
      03. $vCenterPassword: the password for the vCenter service account or user
      04. $templateName: the name of the Windows template to clone (IaaS machines will be built with this template)
      05. $hostName: the name of the host to deploy the IaaS VMs
      06. $datastoreName: the name of the datastore to host the IaaS VMs
      07. $networkName: the name of the port group to conect the IaaS VMs
      08. $targetVCenterFolderName: the vCenter folder to store the virtual machines created by this script
      09. $defaultGateway: the default gateway for the IaaS VMs
      10. $subnetMask: the subnet mask for the IaaS VMs
      11. $dnsServers: a comma separates list of DNS servers for the IaaS VMs
      12. $osCustomizationSpec: an OS customization spec for Windows deployments
      13. $iaaSVMNames: a list of windows machine names to deploy for IaaS
      14. $iaaSVMIPs: a list of IP addresses to apply to each windows IaaS VM

#>

<# Input Parameters #>
$vCenterServer = 'vcenter.domain.local'
$vCenter_username = 'administrator@vsphere.local'
$vCenter_password = 'password'
$templateName = 'vra_iaas_win12r2'
$hostName = 'esxhost.domain.local'
$datastoreName = 'my_datastore'
$networkName = 'my_portgroup'
$targetVCenterFolderName = 'vRealize'
$defaultGateway = '10.0.0.1'
$subnetMask = '255.255.255.0'
$dnsServers = '10.0.0.2'
$osCustomizationSpec = 'win12r2'

$iaaSVMNames = @('vraiaasmgr01', 'vraiaasweb01', 'vraiaasdem01')
$iaaSVMIPs = @('10.0.0.10', '10.0.0.11', '10.0.0.12')


<# Connect to vCenter #>
echo 'Connecting to vCenter '+$vCenterServer
Connect-VIServer –Server $vCenterServer -Username $vCenter_username -Password $vCenter_password | Out-Null

<# Create IaaS Machine #>
function CreateIaaSVM($iaaSVMName, $iaasVMIP, $osCustomizationSpec, $templateName, $hostName, $targetVCenterFolderName, $datastoreName, $networkName){
   $newVMName = $iaaSVMName
   $newVMIPAddress = $iaasVMIP


   echo '=========='$newVMName '=========='
   echo 'Configuring network information within customization spec'
   Get-OSCustomizationSpec $osCustomizationSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $newVMIPAddress -SubnetMask $subnetMask -DefaultGateway $defaultGateway -Dns $dnsServers

   echo 'Creating New VM from template'
   New-VM -Template $templateName -Name $newVMName -VMHost $hostName -Location $targetVCenterFolderName -Datastore $datastoreName -DiskstorageFormat Thin -OSCustomizationSpec $osCustomizationSpec |
   Set-VM -OSCustomizationSpec $osCustomizationSpec -NumCpu 4 -MemoryMB 8192 -Confirm:$false |
   Get-HardDisk | Set-HardDisk -CapacityGB 50.000 -Confirm:$false 

   echo 'Power On VM'
   Start-VM $newVMName -Confirm:$false

   echo 'Configure vNIC'
   $networkAdaptor = Get-NetworkAdapter -VM $newVMName
   Set-NetworkAdapter $networkAdaptor -NetworkName $networkName -Connected:$true -Confirm:$false

   echo 'Waiting for OS customization to complete...'
   function CheckOSCustomization($newVMName){
      while ($True)
      {
        $vmToMonitor = $newVMName
		$vmEvents = Get-VIEvent -Entity $vmToMonitor
		$succeedEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationSucceeded" }
		$failEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationFailed" }
 
		if ($failEvent)
		{
			return $False
		}
 
		if($succeedEvent)
		{
			return $True
		}
 
		Start-Sleep -Seconds 2			
	   }
    }

$isOSCustomizationSuccessful = CheckOSCustomization $newVMName
return $isOSCustomizationSuccessful
}

echo 'Scheduling job to create ' $iaaSVMNames.Length ' vRA IaaS Machines'
For ($i=0; $i -lt $iaaSVMNames.Length; $i++){
  CreateIaaSVM $iaaSVMNames[$i] $iaasVMIPs[$i] $osCustomizationSpec $templateName $hostName $targetVCenterFolderName $datastoreName $networkName
}
