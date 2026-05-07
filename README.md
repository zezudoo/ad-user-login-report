# AD User Login Report

Language: English | [Português (Brasil)](README.pt-BR.md)

PowerShell script that exports an Active Directory user login report to CSV.

## Features

- Lists AD users with status, UPN, OU, password last set, and last login.
- Can query exact `lastLogon` values across all domain controllers.
- Supports limiting the query to a specific `SearchBase`.
- Generates a CSV report useful for audits and cleanup routines.

## Requirements

- Windows PowerShell 5.1, or PowerShell 7 with RSAT AD module support.
- Active Directory PowerShell module.
- Permission to read users and domain controllers.

## Usage

```powershell
.\Get-ADUserLoginReport.ps1 -OutputPath .\AD_User_Login_Report.csv
```

Query a specific OU:

```powershell
.\Get-ADUserLoginReport.ps1 `
  -SearchBase "OU=Users,DC=example,DC=com" `
  -OutputPath .\AD_User_Login_Report.csv
```

Use exact `lastLogon` by querying every domain controller:

```powershell
.\Get-ADUserLoginReport.ps1 -UseExactLastLogon -OutputPath .\AD_User_Login_Report.csv
```

`-UseExactLastLogon` is slower, but more precise than the replicated
`LastLogonDate` value.
