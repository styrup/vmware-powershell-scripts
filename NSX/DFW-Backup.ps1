<#
    .NOTES
    ===========================================================================
     Created by:    Jacob Styrup Bang
     Organization:  AUIT - Aarhus University
     Twitter:       @styrup
        ===========================================================================
    .DESCRIPTION
        This script uses the NSX API and exports the firewall rules and the Security Groups to XML.
        The backup files are stored under nsx-backup and 2 files with timestamp.
#>

# Quick and dirty credentials setup. Use more clever solution...
$username = "username"
$password = "password"
$NSXMGR_BASE_URL = "https://nsx-mgr-fqdn/api"

# timestamp: day month year and time, DK style.
$xmlfilename = get-date -Format "ddMMyyyy-HHmm"

# Firewall Backup 
$Path = "$(Get-Location)\nsx-backup\$($xmlfilename)-nsx-rules.xml"
$TURL = "/4.0/firewall/globalroot-0/config"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$firewallConfig = Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo);"Accept"="application/xml";"Content-Type"="application/xml"} -uri "$NSXMGR_BASE_URL$TURL" -Method Get -ContentType "application/xml"
$firewallConfig.Content | Out-File -Encoding utf8 -FilePath $Path

# Security Groups Backup 
$Path = "$(Get-Location)\nsx-backup\$($xmlfilename)-nsx-securitygroups.xml"
$TURL = "/2.0/services/securitygroup/scope/globalroot-0"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$SGConfig = Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo);"Accept"="application/xml";"Content-Type"="application/xml"} -uri "$NSXMGR_BASE_URL$TURL" -Method Get -ContentType "application/xml"
$SGConfig.Content | Out-File -Encoding utf8 -FilePath $Path