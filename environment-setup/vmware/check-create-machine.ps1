#! /usr/bin/pwsh

param(
    [string]$VMWareUser,
    [string]$VMWarePassword,
    [string]$VMWareServer,
    [string]$MachineName,
    [string]$EnvFolderName,
    [string]$ProjectFolderName,
    [string]$NetworkName,
    [string]$TemplateName,
    [string]$ClusterName,
    [string]$DatastoreClusterName
)

# Install the PowerCLI module
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
Find-Module "VMware.PowerCLI" | Install-Module -Scope "CurrentUser" -AllowClobber
Import-Module "VMware.PowerCLI"
Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore  -Confirm:$false

# Check if the environmnet doesn't exist then create it
Connect-VIServer -Server $VMWareServer -User $VMWareUser -Password $VMWarePassword
$Exists = get-vm -name $MachineName -ErrorAction SilentlyContinue  
If ($Exists){  
    Write-Output "The VM exists"
    # Start the VM if it is not running and wait until it gets an IP
    $vmIsRunning = (Get-VM -Name $MachineName).PowerState -eq "PoweredOn"
    if(-Not $vmIsRunning){
        Start-VM -VM $MachineName
        Do {
            Write-host "Waiting for the machine IP... " -ForegroundColor Yellow;
            $ipAddress= ( Get-VM -Name $MachineName).guest.IPAddress[0]
            Start-Sleep -Seconds 10
        }
        While (!$ipAddress)
    }
}  
Else {  
     Write-host "The VM doesn't exist. Creating the VM...." -ForegroundColor Yellow;
     $Template = Get-Template -Name $TemplateName
     $myCluster = Get-Cluster -Name $ClusterName
     $datastoreCluster=Get-DatastoreCluster $DatastoreClusterName
     $location= (Get-Folder $EnvFolderName) | Where-Object Parent -Match  (Get-Folder $ProjectFolderName)
     New-VM -Name $MachineName -Template $Template -Confirm:$false -Location $location -VMHost (Get-VMHost | Select-Object -first 1) -ResourcePool  $myCluster -Datastore  $datastoreCluster

     # Setting the newtork adapter
     Write-Output "Setting the network adapter..."
     Get-VM -Name $MachineName | Get-NetworkAdapter -Name "Network adapter 1" | Set-NetworkAdapter -NetworkName $NetworkName -Confirm:$false

     # Power On the machine
     Start-VM -VM $MachineName

     # Get the IP Address
     Do {
        Write-host "Waiting for the machine IP... " -ForegroundColor Yellow;
        $ipAddress= ( Get-VM -Name $MachineName).guest.IPAddress[0]
        Start-Sleep -Seconds 10
     }
     While (!$ipAddress)
    
     Write-Output "The new machine IP: $ipAddress"
}