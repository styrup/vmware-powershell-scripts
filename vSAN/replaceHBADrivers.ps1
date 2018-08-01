param(        
    [Parameter(Mandatory = $true,HelpMessage="VM host")]
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$VMHost
)
$esxcli = Get-EsxCli -VMHost $VMHost -V2

# Check for NVMe driver version - module
$updateNVME = $false
$NVMeCheck = $esxcli.system.module.get.Invoke(@{"module"="intel-nvme"})
if($NVMeCheck.Version -eq "1.2.0.9-1OEM.600.0.0.2768847") {
    Write-Host "NVMe version OK"
} else {
    Write-Host "NVMe version have to be updatede!"
    $updateNVME = $true
}

#Check for HBA driver version - VIB (as it is not loaded)
$updateHBA = $false
$HBACheck = $esxcli.software.vib.get.Invoke(@{"vibname"="lsi-mr3"})
if($HBACheck.Version -eq "6.610.21.00-1OEM.600.0.0.2768847") {
    Write-Host "HBA version OK"
} else {
    Write-Host "HBA version have to be updatede!"
    $updateHBA = $true
}

if($updateNVME -or $updateHBA){
    Write-Host "Enter Maintenance Mode with VsanDataMigrationMode Full"
    Set-VMhost -State Maintenance -VMHost $VMHost -VsanDataMigrationMode Full
}

if($updateHBA){
    # Remove VIB
    $removeArgs = $esxcli.software.vib.install.CreateArgs()
    $removeArgs.vibname = "lsi-mr3"
    $removeArgs.force = $true
    Write-Host "Removing VIB..."
    $esxcli.software.vib.remove.Invoke($removeArgs)
    # Install new VIB
    $installArgs = $esxcli.software.vib.install.CreateArgs()
    $installArgs.viburl = "/vmfs/volumes/MY-DATASTORE/Drivers/HBA/lsi-mr3-6.610.21.00-1OEM.600.0.0.2768847.x86_64.vib"
    Write-Host "Installing new VIB..."
    $esxcli.software.vib.install.Invoke($installArgs)
    # Enable new module instead of megaraid_sas
    $enableArgs = $esxcli.system.module.set.CreateArgs()
    $enableArgs.module = "lsi_mr3"
    $enableArgs.enabled = $true
    Write-Host "Enabled driver module"
    $esxcli.system.module.set.Invoke($enableArgs)
}
if($updateNVME){
    # Update NVMe drivers.
    $updateArgs = $esxcli.software.vib.update.CreateArgs()
    $updateArgs.viburl = "/vmfs/volumes/MY-DATASTORE/Drivers/NVMe/intel-nvme-1.2.0.9-1OEM.600.0.0.2768847.x86_64.vib"
    Write-Host "Updating NVMe driver..."
    $esxcli.software.vib.update.Invoke($updateArgs)
}
if($updateNVME -or $updateHBA){
    # Restart host
    Write-Host "Restarting host.."
    Restart-VMHost -VMHost $VMHost -Confirm:$false
}