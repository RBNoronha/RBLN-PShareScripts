<#
    .Description
    Essa funcao produz um relatorio do Excel de compartilhamentos para o endpoint em que e executada.  O relatorio tera guias para todos os compartilhamentos.  Cada guia de compartilhamento descreve as permissoes de compartilhamento e NTFS para o compartilhamento.  Abas adicionais sao criadas com grupos do Active Directroy e seus membros para referencia cruzada.

    .Parameter DomainController
    Parametro obrigatorio para informacoes de associacao ao grupo

    .Parameter Path
    Caminho onde o relatorio sera salvo. O caminho padrao do parametro e $env:USERPROFILE\downloads\Share Permissions.xlsx

    .Parameter smbShares
    Para Especificar um ou mais compartilhamentos que devem ser relatados. O parametro padrao esta definido para puxar para todos os compartilhamentos

    .Example
    Get-ShareReport -DomainController DCHostname

    Obtenha um relatorio de compartilhamento para todos os compartilhamentos

    .Example
    Get-ShareReport -DomainController DCHostname -smbShares Sharename

    Obtenha um relatorio de compartilhamento para um unico compartilhamento

    .Link
    https://github.com/RBNoronha/RBLN-PShareScripts
#>

Function Get-ADReportSharefolder {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)]$DomainController,
        [Parameter(Mandatory = $false)]$Path = "$env:USERPROFILE\downloads\Share Permissions.xlsx",
        [Parameter(Mandatory = $false)]$smbShares = (Get-SmbShare)
    )

    begin {


        $DCSession = New-PSSession -ComputerName $domaincontroller
        Invoke-Command -Command { Import-Module ActiveDirectory } -Session $DCSession
        Import-PSSession -Session $DCSession -Module ActiveDirectory -AllowClobber


        Start-Process explorer.exe $env:USERPROFILE\downloads
    }

    process {



        ForEach ($SmbShare in $SmbShares) {
            $smb = $smbshare.name
            Get-SmbShareAccess $Smb |
                Select-Object Name, AccountName, AccessRight, AccessControlType |
                Export-Excel -WorksheetName $Smb -TableName "$Smb SMB Table" -FreezeTopRow -Path $Path -Title "$Smb SMB Access" -TitleSize 12 -TitleBold -AutoSize -WarningAction:SilentlyContinue
        }


        ForEach ($SmbShare in $SmbShares | Where-Object { $_.Path -notlike $null }) {
            $smb = $smbshare.name
            (Get-Acl -Path $SmbShare.Path).access | Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags |
                Export-Excel -WorksheetName $Smb -TableName "$Smb NTFS Table" -FreezeTopRow -Path $Path -Title "$Smb NTFS Access" -TitleSize 12 -TitleBold -AutoSize -StartColumn 6 -WarningAction:SilentlyContinue
        }


        $ADGroup = Get-ADGroup -Filter * | Sort-Object Name
        $ADDomain = (Get-ADDomain).name
        ForEach ($Group in $ADGroup) {
            $notnull = Get-ADGroupMember -Identity $Group.Name -ErrorAction silentlycontinue
            if ($null -ne $notnull) {
                $Groupname = $Group.Name
                Get-ADGroupMember -Identity $Group.Name -ErrorAction silentlycontinue |
                    Select-Object objectClass, name, SamAccountName, @{name = "AccountStatus"; Expression = ( { $status = Get-ADUser $_.SamAccountName | Select-Object Enabled; $status.Enabled }) }, distinguishedName, objectGUID |
                    Export-Excel -FreezeTopRow -WorksheetName "$ADDomain|$Groupname" -Path $Path -TableName "$ADDomain|$Groupname" -Title "$ADDomain|$Groupname" -TitleSize 12 -TitleBold -AutoSize -WarningAction:SilentlyContinue
            }
        }

        $ErrorActionPreference = 'silentlycontinue'
        $Localgroup = Get-LocalGroup | Sort-Object Name
        ForEach ($Group in $LocalGroup) {
            $notnull = Get-LocalGroupMember -Name $Group.Name
            if ($null -ne $notnull) {
                $Groupname = $Group.Name
                Get-LocalGroupMember -Name $Group.Name |
                    Select-Object Name, ObjectClass, PrincipalSource |
                    Export-Excel -FreezeTopRow -WorksheetName "Builtin|$Groupname" -Path $Path -TableName "Builtin|$Groupname" -Title "Builtin|$Groupname" -TitleSize 12 -TitleBold -AutoSize -WarningAction:SilentlyContinue
            }
        }
        $ErrorActionPreference = 'continue'
    }

    end {
    }
}