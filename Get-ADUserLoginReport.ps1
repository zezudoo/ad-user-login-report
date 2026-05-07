[CmdletBinding()]
param(
    [string]$SearchBase,
    [string]$OutputPath = ".\AD_User_Login_Report.csv",
    [switch]$UseExactLastLogon
)

Import-Module ActiveDirectory -ErrorAction Stop

function Get-OUPath {
    param(
        [string]$CanonicalName,
        [string]$DistinguishedName
    )

    if ($CanonicalName) {
        $parts = $CanonicalName -split '/'
        if ($parts.Count -ge 3) {
            return ($parts[1..($parts.Count - 2)] -join '/')
        }
    }

    if ($DistinguishedName) {
        return ($DistinguishedName -replace '^CN=.*?,', '')
    }

    return $null
}

function Get-ExactLastLogonInfo {
    param(
        [Parameter(Mandatory)][string]$SamAccountName,
        [Parameter(Mandatory)][array]$DomainControllers
    )

    $latestLogon = $null
    $latestDc = $null

    foreach ($dc in $DomainControllers) {
        try {
            $userOnDc = Get-ADUser `
                -Identity $SamAccountName `
                -Server $dc.HostName `
                -Properties lastLogon `
                -ErrorAction Stop

            if ($userOnDc.lastLogon -and [int64]$userOnDc.lastLogon -gt 0) {
                $candidate = [DateTime]::FromFileTime([int64]$userOnDc.lastLogon)

                if (-not $latestLogon -or $candidate -gt $latestLogon) {
                    $latestLogon = $candidate
                    $latestDc = $dc.HostName
                }
            }
        }
        catch {
            Write-Verbose "Could not read lastLogon for $SamAccountName on $($dc.HostName): $($_.Exception.Message)"
        }
    }

    [PSCustomObject]@{
        LastLogon   = $latestLogon
        LastLogonDC = $latestDc
    }
}

$adParams = @{
    LDAPFilter     = '(&(objectCategory=person)(objectClass=user))'
    Properties     = @(
        'DisplayName',
        'SamAccountName',
        'UserPrincipalName',
        'Enabled',
        'DistinguishedName',
        'CanonicalName',
        'PasswordLastSet',
        'LastLogonDate'
    )
    ResultPageSize = 2000
}

if ($SearchBase) {
    $adParams.SearchBase = $SearchBase
}

$users = @(Get-ADUser @adParams | Sort-Object Name)

$domainControllers = @()
if ($UseExactLastLogon) {
    $domainControllers = @(Get-ADDomainController -Filter * | Sort-Object HostName)
}

$total = $users.Count
$index = 0

$report = foreach ($user in $users) {
    $index++

    if ($total -gt 0) {
        Write-Progress `
            -Activity "Building AD user report" `
            -Status "$index / $total - $($user.SamAccountName)" `
            -PercentComplete (($index / $total) * 100)
    }

    $lastLogon = $user.LastLogonDate
    $lastLogonDc = $null

    if ($UseExactLastLogon) {
        $exactInfo = Get-ExactLastLogonInfo `
            -SamAccountName $user.SamAccountName `
            -DomainControllers $domainControllers

        $lastLogon = $exactInfo.LastLogon
        $lastLogonDc = $exactInfo.LastLogonDC
    }

    [PSCustomObject]@{
        Name              = $user.Name
        DisplayName       = $user.DisplayName
        SamAccountName    = $user.SamAccountName
        UserPrincipalName = $user.UserPrincipalName
        Status            = if ($user.Enabled) { 'Active' } else { 'Disabled' }
        LastLogon         = $lastLogon
        LastLogonDC       = $lastLogonDc
        PasswordLastSet   = $user.PasswordLastSet
        OU                = Get-OUPath `
            -CanonicalName $user.CanonicalName `
            -DistinguishedName $user.DistinguishedName
        DistinguishedName = $user.DistinguishedName
    }
}

Write-Progress -Activity "Building AD user report" -Completed

$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Report exported to: $OutputPath"

