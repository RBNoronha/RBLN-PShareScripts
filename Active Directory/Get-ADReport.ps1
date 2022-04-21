Function Get-ADReport {
    <#
.SYNOPSIS
    Gere relatorios graficos para todos os objetos do Active Directory.

.DESCRIPTION
    Gere o relatorio grafico para todos os objetos do Active Directory.

.PARAMETER CompanyLogo
    Especifique o caminho URL ou UNC para o seu logotipo da empresa desejado para relatório gerado.

    -CompanyLogo "\\Server01\Admin\Files\CompanyLogo.png"

.PARAMETER RightLogo
    Especifique o caminho URL ou UNC para o logotipo do lado direito desejado para relatório gerado.

    -RightLogo "https://www.psmpartners.com/wp-content/uploads/2017/10/porcaro-stolarek-mete.png"

.PARAMETER ReportTitle
    Insira o titulo desejado para o relatorio gerado.

    -ReportTitle "Relatorio Active Directory | RB Solution"

.PARAMETER Days
    Usuarios que nao fizeram login em [X] dias ou mais.

    -Days "30"

.PARAMETER UserCreatedDays
    Usuarios que foram criados dentro de [X] dias

    -UserCreatedDays "7"

.PARAMETER DaysUntilPWExpireINT
    A senha do usuario expira dentro de [X] dias

    -DaysUntilPWExpireINT "7"

.PARAMETER ADModNumber
    Objetos do Active Directory que foram modificados dentro de [x] quantidade de dias.

    -ADModNumber "3"
#>

    param (


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Digite o URL ou o caminho UNC para o logotipo da empresa")]
        [String]$CompanyLogo = "",


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Insira a URL ou o caminho UNC para o logotipo lateral")]
        [String]$RightLogo = "https://www.psmpartners.com/wp-content/uploads/2017/10/porcaro-stolarek-mete.png",


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Insira o titulo desejado para o relatorio")]
        [String]$ReportTitle = "Relatorio Active Directory | RB Solution ",


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Digite o caminho do diretorio desejado para salvar o relatorio;  Padrao: C:\temp\")]
        [String]$ReportSavePath = "C:\Automation\",


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Usuarios que nao fizeram logon em mais de [X] dias.  quantidade de dias;  Padrao: 30")]
        $Days = 30,


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Usuarios que foram criados dentro de [X] dias;  Padrao: 7")]
        $UserCreatedDays = 7,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "A senha do usuario expira dentro de [X] dias;  Padrao: 7")]
        $DaysUntilPWExpireINT = 7,


        [Parameter(ValueFromPipeline = $true, HelpMessage = "Objetos do AD que foram modificados dentro de [X] dias;  Padrao: 3")]
        $ADModNumber = 3


    )

    Write-Host "Configurando a personalizacao do relatorio..." -ForegroundColor White
    Write-Host "__________________________________" -ForegroundColor White
(Write-Host -NoNewline "Logo da empresa (esquerda): " -ForegroundColor Yellow), (Write-Host  $CompanyLogo -ForegroundColor White)
(Write-Host -NoNewline "Logo da empresa (Direita): " -ForegroundColor Yellow), (Write-Host  $RightLogo -ForegroundColor White)
(Write-Host -NoNewline "Titulo do relatorio " -ForegroundColor Yellow), (Write-Host  $ReportTitle -ForegroundColor White)
(Write-Host -NoNewline "Caminho para salvar relatorio: " -ForegroundColor Yellow), (Write-Host  $ReportSavePath -ForegroundColor White)
(Write-Host -NoNewline "Quantidade de dias do ultimo relatorio de logon do usuario: " -ForegroundColor Yellow), (Write-Host  $Days -ForegroundColor White)
(Write-Host -NoNewline "Amount of Days for New User Creation Report: " -ForegroundColor Yellow), (Write-Host  $UserCreatedDays -ForegroundColor White)
(Write-Host -NoNewline "Quantidade de dias para o relatorio de criacao de novos usuarios: " -ForegroundColor Yellow), (Write-Host  $DaysUntilPWExpireINT -ForegroundColor White)
(Write-Host -NoNewline "Quantidade de dias para o relatorio de objetos do AD recem-modificados: " -ForegroundColor Yellow), (Write-Host  $ADModNumber -ForegroundColor White)
    Write-Host "__________________________________" -ForegroundColor White

    function LastLogonConvert ($ftDate) {

        $Date = [DateTime]::FromFileTime($ftDate)

        if ($Date -lt (Get-Date '1/1/1900') -or $date -eq 0 -or $null -eq $date) {

            "Never"
        }

        else {

            $Date
        }

    }


    $Mod = Get-Module -ListAvailable -Name "ReportHTML"

    If ($null -eq $Mod) {

        Write-Host "O modulo ReportHTML nao esta presente, tentando instala-lo"

        Install-Module -Name ReportHTML -Force
        Import-Module ReportHTML -ErrorAction SilentlyContinue
    }


    $DefaultSGs = @(

        "Access Control Assistance Operators"
        "Account Operators"
        "Administrators"
        "Allowed RODC Password Replication Group"
        "Backup Operators"
        "Certificate Service DCOM Access"
        "Cert Publishers"
        "Cloneable Domain Controllers"
        "Cryptographic Operators"
        "Denied RODC Password Replication Group"
        "Distributed COM Users"
        "DnsUpdateProxy"
        "DnsAdmins"
        "Domain Admins"
        "Domain Computers"
        "Domain Controllers"
        "Domain Guests"
        "Domain Users"
        "Enterprise Admins"
        "Enterprise Key Admins"
        "Enterprise Read-only Domain Controllers"
        "Event Log Readers"
        "Group Policy Creator Owners"
        "Guests"
        "Hyper-V Administrators"
        "IIS_IUSRS"
        "Incoming Forest Trust Builders"
        "Key Admins"
        "Network Configuration Operators"
        "Performance Log Users"
        "Performance Monitor Users"
        "Print Operators"
        "Pre-Windows 2000 Compatible Access"
        "Protected Users"
        "RAS and IAS Servers"
        "RDS Endpoint Servers"
        "RDS Management Servers"
        "RDS Remote Access Servers"
        "Read-only Domain Controllers"
        "Remote Desktop Users"
        "Remote Management Users"
        "Replicator"
        "Schema Admins"
        "Server Operators"
        "Storage Replica Administrators"
        "System Managed Accounts Group"
        "Terminal Server License Servers"
        "Users"
        "Windows Authorization Access Group"
        "WinRMRemoteWMIUsers"
    )

    $Table = New-Object 'System.Collections.Generic.List[System.Object]'
    $OUTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $UserTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $GroupTypetable = New-Object 'System.Collections.Generic.List[System.Object]'
    $DefaultGrouptable = New-Object 'System.Collections.Generic.List[System.Object]'
    $EnabledDisabledUsersTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $DomainAdminTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $ExpiringAccountsTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $CompanyInfoTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $securityeventtable = New-Object 'System.Collections.Generic.List[System.Object]'
    $DomainTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $OUGPOTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $GroupMembershipTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $PasswordExpirationTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $PasswordExpireSoonTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $userphaventloggedonrecentlytable = New-Object 'System.Collections.Generic.List[System.Object]'
    $EnterpriseAdminTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $NewCreatedUsersTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $GroupProtectionTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $OUProtectionTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $GPOTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $ADObjectTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $ProtectedUsersTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $ComputersTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $ComputerProtectedTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $ComputersEnabledTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $DefaultComputersinDefaultOUTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $DefaultUsersinDefaultOUTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $TOPUserTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $TOPGroupsTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $TOPComputersTable = New-Object 'System.Collections.Generic.List[System.Object]'
    $GraphComputerOS = New-Object 'System.Collections.Generic.List[System.Object]'


    $AllUsers = Get-ADUser -Filter * -Properties *

    $GPOs = Get-GPO -All | Select-Object DisplayName, GPOStatus, ModificationTime, @{ Label = "ComputerVersion"; Expression = { $_.computer.dsversion } }, @{ Label = "UserVersion"; Expression = { $_.user.dsversion } }

    <###########################
         Dashboard
############################>

    Write-Host "Construindo o painel de relatorios..." -ForegroundColor Green

    $dte = (Get-Date).AddDays(- $ADModNumber)

    $ADObjs = Get-ADObject -Filter { whenchanged -gt $dte -and ObjectClass -ne "domainDNS" -and ObjectClass -ne "rIDManager" -and ObjectClass -ne "rIDSet" } -Properties *

    foreach ($ADObj in $ADObjs) {

        if ($ADObj.ObjectClass -eq "GroupPolicyContainer") {

            $Name = $ADObj.DisplayName
        }

        else {

            $Name = $ADObj.Name
        }

        $obj = [PSCustomObject]@{

            'Nome'            = $Name
            'Tipo de Objeto'  = $ADObj.ObjectClass
            'Quando alterado' = $ADObj.WhenChanged
        }

        $ADObjectTable.Add($obj)
    }
    if (($ADObjectTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'informacao: Nenhum objeto AD foi modificado recentemente'
        }

        $ADObjectTable.Add($obj)
    }


    $ADRecycleBinStatus = (Get-ADOptionalFeature -Filter 'name -like "Recycle Bin Feature"').EnabledScopes

    if ($ADRecycleBinStatus.Count -lt 1) {

        $ADRecycleBin = "Disabled"
    }

    else {

        $ADRecycleBin = "Enabled"
    }

    #Company Information
    $ADInfo = Get-ADDomain
    $ForestObj = Get-ADForest
    $DomainControllerobj = Get-ADDomain
    $Forest = $ADInfo.Forest
    $InfrastructureMaster = $DomainControllerobj.InfrastructureMaster
    $RIDMaster = $DomainControllerobj.RIDMaster
    $PDCEmulator = $DomainControllerobj.PDCEmulator
    $DomainNamingMaster = $ForestObj.DomainNamingMaster
    $SchemaMaster = $ForestObj.SchemaMaster

    $obj = [PSCustomObject]@{

        'Domain'                = $Forest
        'AD Recycle Bin'        = $ADRecycleBin
        'Infrastructure Master' = $InfrastructureMaster
        'RID Master'            = $RIDMaster
        'PDC Emulator'          = $PDCEmulator
        'Domain Naming Master'  = $DomainNamingMaster
        'Schema Master'         = $SchemaMaster
    }

    $CompanyInfoTable.Add($obj)

    if (($CompanyInfoTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nao foi possivel obter itens para a tabela'
        }
        $CompanyInfoTable.Add($obj)
    }

    #Get newly created users
    $When = ((Get-Date).AddDays(- $UserCreatedDays)).Date
    $NewUsers = $AllUsers | Where-Object { $_.whenCreated -ge $When }

    foreach ($Newuser in $Newusers) {

        $obj = [PSCustomObject]@{

            'Nome'            = $Newuser.Name
            'Habilitado'      = $Newuser.Enabled
            'Data de criacao' = $Newuser.whenCreated
        }

        $NewCreatedUsersTable.Add($obj)
    }
    if (($NewCreatedUsersTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Em informacao: Nenhum novo usuario foi criado recentemente'
        }
        $NewCreatedUsersTable.Add($obj)
    }



    #Get Domain Admins
    $DomainAdminMembers = Get-ADGroupMember "Domain Admins"

    foreach ($DomainAdminMember in $DomainAdminMembers) {

        $Name = $DomainAdminMember.Name
        $Type = $DomainAdminMember.ObjectClass
        $Enabled = ($AllUsers | Where-Object { $_.Name -eq $Name }).Enabled

        $obj = [PSCustomObject]@{

            'Nome'       = $Name
            'Habilitado' = $Enabled
            'Tipo'       = $Type
        }

        $DomainAdminTable.Add($obj)
    }

    if (($DomainAdminTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'informacao: nenhum membro administrador de dominio foi encontrado'
        }
        $DomainAdminTable.Add($obj)
    }


    #Get Enterprise Admins
    $EnterpriseAdminsMembers = Get-ADGroupMember "Enterprise Admins" -Server $SchemaMaster

    foreach ($EnterpriseAdminsMember in $EnterpriseAdminsMembers) {

        $Name = $EnterpriseAdminsMember.Name
        $Type = $EnterpriseAdminsMember.ObjectClass
        $Enabled = ($AllUsers | Where-Object { $_.Name -eq $Name }).Enabled

        $obj = [PSCustomObject]@{

            'Nome'       = $Name
            'Habilitado' = $Enabled
            'Tipo'       = $Type
        }

        $EnterpriseAdminTable.Add($obj)
    }

    if (($EnterpriseAdminTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'informacao: Os membros do Enterprise Admin foram encontrados'
        }
        $EnterpriseAdminTable.Add($obj)
    }

    $DefaultComputersOU = (Get-ADDomain).computerscontainer
    $DefaultComputers = Get-ADComputer -Filter * -Properties * -SearchBase "$DefaultComputersOU"

    foreach ($DefaultComputer in $DefaultComputers) {

        $obj = [PSCustomObject]@{

            'Nome'                      = $DefaultComputer.Name
            'Habilitado'                = $DefaultComputer.Enabled
            'Sistema operacional'       = $DefaultComputer.OperatingSystem
            'Data de modificacao'       = $DefaultComputer.Modified
            'Ultima senha definida'     = $DefaultComputer.PasswordLastSet
            'Protegido contra exclusao' = $DefaultComputer.ProtectedFromAccidentalDeletion
        }

        $DefaultComputersinDefaultOUTable.Add($obj)
    }

    if (($DefaultComputersinDefaultOUTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum computador foi encontrado na OU padrao'
        }
        $DefaultComputersinDefaultOUTable.Add($obj)
    }

    $DefaultUsersOU = (Get-ADDomain).UsersContainer
    $DefaultUsers = $Allusers | Where-Object { $_.DistinguishedName -like "*$($DefaultUsersOU)" } | Select-Object Name, UserPrincipalName, Enabled, ProtectedFromAccidentalDeletion, EmailAddress, @{ Name = 'lastlogon'; Expression = { LastLogonConvert $_.lastlogon } }, DistinguishedName

    foreach ($DefaultUser in $DefaultUsers) {

        $obj = [PSCustomObject]@{

            'Nome'                      = $DefaultUser.Name
            'UserPrincipalName'         = $DefaultUser.UserPrincipalName
            'Habilitado'                = $DefaultUser.Enabled
            'Protegido contra exclusao' = $DefaultUser.ProtectedFromAccidentalDeletion
            'Ultimo Logon'              = $DefaultUser.LastLogon
            'Endereco de e-mail'        = $DefaultUser.EmailAddress
        }

        $DefaultUsersinDefaultOUTable.Add($obj)
    }
    if (($DefaultUsersinDefaultOUTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum usuario foi encontrado na OU padrao'
        }
        $DefaultUsersinDefaultOUTable.Add($obj)
    }


    #Expiring Accounts
    $LooseUsers = Search-ADAccount -AccountExpiring -UsersOnly

    foreach ($LooseUser in $LooseUsers) {

        $NameLoose = $LooseUser.Name
        $UPNLoose = $LooseUser.UserPrincipalName
        $ExpirationDate = $LooseUser.AccountExpirationDate
        $enabled = $LooseUser.Enabled

        $obj = [PSCustomObject]@{

            'Nome'              = $NameLoose
            'UserPrincipalName' = $UPNLoose
            'Data de expiracao' = $ExpirationDate
            'Habilitado'        = $enabled
        }

        $ExpiringAccountsTable.Add($obj)
    }

    if (($ExpiringAccountsTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum usuario foi encontrado para expirar em breve'
        }
        $ExpiringAccountsTable.Add($obj)
    }


    $SecurityLogs = Get-EventLog -Newest 7 -LogName "Security" | Where-Object { $_.Message -like "*An account*" }

    foreach ($SecurityLog in $SecurityLogs) {

        $TimeGenerated = $SecurityLog.TimeGenerated
        $EntryType = $SecurityLog.EntryType
        $Recipient = $SecurityLog.Message

        $obj = [PSCustomObject]@{

            'Tempo'    = $TimeGenerated
            'Tipo'     = $EntryType
            'Mensagem' = $Recipient
        }

        $SecurityEventTable.Add($obj)
    }

    if (($SecurityEventTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum sufixo UPN foi encontrado'
        }
        $SecurityEventTable.Add($obj)
    }

    #Tenant Domain
    $Domains = Get-ADForest | Select-Object -ExpandProperty upnsuffixes | ForEach-Object {

        $obj = [PSCustomObject]@{

            'Sufixos UPN' = $_
            Valid         = "True"
        }

        $DomainTable.Add($obj)
    }
    if (($DomainTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum sufixo UPN foi encontrado'
        }
        $DomainTable.Add($obj)
    }

    Write-Host "Finalizado!" -ForegroundColor White

    <###########################

		   Groups

############################>

    Write-Host "Contruindo o grupos..." -ForegroundColor Green

    #Get groups and sort in alphabetical order
    $Groups = Get-ADGroup -Filter * -Properties *
    $SecurityCount = 0
    $MailSecurityCount = 0
    $CustomGroup = 0
    $DefaultGroup = 0
    $Groupswithmemebrship = 0
    $Groupswithnomembership = 0
    $GroupsProtected = 0
    $GroupsNotProtected = 0

    foreach ($Group in $Groups) {

        $DefaultADGroup = 'False'
        $Type = New-Object 'System.Collections.Generic.List[System.Object]'
        $Gemail = (Get-ADGroup $Group -Properties mail).mail

        if (($group.GroupCategory -eq "Security") -and ($Gemail -ne $Null)) {

            $MailSecurityCount++
        }

        if (($group.GroupCategory -eq "Security") -and (($Gemail) -eq $Null)) {

            $SecurityCount++
        }

        if ($Group.ProtectedFromAccidentalDeletion -eq $True) {

            $GroupsProtected++
        }

        else {

            $GroupsNotProtected++
        }

        if ($DefaultSGs -contains $Group.Name) {

            $DefaultADGroup = "True"
            $DefaultGroup++
        }

        else {

            $CustomGroup++
        }

        if ($group.GroupCategory -eq "Distribution") {

            $Type = "Distribution Group"
        }

        if (($group.GroupCategory -eq "Security") -and (($Gemail) -eq $Null)) {

            $Type = "Security Group"
        }

        if (($group.GroupCategory -eq "Security") -and (($Gemail) -ne $Null)) {

            $Type = "Mail-Enabled Security Group"
        }

        if ($Group.Name -ne "Domain Users") {

            $Users = (Get-ADGroupMember -Identity $Group | Sort-Object DisplayName | Select-Object -ExpandProperty Name) -join ", "

            if (!($Users)) {

                $Groupswithnomembership++
            }

            else {

                $Groupswithmemebrship++

            }
        }

        else {

            $Users = "Associacao de usuarios de dominio ignorados"
        }

        $OwnerDN = Get-ADGroup -Filter { name -eq $Group.Name } -Properties managedBy | Select-Object -ExpandProperty ManagedBy
        Try {
            $Manager = Get-ADUser -Filter { distinguishedname -like $OwnerDN } | Select-Object -ExpandProperty Name
        } Catch {
            Write-Host -ForegroundColor Yellow "Nao e possivel resolver o gerenciador, " $Manager " no grupo " $group.name
        }


        $obj = [PSCustomObject]@{

            'Nome'                  = $Group.name
            'Tipo'                  = $Type
            'Membros'               = $users
            'Gerenciado por'        = $Manager
            'Endereco de e-mail'    = $GEmail
            'Protegido da exclusao' = $Group.ProtectedFromAccidentalDeletion
            'Grupo AD Padrao'       = $DefaultADGroup
        }

        $table.Add($obj)
    }

    if (($table).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum grupo foi encontrado'
        }
        $table.Add($obj)
    }
    #TOP groups table
    $obj1 = [PSCustomObject]@{

        'Total de grupos'                      = $Groups.Count
        'Grupos de seg habilitados para email' = $MailSecurityCount
        'Grupos de seguranca'                  = $SecurityCount
        'Grupos de distribuicao'               = $DistroCount
    }

    $TOPGroupsTable.Add($obj1)

    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Grupos de seg habilitados para email'
        'Contagem' = $MailSecurityCount
    }

    $GroupTypetable.Add($obj1)

    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Grupos de seguranca'
        'Contagem' = $SecurityCount
    }

    $GroupTypetable.Add($obj1)
    $DistroCount = ($Groups | Where-Object { $_.GroupCategory -eq "Distribution" }).Count

    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Grupos de distribuicao'
        'Contagem' = $DistroCount
    }

    $GroupTypetable.Add($obj1)

    #Default Group Pie Chart
    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Grupo padrao'
        'Contagem' = $DefaultGroup
    }

    $DefaultGrouptable.Add($obj1)

    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Grupos personalizados'
        'Contagem' = $CustomGroup
    }

    $DefaultGrouptable.Add($obj1)

    #Group Protection Pie Chart
    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Protegido'
        'Contagem' = $GroupsProtected
    }

    $GroupProtectionTable.Add($obj1)

    $obj1 = [PSCustomObject]@{

        'Nome'     = 'Sem protecao'
        'Contagem' = $GroupsNotProtected
    }

    $GroupProtectionTable.Add($obj1)

    #Groups with membership vs no membership pie chart
    $objmem = [PSCustomObject]@{

        'Nome'     = 'Com membros'
        'Contagem' = $Groupswithmemebrship
    }

    $GroupMembershipTable.Add($objmem)

    $objmem = [PSCustomObject]@{

        'Nome'     = 'Sem Membros'
        'Contagem' = $Groupswithnomembership
    }

    $GroupMembershipTable.Add($objmem)

    Write-Host "Finalizado!" -ForegroundColor White

    <###########################

    Organizational Units

############################>

    Write-Host "Contruindo o Relatorio de Unidades Organizacionais..." -ForegroundColor Green

    #Get all OUs'
    $OUs = Get-ADOrganizationalUnit -Filter * -Properties *
    $OUwithLinked = 0
    $OUwithnoLink = 0
    $OUProtected = 0
    $OUNotProtected = 0

    foreach ($OU in $OUs) {

        $LinkedGPOs = New-Object 'System.Collections.Generic.List[System.Object]'

        if (($OU.linkedgrouppolicyobjects).length -lt 1) {

            $LinkedGPOs = "None"
            $OUwithnoLink++
        }

        else {

            $OUwithLinked++
            $GPOslinks = $OU.linkedgrouppolicyobjects

            foreach ($GPOlink in $GPOslinks) {

                $Split1 = $GPOlink -split "{" | Select-Object -Last 1
                $Split2 = $Split1 -split "}" | Select-Object -First 1
                $LinkedGPOs.Add((Get-GPO -Guid $Split2 -ErrorAction SilentlyContinue).DisplayName)
            }
        }

        if ($OU.ProtectedFromAccidentalDeletion -eq $True) {

            $OUProtected++
        }

        else {

            $OUNotProtected++
        }

        $LinkedGPOs = $LinkedGPOs -join ", "
        $obj = [PSCustomObject]@{

            'Nome'                      = $OU.Name
            'Links de GPOs'             = $LinkedGPOs
            'Data de modificacao'       = $OU.WhenChanged
            'Protegido contra exclusao' = $OU.ProtectedFromAccidentalDeletion
        }

        $OUTable.Add($obj)
    }

    if (($OUTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhuma OU foi encontrada'
        }
        $OUTable.Add($obj)
    }

    #OUs with no GPO Linked
    $obj1 = [PSCustomObject]@{

        'Nome'     = "OUs sem Links de GPOs"
        'Contagem' = $OUwithnoLink
    }

    $OUGPOTable.Add($obj1)

    $obj2 = [PSCustomObject]@{

        'Nome'     = "OUs com Links GPOs"
        'Contagem' = $OUwithLinked
    }

    $OUGPOTable.Add($obj2)

    #OUs Protected Pie Chart
    $obj1 = [PSCustomObject]@{

        'Nome'     = "Protegido"
        'Contagem' = $OUProtected
    }

    $OUProtectionTable.Add($obj1)

    $obj2 = [PSCustomObject]@{

        'Nome'     = "Not Protected"
        'Contagem' = $OUNotProtected
    }

    $OUProtectionTable.Add($obj2)

    Write-Host "Finalizado!" -ForegroundColor White

    <###########################

           USERS

############################>

    Write-Host "Construindo o relatorio de usuarios..." -ForegroundColor Green

    $UserEnabled = 0
    $UserDisabled = 0
    $UserPasswordExpires = 0
    $UserPasswordNeverExpires = 0
    $ProtectedUsers = 0
    $NonProtectedUsers = 0

    $UsersWIthPasswordsExpiringInUnderAWeek = 0
    $UsersNotLoggedInOver30Days = 0
    $AccountsExpiringSoon = 0


    $userphaventloggedonrecentlytable = New-Object 'System.Collections.Generic.List[System.Object]'
    foreach ($User in $AllUsers) {

        $AttVar = $User | Select-Object Enabled, PasswordExpired, PasswordLastSet, PasswordNeverExpires, PasswordNotRequired, Name, SamAccountName, EmailAddress, AccountExpirationDate, @{ Name = 'lastlogon'; Expression = { LastLogonConvert $_.lastlogon } }, DistinguishedName
        $maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days

        if ((($AttVar.PasswordNeverExpires) -eq $False) -and (($AttVar.Enabled) -ne $false)) {


            $passwordSetDate = ($User | ForEach-Object { $_.PasswordLastSet })

            if ($null -eq $passwordSetDate) {

                $daystoexpire = "O usuario nunca fez logon"
            }

            else {

                $PasswordPol = (Get-ADUserResultantPasswordPolicy $user)

                if (($PasswordPol) -ne $null) {

                    $maxPasswordAge = ($PasswordPol).MaxPasswordAge
                }

                $expireson = $passwordsetdate.AddDays($maxPasswordAge)
                $today = (Get-Date)


                $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
            }
        }

        else {

            $daystoexpire = "N/A"
        }

        if (($User.Enabled -eq $True) -and ($AttVar.LastLogon -lt ((Get-Date).AddDays(- $Days))) -and ($User.LastLogon -ne $NULL)) {

            $obj = [PSCustomObject]@{

                'Nome'                          = $User.Name
                'UserPrincipalName'             = $User.UserPrincipalName
                'Habilitado'                    = $AttVar.Enabled
                'Protegido contra exclusao'     = $User.ProtectedFromAccidentalDeletion
                'Ultimo logon'                  = $AttVar.lastlogon
                'A senha nunca expira'          = $AttVar.PasswordNeverExpires
                'Dias ate a expiracao da senha' = $daystoexpire
            }

            $userphaventloggedonrecentlytable.Add($obj)
        }

        if ($User.ProtectedFromAccidentalDeletion -eq $False) {

            $NonProtectedUsers++
        }

        else {

            $ProtectedUsers++
        }

        if (($AttVar.PasswordNeverExpires) -ne $false) {

            $UserPasswordNeverExpires++
        }

        else {

            $UserPasswordExpires++
        }

        #Items for password expiration pie chart
        if (($AttVar.Enabled) -ne $false) {

            $UserEnabled++
        }

        else {

            $UserDisabled++
        }

        $Name = $User.Name
        $UPN = $User.UserPrincipalName
        $Enabled = $AttVar.Enabled
        $EmailAddress = $AttVar.EmailAddress
        $AccountExpiration = $AttVar.AccountExpirationDate
        $PasswordExpired = $AttVar.PasswordExpired
        $PasswordLastSet = $AttVar.PasswordLastSet
        $PasswordNeverExpires = $AttVar.PasswordNeverExpires
        $daysUntilPWExpire = $daystoexpire

        $obj = [PSCustomObject]@{

            'Nome'                           = $Name
            'UserPrincipalName'              = $UPN
            'Habilitado'                     = $Enabled
            'Protegido contra exclusao'      = $User.ProtectedFromAccidentalDeletion
            'Ultimo logon'                   = $LastLogon
            'Endereco de e-mail'             = $EmailAddress
            'Expiracao da conta'             = $AccountExpiration
            'Alterar senha no proximo logon' = $PasswordExpired
            'Ultima senha definida'          = $PasswordLastSet
            'A senha nunca expira'           = $PasswordNeverExpires
            'Dias ate a expiracao da senha'  = $daystoexpire
        }

        $usertable.Add($obj)

        if ($daystoexpire -lt $DaysUntilPWExpireINT) {

            $obj = [PSCustomObject]@{

                'Nome'                          = $Name
                'Dias ate a expiracao da senha' = $daystoexpire
            }

            $PasswordExpireSoonTable.Add($obj)
        }
    }
    if (($userphaventloggedonrecentlytable).Count -eq 0) {
        $userphaventloggedonrecentlytable = [PSCustomObject]@{

            Information = "Informacao: Nao foi encontrado nenhum usuario que nao fez logon em $Days dias ou mais"
        }
    }
    if (($PasswordExpireSoonTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nao foram encontrados usuarios com senhas que expiram em breve'
        }
        $PasswordExpireSoonTable.Add($obj)
    }


    if (($usertable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum usuario foi encontrado'
        }
        $usertable.Add($obj)
    }

    #Data for users enabled vs disabled pie graph
    $objULic = [PSCustomObject]@{

        'Nome'     = 'Habilitado'
        'Contagem' = $UserEnabled
    }

    $EnabledDisabledUsersTable.Add($objULic)

    $objULic = [PSCustomObject]@{

        'Nome'     = 'Desabilitado'
        'Contagem' = $UserDisabled
    }

    $EnabledDisabledUsersTable.Add($objULic)


    $objULic = [PSCustomObject]@{

        'Nome'     = 'A senha expira'
        'Contagem' = $UserPasswordExpires
    }

    $PasswordExpirationTable.Add($objULic)

    $objULic = [PSCustomObject]@{

        'Nome'     = 'A senha nunca expira'
        'Contagem' = $UserPasswordNeverExpires
    }

    $PasswordExpirationTable.Add($objULic)

    #Data for protected users pie graph
    $objULic = [PSCustomObject]@{

        'Nome'     = 'Protegido'
        'Contagem' = $ProtectedUsers
    }

    $ProtectedUsersTable.Add($objULic)

    $objULic = [PSCustomObject]@{

        'Nome'     = 'Sem protecao'
        'Contagem' = $NonProtectedUsers
    }

    $ProtectedUsersTable.Add($objULic)
    if ($null -ne (($userphaventloggedonrecentlytable).Information)) {
        $UHLONXD = "0"

    } Else {
        $UHLONXD = $userphaventloggedonrecentlytable.Count

    }
    #TOP User table
    If ($null -eq (($ExpiringAccountsTable).Information)) {

        $objULic = [PSCustomObject]@{
            'Total de usuarios'                                                    = $AllUsers.Count
            "Usuarios com senhas expirando em menos de $DaysUntilPWExpireINT dias" = $PasswordExpireSoonTable.Count
            'Contas a expirar'                                                     = $ExpiringAccountsTable.Count
            "Os usuarios nao fazem logon ha $Days Dias ou mais"                    = $UHLONXD
        }

        $TOPUserTable.Add($objULic)


    } Else {

        $objULic = [PSCustomObject]@{
            'Total usuarios'                                                         = $AllUsers.Count
            "Usuarios com senhas que expiram em menos de $DaysUntilPWExpireINT dias" = $PasswordExpireSoonTable.Count
            'Contas a expirar'                                                       = "0"
            "Os usuarios nao fazem logon ha $Days Dias ou mais"                      = $UHLONXD
        }
        $TOPUserTable.Add($objULic)
    }

    Write-Host "Finalizado!" -ForegroundColor White
    <###########################

	   Group Policy

############################>
    Write-Host "Construindo o Relatorio de Diretiva de Grupo..." -ForegroundColor Green

    $GPOTable = New-Object 'System.Collections.Generic.List[System.Object]'

    foreach ($GPO in $GPOs) {

        $obj = [PSCustomObject]@{

            'Nome'                 = $GPO.DisplayName
            'Status'               = $GPO.GpoStatus
            'Data de modificacao'  = $GPO.ModificationTime
            'Versao do usuario'    = $GPO.UserVersion
            'Versao do computador' = $GPO.ComputerVersion
        }

        $GPOTable.Add($obj)
    }
    if (($GPOTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum objeto de politica de grupo foi encontrado'
        }
        $GPOTable.Add($obj)
    }
    Write-Host "Finalizado!" -ForegroundColor White
    <###########################

	   Computers

############################>
    Write-Host "Contruindo o Relatorio de Computadores..." -ForegroundColor Green

    $Computers = Get-ADComputer -Filter * -Properties *
    $ComputersProtected = 0
    $ComputersNotProtected = 0
    $ComputerEnabled = 0
    $ComputerDisabled = 0
    #Only search for versions of windows that exist in the Environment
    $WindowsRegex = "(Windows (Server )?(\d+|XP)?( R2)?).*"
    $OsVersions = $Computers | Select-Object OperatingSystem -Unique | ForEach-Object {
        if ($_.OperatingSystem -match $WindowsRegex ) {
            return $matches[1]
        } elseif ($_.OperatingSystem -ne $null) {
            return $_.OperatingSystem
        }
    } | Select-Object -Unique | Sort-Object

    $OsObj = [PSCustomObject]@{}

    $OsVersions | ForEach-Object {

        $OsObj | Add-Member -Name $_ -Value 0 -Type NoteProperty

    }

    foreach ($Computer in $Computers) {

        if ($Computer.ProtectedFromAccidentalDeletion -eq $True) {

            $ComputersProtected++
        }

        else {

            $ComputersNotProtected++
        }

        if ($Computer.Enabled -eq $True) {

            $ComputerEnabled++
        }

        else {

            $ComputerDisabled++
        }

        $obj = [PSCustomObject]@{

            'Nome'                     = $Computer.Name
            'Habilitado'               = $Computer.Enabled
            'Sistema operacional'      = $Computer.OperatingSystem
            'Data de modificacao'      = $Computer.Modified
            'Ultima senha definida'    = $Computer.PasswordLastSet
            'Protecao contra exclusao' = $Computer.ProtectedFromAccidentalDeletion
        }

        $ComputersTable.Add($obj)

        if ($Computer.OperatingSystem -match $WindowsRegex) {
            $OsObj."$($matches[1])"++
        }

    }

    if (($ComputersTable).Count -eq 0) {

        $Obj = [PSCustomObject]@{

            Information = 'Informacao: Nenhum computador foi encontrado'
        }
        $ComputersTable.Add($obj)
    }

    #Pie chart breaking down OS for computer obj
    $OsObj.PSObject.Properties | ForEach-Object {
        $GraphComputerOS.Add([PSCustomObject]@{'Name' = $_.Name; "Count" = $_.Value })
    }

    #Data for TOP Computers data table
    $OsObj | Add-Member -Name 'Total Computers' -Value $Computers.Count -Type NoteProperty

    $TOPComputersTable.Add($OsObj)


    #Data for protected Computers pie graph
    $objULic = [PSCustomObject]@{

        'Nome'     = 'Protegido'
        'Contagem' = $ComputerProtected
    }

    $ComputerProtectedTable.Add($objULic)

    $objULic = [PSCustomObject]@{

        'Nome'     = 'Sem protecao'
        'Contagem' = $ComputersNotProtected
    }

    $ComputerProtectedTable.Add($objULic)

    #Data for enabled/vs Computers pie graph
    $objULic = [PSCustomObject]@{

        'Nome'     = 'Habilitado'
        'Contagem' = $ComputerEnabled
    }

    $ComputersEnabledTable.Add($objULic)

    $objULic = [PSCustomObject]@{

        'Nome'     = 'desabilitado'
        'Contagem' = $ComputerDisabled
    }

    $ComputersEnabledTable.Add($objULic)

    Write-Host "Finalizado!" -ForegroundColor White

    $tabarray = @('Dashboard', 'Grupos', 'Unidades organizacionais', 'Usuarios', 'Politica de grupo', 'Computadores')

    Write-Host "Compilando relatorio...." -ForegroundColor Green

    ##--OU Protection PIE CHART--##
    #Basic Properties
    $PO12 = Get-HTMLPieChartObject
    $PO12.Title = "Unidades organizacionais protegidas contra exclusao"
    $PO12.Size.Height = 250
    $PO12.Size.width = 250
    $PO12.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PO12.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PO12.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PO12.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PO12.DataDefinition.DataNameColumnName = 'Nome'
    $PO12.DataDefinition.DataValueColumnName = 'Contagem'

    ##--Computer OS Breakdown PIE CHART--##
    $PieObjectComputerObjOS = Get-HTMLPieChartObject
    $PieObjectComputerObjOS.Title = "Sistemas operacionais dos dispositivos"

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectComputerObjOS.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectComputerObjOS.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectComputerObjOS.ChartStyle.ColorSchemeName = 'Random'

    ##--Computers Protection PIE CHART--##
    #Basic Properties
    $PieObjectComputersProtected = Get-HTMLPieChartObject
    $PieObjectComputersProtected.Title = "Computadores protegidos contra exclusao"
    $PieObjectComputersProtected.Size.Height = 250
    $PieObjectComputersProtected.Size.width = 250
    $PieObjectComputersProtected.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectComputersProtected.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectComputersProtected.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectComputersProtected.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObjectComputersProtected.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectComputersProtected.DataDefinition.DataValueColumnName = 'Contagem'

    ##--Computers Enabled PIE CHART--##
    #Basic Properties
    $PieObjectComputersEnabled = Get-HTMLPieChartObject
    $PieObjectComputersEnabled.Title = "Computadores habilitados vs desabilitados"
    $PieObjectComputersEnabled.Size.Height = 250
    $PieObjectComputersEnabled.Size.width = 250
    $PieObjectComputersEnabled.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectComputersEnabled.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectComputersEnabled.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectComputersEnabled.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObjectComputersEnabled.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectComputersEnabled.DataDefinition.DataValueColumnName = 'Contagem'

    ##--USERS Protection PIE CHART--##
    #Basic Properties
    $PieObjectProtectedUsers = Get-HTMLPieChartObject
    $PieObjectProtectedUsers.Title = "Usuarios protegidos contra exclusao"
    $PieObjectProtectedUsers.Size.Height = 250
    $PieObjectProtectedUsers.Size.width = 250
    $PieObjectProtectedUsers.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectProtectedUsers.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectProtectedUsers.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectProtectedUsers.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObjectProtectedUsers.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectProtectedUsers.DataDefinition.DataValueColumnName = 'Contagem'

    #Basic Properties
    $PieObjectOUGPOLinks = Get-HTMLPieChartObject
    $PieObjectOUGPOLinks.Title = "Links de GPO em OU "
    $PieObjectOUGPOLinks.Size.Height = 250
    $PieObjectOUGPOLinks.Size.width = 250
    $PieObjectOUGPOLinks.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectOUGPOLinks.ChartStyle.ColorSchemeName = "ColorScheme4"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectOUGPOLinks.ChartStyle.ColorSchemeName = "Generated5"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectOUGPOLinks.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObjectOUGPOLinks.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectOUGPOLinks.DataDefinition.DataValueColumnName = 'Contagem'

    #Basic Properties
    $PieObject4 = Get-HTMLPieChartObject
    $PieObject4.Title = "Office 365 Unassigned Licenses"
    $PieObject4.Size.Height = 250
    $PieObject4.Size.width = 250
    $PieObject4.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObject4.ChartStyle.ColorSchemeName = "ColorScheme4"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObject4.ChartStyle.ColorSchemeName = "Generated4"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObject4.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObject4.DataDefinition.DataNameColumnName = 'Nome'
    $PieObject4.DataDefinition.DataValueColumnName = 'Licencas nao atribuidas'

    #Basic Properties
    $PieObjectGroupType = Get-HTMLPieChartObject
    $PieObjectGroupType.Title = "Tipos de grupo"
    $PieObjectGroupType.Size.Height = 250
    $PieObjectGroupType.Size.width = 250
    $PieObjectGroupType.ChartStyle.ChartType = 'doughnut'

    #Pie Chart Groups with members vs no members
    $PieObjectGroupMembersType = Get-HTMLPieChartObject
    $PieObjectGroupMembersType.Title = "Associacao ao grupo"
    $PieObjectGroupMembersType.Size.Height = 250
    $PieObjectGroupMembersType.Size.width = 250
    $PieObjectGroupMembersType.ChartStyle.ChartType = 'doughnut'
    $PieObjectGroupMembersType.ChartStyle.ColorSchemeName = "ColorScheme4"
    $PieObjectGroupMembersType.ChartStyle.ColorSchemeName = "Generated8"
    $PieObjectGroupMembersType.ChartStyle.ColorSchemeName = 'Random'
    $PieObjectGroupMembersType.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectGroupMembersType.DataDefinition.DataValueColumnName = 'Contagem'

    #Basic Properties
    $PieObjectGroupType2 = Get-HTMLPieChartObject
    $PieObjectGroupType2.Title = "Grupos personalizados x padrao"
    $PieObjectGroupType2.Size.Height = 250
    $PieObjectGroupType2.Size.width = 250
    $PieObjectGroupType2.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectGroupType.ChartStyle.ColorSchemeName = "ColorScheme4"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectGroupType.ChartStyle.ColorSchemeName = "Generated8"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectGroupType.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObjectGroupType.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectGroupType.DataDefinition.DataValueColumnName = 'Contagem'

    ##--Enabled users vs Disabled Users PIE CHART--##
    #Basic Properties
    $EnabledDisabledUsersPieObject = Get-HTMLPieChartObject
    $EnabledDisabledUsersPieObject.Title = "Usuarios habilitados vs desabilitados"
    $EnabledDisabledUsersPieObject.Size.Height = 250
    $EnabledDisabledUsersPieObject.Size.width = 250
    $EnabledDisabledUsersPieObject.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $EnabledDisabledUsersPieObject.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $EnabledDisabledUsersPieObject.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $EnabledDisabledUsersPieObject.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $EnabledDisabledUsersPieObject.DataDefinition.DataNameColumnName = 'Nome'
    $EnabledDisabledUsersPieObject.DataDefinition.DataValueColumnName = 'Contagem'

    ##--PasswordNeverExpires PIE CHART--##
    #Basic Properties
    $PWExpiresUsersTable = Get-HTMLPieChartObject
    $PWExpiresUsersTable.Title = "Expiracao da senha"
    $PWExpiresUsersTable.Size.Height = 250
    $PWExpiresUsersTable.Size.Width = 250
    $PWExpiresUsersTable.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PWExpiresUsersTable.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PWExpiresUsersTable.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PWExpiresUsersTable.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PWExpiresUsersTable.DataDefinition.DataNameColumnName = 'Nome'
    $PWExpiresUsersTable.DataDefinition.DataValueColumnName = 'Contagem'

    ##--Group Protection PIE CHART--##
    #Basic Properties
    $PieObjectGroupProtection = Get-HTMLPieChartObject
    $PieObjectGroupProtection.Title = "Grupos protegidos contra exclusao"
    $PieObjectGroupProtection.Size.Height = 250
    $PieObjectGroupProtection.Size.width = 250
    $PieObjectGroupProtection.ChartStyle.ChartType = 'doughnut'

    #These file exist in the module directoy, There are 4 schemes by default
    $PieObjectGroupProtection.ChartStyle.ColorSchemeName = "ColorScheme3"

    #There are 8 generated schemes, randomly generated at runtime
    $PieObjectGroupProtection.ChartStyle.ColorSchemeName = "Generated3"

    #you can also ask for a random scheme.  Which also happens ifyou have too many records for the scheme
    $PieObjectGroupProtection.ChartStyle.ColorSchemeName = 'Random'

    #Data defintion you can reference any column from name and value from the  dataset.
    #Name and Count are the default to work with the Group function.
    $PieObjectGroupProtection.DataDefinition.DataNameColumnName = 'Nome'
    $PieObjectGroupProtection.DataDefinition.DataValueColumnName = 'Contagem'

    #Dashboard Report
    $FinalReport = New-Object 'System.Collections.Generic.List[System.Object]'
    $FinalReport.Add($(Get-HTMLOpenPage -TitleText $ReportTitle -LeftLogoString $CompanyLogo -RightLogoString $RightLogo))
    $FinalReport.Add($(Get-HTMLTabHeader -TabNames $tabarray))
    $FinalReport.Add($(Get-HTMLTabContentopen -TabName $tabarray[0] -TabHeading ("Relatorio: " + (Get-Date -Format dd-MM-yyyy))))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Informacoes da Empresa"))
    $FinalReport.Add($(Get-HTMLContentTable $CompanyInfoTable))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Grupos"))
    $FinalReport.Add($(Get-HTMLColumn1of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText 'Administradores de dominio'))
    $FinalReport.Add($(Get-HTMLContentDataTable $DomainAdminTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText 'Administradores Enterprise'))
    $FinalReport.Add($(Get-HTMLContentDataTable $EnterpriseAdminTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Objetos em UOs padrao"))
    $FinalReport.Add($(Get-HTMLColumn1of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText 'Computadores'))
    $FinalReport.Add($(Get-HTMLContentDataTable $DefaultComputersinDefaultOUTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText 'Usuarios'))
    $FinalReport.Add($(Get-HTMLContentDataTable $DefaultUsersinDefaultOUTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Objetos do AD modificados nos ultimos $ADModNumber dias"))
    $FinalReport.Add($(Get-HTMLContentDataTable $ADObjectTable))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Itens expirando"))
    $FinalReport.Add($(Get-HTMLColumn1of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText "Usuarios com senhas expirando em menos de $DaysUntilPWExpireINT dias"))
    $FinalReport.Add($(Get-HTMLContentDataTable $PasswordExpireSoonTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText 'Contas que expiram em breve'))
    $FinalReport.Add($(Get-HTMLContentDataTable $ExpiringAccountsTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Contas"))
    $FinalReport.Add($(Get-HTMLColumn1of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText "Os usuarios nao fazem logon ha $Days Dias ou mais"))
    $FinalReport.Add($(Get-HTMLContentDataTable $userphaventloggedonrecentlytable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText "Contas criadas em $UserCreatedDays dias ou menos"))
    $FinalReport.Add($(Get-HTMLContentDataTable $NewCreatedUsersTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Logs de seguranca"))
    $FinalReport.Add($(Get-HTMLContentDataTable $securityeventtable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Sufixos UPN"))
    $FinalReport.Add($(Get-HTMLContentTable $DomainTable))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLTabContentClose))

    #Groups Report
    $FinalReport.Add($(Get-HTMLTabContentopen -TabName $tabarray[1] -TabHeading ("Relatorio: " + (Get-Date -Format dd-MM-yyyy))))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Visao geral dos grupos"))
    $FinalReport.Add($(Get-HTMLContentTable $TOPGroupsTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Grupos do Active Directory"))
    $FinalReport.Add($(Get-HTMLContentDataTable $Table -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumn1of2))

    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText 'Administradores de dominio'))
    $FinalReport.Add($(Get-HTMLContentDataTable $DomainAdminTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText 'Administradores Enterprise'))
    $FinalReport.Add($(Get-HTMLContentDataTable $EnterpriseAdminTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Grafico de grupos do Active Directory"))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 4))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectGroupType -DataSet $GroupTypetable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 4))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectGroupType2 -DataSet $DefaultGrouptable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 3 -ColumnCount 4))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectGroupMembersType -DataSet $GroupMembershipTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 4 -ColumnCount 4))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectGroupProtection -DataSet $GroupProtectionTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLTabContentClose))

    #Organizational Unit Report
    $FinalReport.Add($(Get-HTMLTabContentopen -TabName $tabarray[2] -TabHeading ("Report: " + (Get-Date -Format dd-MM-yyyy))))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Unidades organizacionais"))
    $FinalReport.Add($(Get-HTMLContentDataTable $OUTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Organizational Units Charts"))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 2))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectOUGPOLinks -DataSet $OUGPOTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 2))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PO12 -DataSet $OUProtectionTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentclose))
    $FinalReport.Add($(Get-HTMLTabContentClose))

    #Users Report
    $FinalReport.Add($(Get-HTMLTabContentopen -TabName $tabarray[3] -TabHeading ("Relatorio: " + (Get-Date -Format dd-MM-yyyy))))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Visao geral dos usuarios"))
    $FinalReport.Add($(Get-HTMLContentTable $TOPUserTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Usuarios do Active Directory"))
    $FinalReport.Add($(Get-HTMLContentDataTable $UserTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Itens expirando"))
    $FinalReport.Add($(Get-HTMLColumn1of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText "Usuarios com senhas que expiram em menos de $DaysUntilPWExpireINT dias"))
    $FinalReport.Add($(Get-HTMLContentDataTable $PasswordExpireSoonTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText 'Contas que expiram em breves Expiring Soon'))
    $FinalReport.Add($(Get-HTMLContentDataTable $ExpiringAccountsTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Conta"))
    $FinalReport.Add($(Get-HTMLColumn1of2))
    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText "Os usuarios nao fazem logon ha $Days Dias ou mais"))
    $FinalReport.Add($(Get-HTMLContentDataTable $userphaventloggedonrecentlytable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumn2of2))

    $FinalReport.Add($(Get-HTMLContentOpen -BackgroundShade 1 -HeaderText "Contas criadas em $UserCreatedDays dias ou menos"))
    $FinalReport.Add($(Get-HTMLContentDataTable $NewCreatedUsersTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Graficos de usuarios"))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 3))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $EnabledDisabledUsersPieObject -DataSet $EnabledDisabledUsersTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 3))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PWExpiresUsersTable -DataSet $PasswordExpirationTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 3 -ColumnCount 3))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectProtectedUsers -DataSet $ProtectedUsersTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLTabContentClose))

    #GPO Report
    $FinalReport.Add($(Get-HTMLTabContentopen -TabName $tabarray[4] -TabHeading ("Relatorio: " + (Get-Date -Format dd-MM-yyyy))))
    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Politicas de Grupo"))
    $FinalReport.Add($(Get-HTMLContentDataTable $GPOTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))
    $FinalReport.Add($(Get-HTMLTabContentClose))

    #Computers Report
    $FinalReport.Add($(Get-HTMLTabContentopen -TabName $tabarray[5] -TabHeading ("Relatorio: " + (Get-Date -Format dd-MM-yyyy))))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Visao geral dos computadores"))
    $FinalReport.Add($(Get-HTMLContentTable $TOPComputersTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Computadores"))
    $FinalReport.Add($(Get-HTMLContentDataTable $ComputersTable -HideFooter))
    $FinalReport.Add($(Get-HTMLContentClose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Graficos dos Dispositivos"))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 2))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectComputersProtected -DataSet $ComputerProtectedTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 2))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectComputersEnabled -DataSet $ComputersEnabledTable))
    $FinalReport.Add($(Get-HTMLColumnClose))
    $FinalReport.Add($(Get-HTMLContentclose))

    $FinalReport.Add($(Get-HTMLContentOpen -HeaderText "Detalhamento do sistema operacional dos Dispositivos"))
    $FinalReport.Add($(Get-HTMLPieChart -ChartObject $PieObjectComputerObjOS -DataSet $GraphComputerOS))
    $FinalReport.Add($(Get-HTMLContentclose))

    $FinalReport.Add($(Get-HTMLTabContentClose))
    $FinalReport.Add($(Get-HTMLClosePage))

    $Day = (Get-Date).Day
    $Month = (Get-Date).Month
    $Year = (Get-Date).Year
    $ReportName = ("$Day - $Month - $Year - AD Report")

    Save-HTMLReport -ReportContent $FinalReport -ShowReport -ReportName $ReportName -ReportPath $ReportSavePath
}