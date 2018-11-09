# VMWare PSO Tutorials
How to use: clone boc-pub or select specific tutorials below. From CLI use wget <path_to_raw_code> to download script directly, or use git clone https://github.com/boconnor2017/boc-pub.git to download the entire boc-pub repository. 

# vRealize
VMWare vRealize Suite tutorials: vRealize Automation, vRealize Business, vRealize Operations, vRealize Log Insight, vRealize Code Stream and vRealize Network Insight. 

   - vRealize Suite Lifecycle Management Tutorials
   
        -- Local directory for OVAs: /data
   
        -- PowerCLI script to automate deployment of IaaS Virtual Machines
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/InstallManagementAgent.ps1 
           
        -- Procedure to automate deployment of IaaS Virtual Machines using PowerCLI
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/03-PowerCLI%20script%20to%20Setup%20Windows%20Servers%20for%20vRealize%20Automation%207.x.docx
           
        -- PowerShell script to automate installation of the IaaS Management components on Windows machines
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/InstallManagementAgent.ps1  
           
        -- Powershell/CloudClient script to export Blueprint to yaml file
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/pscc_export_blueprint.ps1
           
        -- XaaS Blueprint: edit vRA catalog item JSON and submit
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/com.vmware.vra.xaas.submitcatalogitem.package
           
        -- Steps to connect and query embedded vRealize Automation postgres database
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/connect_to_vra_postgres.txt 
           
        -- Sample JSON: Deploy vRA POC Environment using vRLCM Configuration File
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/vrlcm_vra_small.json
           
        -- Sample JSON: Deploy vROPS POC Environment using vRLCM Configuration File
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/vrlcm_vrops_small.json
           
        -- Sample JSON: Deploy vRB POC Environment using vRLCM Configuration File
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/vrlcm_vrb_small.json
           
        -- Sample JSON: Deploy vRLI POC Environment using vRLCM Configuration File
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/vrlcm_vrli_sm.json
           
        -- Powershell script to automate preparation of Windows template for Software Components
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/ps_prepare_vra_template_for_swc.ps1
           
        -- Shell script to automate preparation of Linux template for Software Components
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/sh_prepare_vra_template_for_swc.sh
           
        -- Shell script to synch vRA appliance to NTP server
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/synch_vra_to_domain.sh
           
        -- Bash command to restart vra installation wizard 
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/restart_vra_wizard.txt

           
    - Guest Level Operations (Windows, Linux, PhotonOS, etc)
        
        -- Shell script to automate installation of NodeJS
           https://github.com/boconnor2017/boc-pub/blob/master/PhotonOS/installNodeJS.sh
        
        -- Bash command to open Linux ports
           https://github.com/boconnor2017/boc-pub/blob/master/vRealize/iptables.txt 

# vSphere Integrated Openstack
   - Sample json configuration for VIO with Kubernetes: https://github.com/boconnor2017/boc-pub/blob/master/VIO/vio_with_kubernetes.json 
# VMWare Cloud Foundation
VMWare Cloud Foundation tutorials: Dell, Cisco, ONIE, SDDC Manager, ESXi, vSAN, NSX

   - VMWare Cloud Foundation Imaging and Bringup 
   
       -- Helpful CLI commands and references during deployment of VCF
          https://github.com/boconnor2017/boc-pub/blob/master/VCF/helpful_cli_and_references.txt

# Hybrid Cloud Extension (HCX)
   - Steps to resolve "Untrusted SSL connection" during site pairing: https://github.com/boconnor2017/boc-pub/blob/master/HCX/generateSSL.txt

# vSphere
VMWare vSphere tutorials: vCenter and ESXi

   - General vSphere Tutorials
   
       -- PowerCLI script to deploy OVA template
          https://github.com/boconnor2017/boc-pub/blob/master/vSphere/pscli_deploy_ova_template.ps1  
          
       -- Helpful esxcli commands: 
          https://github.com/boconnor2017/boc-pub/blob/master/vSphere/esxcli_commands.txt
          
       -- PowerCLI script to power on all powered off vms: https://github.com/boconnor2017/boc-pub/blob/master/vSphere/pscli_restart_all_powered_off_vms.ps1
      
 # vSAN
 Virtual SAN tutorials
 
 - Helpful esxcli commands: https://github.com/boconnor2017/boc-pub/blob/master/vSAN/esxcli_commands.txt 
 - vSAN Sizing Calculator: https://kauteetech.github.io/vsancapacity/allflash  
