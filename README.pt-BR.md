# Relatório de Login de Usuários do AD

Idioma: [English](README.md) | Português (Brasil)

Script PowerShell que exporta um relatório de login de usuários do Active
Directory para CSV.

## Recursos

- Lista usuários do AD com status, UPN, OU, última alteração de senha e último login.
- Permite consulta exata de `lastLogon` em todos os controladores de domínio.
- Suporta limitar a consulta a uma `SearchBase` específica.
- Gera um relatório CSV útil para auditoria e rotinas de limpeza.

## Requisitos

- Windows PowerShell 5.1 ou PowerShell 7 com suporte ao módulo RSAT AD.
- Módulo PowerShell do Active Directory.
- Permissão para ler usuários e controladores de domínio.

## Uso

```powershell
.\Get-ADUserLoginReport.ps1 -OutputPath .\AD_User_Login_Report.csv
```

Consultar uma OU específica:

```powershell
.\Get-ADUserLoginReport.ps1 `
  -SearchBase "OU=Users,DC=example,DC=com" `
  -OutputPath .\AD_User_Login_Report.csv
```

Usar `lastLogon` exato consultando todos os controladores de domínio:

```powershell
.\Get-ADUserLoginReport.ps1 -UseExactLastLogon -OutputPath .\AD_User_Login_Report.csv
```

`-UseExactLastLogon` é mais lento, mas é mais preciso do que o
`LastLogonDate` replicado.

