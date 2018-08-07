<#
.SYNOPSIS Enabling the SSD option on SSD based disks
.NOTES  Author:  Jacob Styrup Bang
.NOTES  Site:    http://blog.styrupnet.dk
.NOTES  Reference: https://kb.vmware.com/kb/2013188
.PARAMETER Vmhost
  ESXi host
#>
param(        
    [Parameter(Mandatory = $true,HelpMessage="VM host")]
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$VMHost
)
$esxcli = Get-EsxCli -VMHost $VMHost -V2
$vDisks = $esxcli.vsan.storage.list.Invoke()
# Get all the non SSDs and capacity disks.
$capacityDisks = $vDisks | where{($_.IsCapacityTier -eq $true) -and ($_.IsSSD -eq $false)} | Select-Object -Property Displayname

foreach($capacityDisk in $capacityDisks){
    ## This is for tag flash disk to capacityFlash
    ## $esxcli.vsan.storage.tag.add.Invoke(@{"tag"="capacityFlash";"disk"=$($capacityDisk.Displayname)})
    $naa = "$($capacityDisk.Displayname)"
    $esxcli.storage.nmp.satp.rule.remove.Invoke(@{"satp"="VMW_SATP_LOCAL";"device"=$($naa)})
    $esxcli.storage.nmp.satp.rule.add.Invoke(@{"satp"="VMW_SATP_LOCAL";"device"=$($naa);"option"="enable_ssd"})
}
