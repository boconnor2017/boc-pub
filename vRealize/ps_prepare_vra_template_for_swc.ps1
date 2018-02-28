<#  
    The following script can be used to prepare a windows machine for software components. 
    Run this script on a Windows VM template prior to creating siftware component in vRA. 
    This script can be downloaded at https://<vra_fqdn>/software/index.html by clicking
    "prepare_vra_template.ps1".
    
    To execute this script, download to a local directory. cd into the directory where the
    ps1 is saved. Run 'PowerShell -NoProfile -ExecutionPolicy Bypass -Command prepare_vra_template.ps1' 
#>


# Parameters from the commandline to set the default variables

    param(
      [string]$ApplianceHost="",
      [string]$AppliancePort="443",
      [string]$ManagerServiceHost="",
      [string]$ManagerServicePort="443",
      [string]$CloudProvider="",
      [string]$SoftwareDomainUser="",
      [switch]$SoftwareLocalSystem=$false,
      [string]$SoftwarePassword="",
      [switch]$SoftwareLocalPasswordNeverExpire=$False,
      [string]$ApplianceFingerprint="",
      [string]$ManagerFingerprint="",
      [switch]$Uninstall=$false,
      [switch]$GuestAgentOnly=$false,
      [switch]$NonInteractive=$false
    )

# -----------------------------------------------------
#       USER CONFIGURATION - EDIT AS NEEDED
# -----------------------------------------------------

$guestAgentFolder="c:\VRMGuestAgent"

$vraSoftwareRoot="C:\opt"
$softwareAgentFolder="${vraSoftwareRoot}\vmware-appdirector"
$softwareAgentJavaFolder="${vraSoftwareRoot}\vmware-jre"

$logFile="${vraSoftwareRoot}\agentinstall.txt"

$prepareFolder="${vraSoftwareRoot}\prepare"
$jreInstaller="${prepareFolder}\jre.zip"
$guestAgentInstaller="${prepareFolder}\GuestAgentInstaller_x64.exe"
$softwareAgentInstaller="${prepareFolder}\bootstrap.zip"

# -----------------------------------------------------
#       END OF USER CONFIGURATION
# -----------------------------------------------------

# vsphere is the default and first in the list
$supportedCloudProviders = @("vsphere", "vca", "vcd", "ec2")

# -----------------------------------------------------
#       Functions
# -----------------------------------------------------
# function to write output to both file and screen
function Write-Feedback($msg)
{
    Write-Host -BackgroundColor "Black" -ForegroundColor "Green" $msg;
    $msg | Out-File $logFile -Append;
}

function Write-Feedback-Command($msg)
{
    Write-Host -BackgroundColor "Black" -ForegroundColor "Yellow" $msg;
    $msg | Out-File $logFile -Append;
}

function Write-Feedback-Error($msg)
{
    "Exiting - $msg" | Out-File $logFile -Append;
    throw $msg
}

# function to download files
function downloadNeededFiles($url,$file)
{
    Write-Feedback-Command "$file Downloading"
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $clnt = New-Object System.Net.WebClient
    $clnt.DownloadFile($url,$file)
    Write-Feedback "$file Downloaded"
}

# function to extract zip files
function extractZip($zipfile,$destination)
{
    Write-Feedback-Command "$zipfile Extracting"
    $shell = new-object -com shell.application
    if (!(Test-Path "$zipfile"))
    {
        throw "$zipfile does not exist"
    }
    New-Item -ItemType Directory -Force -Path $destination -WarningAction SilentlyContinue | Out-Null
    $shell.namespace($destination).copyhere($shell.namespace("$zipfile").items())
    Write-Feedback "$zipfile Extracted"
}

function detectCertificate()
{
    param($fileInput, $fileOutput, $tries, $sleepDelay, $openssl);
    $certificateFound=$False;

    # While certificate is not found,
    for ( $i=0; $i -lt $tries -and ( $certificateFound ) -eq $False ; $i++)
    {
        Start-Sleep -s $sleepDelay;
        $extract = Start-Process "${guestAgentFolder}\extractpem.bat" -windowStyle Hidden -Wait -PassThru -ArgumentList "${fileInput} ${fileOutput}"
        if($extract.ExitCode -eq 0)
        {
            $certificateFound = $True;
        }
        else
        {
            Write-Feedback "SSL Certificate not detected, waiting for $sleepDelay seconds before retry";
        }
    }

    Stop-Process -Id $openssl | Out-Null
    # Ensure it is stopped
    Start-Sleep -s $sleepDelay;

    return $certificateFound;
}

function remoteCertificateFingerprint()
{
    param($remoteHost,$remotePort);

    $wr = [Net.WebRequest]::Create("https://${remoteHost}:${remotePort}");
    try {
        $wr.GetResponse();
    }
    catch
    {
        # An error is inevitable if the URL is unreachable OR if the certificate
        # is untrusted.  This function is about asking the user to verify the
        # certificate fingerprint.
        $delayedError = $Error[0];
    }

    if ($wr.ServicePoint -eq $null -or $wr.ServicePoint.Certificate -eq $null) {
        Write-Feedback "Connecting to https://${remoteHost}:${remotePort} failed:"
        throw $delayedError
    }
    $cert = [Security.Cryptography.X509Certificates.X509Certificate2]$wr.ServicePoint.Certificate.Handle;
    $remoteFingerprint="";
    # Injecting ":" every two characters for consistency of presentation
    foreach ($c in $cert.Thumbprint.ToCharArray())
    {
        if (($remoteFingerprint.length % 3)-eq 2)
        {
            $remoteFingerprint = $remoteFingerprint + ":";
        }
        $remoteFingerprint = $remoteFingerprint + $c;
    }

    return $remoteFingerprint;
}

function fingerprintFromOpensslCertificate()
{
    param($pemFile);

    Start-Process "${guestAgentFolder}\bin\openssl.exe" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "${prepareFolder}\fingerprint.txt" -RedirectStandardError "${prepareFolder}\opensslerror.txt" -ArgumentList "x509 -noout -in $pemFile -fingerprint -sha1" | Out-Null
    $rawFingerprint = Get-Content "${prepareFolder}\fingerprint.txt"
    $downloadedFingerprint = ($rawFingerprint -split "=")[1]

    return $downloadedFingerprint
}

function downloadOpensslCertificate()
{
    param($remoteHost,$remotePort,$pemFile);

# The openssl binary has a documented problem where it does not exit properly
# even when it has been signalled there is no more input. The following code
# activities are intended to avoid the 2 minute pause while the openssl binary
# times out.  openssl is left running in the background until the expected
# output is found in the standard output.

    "QUIT" | Set-Content "${prepareFolder}\opensslinput.txt"
    $openssl = Start-Process -RedirectStandardInput "${prepareFolder}\opensslinput.txt" -RedirectStandardOutput "${prepareFolder}\openssloutput.txt" -RedirectStandardError "${prepareFolder}\opensslerror.txt" -NoNewWindow -PassThru "${guestAgentFolder}\bin\openssl" "s_client -connect ${remoteHost}:${remotePort}" | Select -Expand id

    $detected = detectCertificate "${prepareFolder}\openssloutput.txt" "${pemFile}" 5 5 $openssl

    Remove-Item -Force "${prepareFolder}\opensslinput.txt"
    Remove-Item -Force "${prepareFolder}\openssloutput.txt"
    Remove-Item -Force "${prepareFolder}\opensslerror.txt"

    if ($detected)
    {
        Write-Feedback "SSL Certificate for ${remoteHost}:${remotePort} found.";
    }
    else
    {
        Write-Feedback-Error "SSL Certificate for ${remoteHost}:${remotePort} not found.";
    }
}

function interactivelyMustAcceptOrReject()
{
    $result=""
    while ($result -eq "") {
        $inputAcceptFingerprint = Read-Host
        if ($inputAcceptFingerprint -eq "")
        {
            $result="false"
        }
        elseif ($inputAcceptFingerprint -eq "yes")
        {
            $result="true"
        }
        elseif ($inputAcceptFingerprint -eq "no")
        {
            $result="false"
        }
        else
        {
            Write-Host -noNewLine "Please type 'yes' or 'no': "
        }
    }
    return $result -eq "true"
}

# -----------------------------------------------------
#       End Functions
# -----------------------------------------------------


# -----------------------------------------------------
#       Log file start
# -----------------------------------------------------
# Creating Directory and Log file path

New-Item -ItemType Directory -Force -Path $vraSoftwareRoot | Out-Null
"Starting the log file" | Out-file -FilePath $logFile | Write-Host

# -----------------------------------------------------
#       CHECK POWERSHELL SESSION
# -----------------------------------------------------

$Elevated = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
& {
    if ($Elevated.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))
    {
        Write-Feedback "PowerShell is running as an administrator."
    }
    else
    {
        Write-Feedback-Error "Powershell must be run as an adminstrator."
    }
    if ($ENV:Processor_architecture -eq "AMD64" )
    {
        Write-Feedback "You are running 64-bit PowerShell."
    }
    else
    {
        Write-Feedback-Error "This script must exit as Windows 32 bit isn't supported."
    }
}
# -----------------------------------------------------
#       END OF POWERSHELL CHECK
# -----------------------------------------------------

# -----------------------------------------------------
#       Check Operating System Version and .NET Framework
# -----------------------------------------------------
# Grab the OS Name
$os = (get-WMiObject -class Win32_OperatingSystem).caption
Write-Feedback "OS = $os"
if ( $os -like "*2012 R2*" )
{
}
elseif ( $os -like "*2008 R2*" )
{
}
elseif ( $os -like "*2016 *" )
{
}
else
{
    Write-Feedback-Error "This script must exit due to unsupported operating system. $os is not supported please execute against Windows 2008 or 2012 R2 only!"
}
# -----------------------------------------------------
#       END OF OS CHECK
# -----------------------------------------------------

If (Test-Path $prepareFolder)
{
  Remove-Item -Recurse -Force $prepareFolder
}
New-Item -ItemType Directory -Force -Path $prepareFolder | Out-Null

# -----------------------------------------------------
#       Install Script
# -----------------------------------------------------

if (!$ApplianceHost)
{
    if ($NonInteractive)
    {
        Write-Feedback-Error "FQDN/IP/VIP of vRealize Appliance must be set in order to install."
    }
    else
    {
        $ApplianceHost = Read-Host -Prompt "FQDN/IP/VIP of vRealize Appliance (vraServer.domain)  "
    }
}

$remoteApplianceFingerprint = remoteCertificateFingerprint $ApplianceHost $AppliancePort
Write-Feedback "vRealize Appliance RSA key fingerprint is ${remoteApplianceFingerprint}"
if (!$ApplianceFingerprint)
{
    if ($NonInteractive)
    {
        Write-Feedback-Error "No matching verification RSA key fingerprint supplied"
    }
    else
    {
        Write-Host -noNewLine "Do you accept this for the vRealize Appliance (yes/no)? "
        $accept = interactivelyMustAcceptOrReject;
        if (! $accept)
        {
            Write-Feedback-Error "Verification of vRealize Appliance RSA key failed."
        }
    }
}
elseif ($ApplianceFingerprint -ne $remoteApplianceFingerprint)
{
    Write-Feedback-Error "Does not match verification RSA key fingerprint $ApplianceFingerprint."
}


if (!$ManagerServiceHost)
{
    if ($NonInteractive)
    {
        Write-Feedback-Error "FQDN/IP/VIP of Manager Service Server must be set in order to install."
    }
    else
    {
        $ManagerServiceHost = Read-Host -Prompt "FQDN/IP/VIP of Manager Service Server (windowsServer.domain)  "
    }
}

$remoteManagerFingerprint = remoteCertificateFingerprint $ManagerServiceHost $ManagerServicePort
Write-Feedback "Manager Service RSA key fingerprint is ${remoteManagerFingerprint}"
if (!$ManagerFingerprint)
{
    if ($NonInteractive)
    {
        Write-Feedback-Error "No matching verification RSA key fingerprint supplied"
    }
    else
    {
        Write-Host -noNewLine "Do you accept this for the Manager Service (yes/no)? "
        $accept = interactivelyMustAcceptOrReject;
        if (! $accept)
        {
            Write-Feedback-Error "Verification of Manager Service RSA key failed."
        }
    }
}
elseif ($ManagerFingerprint -ne $remoteManagerFingerprint)
{
    Write-Feedback-Error "Does not match verification RSA key fingerprint $ManagerFingerprint."
}

if (!$CloudProvider)
{
    if ($NonInteractive)
    {
        $CloudProvider = "vsphere"
    }
    else
    {
        $cloudProviders = ""
        foreach ($element in $supportedCloudProviders)
        {
            if ($cloudProviders)
            {
                $cloudProviders += ", " + $element
            }
            else
            {
                $cloudProviders = $element
            }
        }
        $CloudProvider = Read-Host -Prompt "Cloud Provider (default=$cloudProviders) "
        if (! $CloudProvider)
        {
            $CloudProvider = "vsphere"
        }
        else
        {
            $found=$false
            foreach ($element in $supportedCloudProviders)
            {
                $found = ($element -eq $CloudProvider)
                if ($found)
                {
                    break
                }
            }
            if (! $found)
            {
                Write-Feedback-Error "Please select one of $cloudProviders"
            }
        }
    }
}

if ($SoftwareLocalSystem)
{
    if ($SoftwareDomainUser)
    {
        Write-Feedback-Error "Please select one of SoftwareLocalSystem or SoftwareDomainUser"
    }
}
else
{
    if (!$SoftwareLocalSystem -and !$NonInteractive)
    {
        $userType = Read-Host -Prompt "Software Agent User Type (default=localSystem, domainUser) "
        if ($userType -eq "" -or $userType -eq "localSystem")
        {
            $SoftwareLocalSystem=$true
        }
        elseif ($userType -eq "domainUser")
        {
            $SoftwareDomainUser = Read-Host -Prompt "Software Agent DOMAIN user: "
            if (!$SoftwareDomainUser)
            {
                Write-Feedback-Error "Please specify a DOMAIN user"
            }
        }
        else
        {
            Write-Feedback-Error "Please specify localSystem or domainUser"
        }
    }
    elseif (!$SoftwareLocalSystem -and !$SoftwareDomainUser -and $NonInteractive)
    {
        $SoftwareLocalSystem=$true
    }
}

if ($SoftwareDomainUser)
{
    if ($NonInteractive)
    {
        Write-Feedback-Error "Please specify SoftwarePassword for $SoftwareDomainUser"
    }
    else
    {
        $SecurePassword = read-Host -asSecureString -Prompt "$SoftwareDomainUser user password  "
        $SoftwarePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
    }
}

Write-Feedback "vRA Appliance is ${ApplianceHost}:${AppliancePort}"
Write-Feedback "Manager Service Server is ${ManagerServiceHost}:${ManagerServicePort}"
if ($SoftwareLocalSystem)
{
    Write-Feedback "Software Service to run as LocalSystem"
}
else
{
    Write-Feedback "Software Service to run as $SoftwareDomainUser"
}


# -----------------------------------------------------
# Set the download files needed based on your vRA Version
$bootstrapFile="https://" + $ApplianceHost + ":" + $AppliancePort + "/software/download/vmware-vra-software-agent-bootstrap-windows_7.3.0.0.zip"
$agentFile="https://" + $ApplianceHost + ":" + $AppliancePort + "/software/download/GuestAgentInstaller_x64.exe"
$javaFile="https://" + $ApplianceHost + ":" + $AppliancePort + "/software/download/jre-1.8.0_121-win64.zip"

# -----------------------------------------------------
#       Download and execute the Guest Agent Installer
# -----------------------------------------------------
Write-Feedback-Command "Downloading Guest Agent $agentFile"
downloadNeededFiles $agentFile $guestAgentInstaller

# If the Guest Agent is already installed, then uninstall it
if (Test-Path ${guestAgentFolder})
{
    Write-Feedback-Command "Stopping and uninstalling previous Guest Agent"
    Start-Process "${guestAgentFolder}\WinService" -Wait -PassThru -NoNewWindow -ArgumentList "-k" | Out-Null
    Start-Process "${guestAgentFolder}\WinService" -Wait -PassThru -NoNewWindow -ArgumentList "-u" | Out-Null
    $doagent = Get-WmiObject Win32_Process | Where-Object {$_.CommandLine -like "*VRMGuestAgent\doag*"} | select -expand ProcessId
    if ($doagent)
    {
        Stop-Process -Force -Id $doagent
        Get-WmiObject Win32_Process | Where-Object {$_.ParentProcessId -match $doagent} | Invoke-WmiMethod -Name Terminate | Out-Null
    }
    Remove-Item -force -recurse ${guestAgentFolder} | Out-Null
}
Write-Feedback-Command "Executing: $guestAgentInstaller"
cd c:\
Start-Process $guestAgentInstaller -Wait
Write-Feedback "$guestAgentInstaller Executed"

# By convention, the Software Agent Bootstrap install also configures the
# Guest Agent, but in $GuestAgentOnly mode we execute the relevant code here
#
# In both cases, the cert.pem file is downloaded and verified against the
# fingerprint below.

if ($GuestAgentOnly)
{
    Write-Feedback-Command "Configuring and installing Guest Agent"
    cd $guestAgentFolder
    Start-Process "${guestAgentFolder}\WinService" -Wait -PassThru -NoNewWindow -ArgumentList "-i -h ${ManagerServiceHost}:${ManagerServicePort} -c $CloudProvider" | Out-Null
}
else
{
    # -----------------------------------------------------
    #       Download and Extract the JRE components
    # -----------------------------------------------------
    if (Test-Path $softwareAgentJavaFolder)
    {
        Remove-Item -recurse -force $softwareAgentJavaFolder | Out-Null
    }
    New-Item -ItemType Directory -Force -Path $softwareAgentJavaFolder | Out-Null

    Write-Feedback-Command "Downloading JRE $javaFile"

    downloadNeededFiles $javaFile $jreInstaller
    extractZip $jreInstaller "${softwareAgentJavaFolder}\"

    # Download and execute vRA bootstrap agent
    cd $prepareFolder
    Write-Feedback-Command "Downloading Bootstrap $bootstrapFile"
    downloadNeededFiles $bootstrapFile $softwareAgentInstaller
    extractZip $softwareAgentInstaller $prepareFolder

    Write-Feedback-Command "Executing install.bat"
    if (Test-Path "${softwareAgentFolder}\agent-bootstrap\bootstrapWin.exe")
    {
        Start-Process "${softwareAgentFolder}\agent-bootstrap\bootstrapWin.exe" -Wait -PassThru -NoNewWindow -ArgumentList "/uninstall" | Out-Null
        Remove-Item -Recurse "${softwareAgentFolder}\agent-bootstrap"
    }
    if (Test-Path "${softwareAgentFolder}\agent")
    {
        Remove-Item -Recurse "${softwareAgentFolder}\agent"
    }

    $bootstrapFile = ("install.bat")
    #
    # The arguments change because of the user choices
    #
    $argumentList = "managerServiceHost=$ManagerServiceHost managerServicePort=$ManagerServicePort cloudProvider=$CloudProvider"
    if ($SoftwareLocalSystem)
    {
       $argumentList = " $argumentList localSystem=true"
       Write-Feedback "Command to run: install.bat $argumentList"
    }
    else
    {
        $argumentList = "$argumentList domainUser=$SoftwareDomainUser"
        Write-Feedback "Command to run: install.bat $argumentList password=******"
        $argumentList = "$argumentList password=$SoftwarePassword"
    }
    $bootstrapInstall = Start-Process $bootstrapFile -ArgumentList $argumentList -Wait | Out-File -FilePath $logFile -Append
    Write-Feedback "Execution completed: install.bat"
}

Write-Feedback-Command "Downloading Manager Service Certificate"

downloadOpensslCertificate $ManagerServiceHost $ManagerServicePort ${guestAgentFolder}\cert.pem
Write-Feedback "Manager Service Host SSL certificate downloaded to ${guestAgentFolder}\cert.pem"

$downloadedManagerFingerprint = fingerprintFromOpensslCertificate ${guestAgentFolder}\cert.pem

if ($remoteManagerFingerprint -eq $downloadedManagerFingerprint)
{
    Write-Feedback "Manager Service Host SSL certificate matches SSL fingerprint $remoteManagerFingerprint"
}
else
{
    # This should never happen but this correlates the fingerprint collected earlier
    Write-Feedback "Manager Service Host SSL certificate fails to match SSL fingerprint $remoteManagerFingerprint"
    Remove-Item "${guestAgentFolder}\cert.pem"
    Write-Feedback-Error "Manager Service host key verification failed."
}


# -----------------------------------------------------
#       Install Script Complete
# -----------------------------------------------------

# -----------------------------------------------------
#       Cleaning up
# -----------------------------------------------------
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $script:MyInvocation.MyCommand.Path }
cd $PSScriptRoot
Write-Feedback "Cleaning up downloaded files"
Remove-Item -recurse $prepareFolder

# -----------------------------------------------------
#       Clean up complete
# -----------------------------------------------------

Write-Feedback "INSTALL COMPLETE Ready for shutdown"

# -----------------------------------------------------
#       End Log File
# -----------------------------------------------------
