<#
     Version: 1.0
     Author: Brendan O'Connor (VMWare Professional Services)
     Date: February 2018

     Disclaimer: this solution is not a validated or copywrite solution from VMWare.
                 This solution is an open source tool for vRealize Administrators to
                 utilize at their discression. You may copy, edit, and redistribute
                 this solution as you like.

     Purpose of this script: this solution is intended to demonstrate how to build
                 a powershell wrapper for PowerCLI commands. When this particular
                 script is executed, a blueprint is exported from vRealize Automation
                 and saved to a drop folder. 

     Prerequisites to runnin this script:
                 1. Download and install CloudClient
                 2. Run login autologinfile
                 3. Populate CloudClient.properties file
                 4. Populate input parameters below

     Input Parameters:
                 $cloudclienthome: path to the bin directory where cloudclient.bat is located
                 $dropFolder: the local directory where the blueprint yaml will be saved to
                 $blueprint_id: the id value of the blueprint from running vra content list
                 $blueprint_content_id: the contentId value of the blueprint from running vra content list

#>

$cloudclienthome = "C:\cloudclient-4.0.0-3343843\bin"
$dropFolder = "C:\cloudclient-4.0.0-3343843\temp"
$blueprint_id = "61832401-cc75-40fe-ab47-07d352319fac"
$blueprint_content_id = "Windows12R2"

cd $cloudclienthome

.\cloudclient.bat vra content export --path $dropFolder --id $blueprint_id --content-id $blueprint_content_id
