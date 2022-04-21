# RBLN-PShareScripts Overview

## Active Directory

### Copy-ADGroupUserMember

Copie a associacao de um determinado grupo para outro grupo no Active Directory

Copie a associacao de um determinado grupo para outro grupo no Active Directory. Por padrao, apenas os membros do grupo de origem serao copiados para o
   grupo de destino. Se o parametro `Complete` for usado, os membros do Target Group que nao sao membros do Source Group serao removidos.  Se o parametro `SINC`
    for usado, a associacao sera sincronizada entre os dois grupos.  Se um usuario for apenas membro do grupo-alvo, essa associacao tambem sera copiada
    para a origem.

```powershell
EXAMPLE:
PS C:\> Copy-ADGroupUserMember -GroupSource GroupUsersRedeLab -GroupTarget OrchestratorGroup
```
Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup'

```powershell
EXAMPLE:
PS C:\> Copy-ADGroupUserMember -GroupSource 'GroupUsersRedeLab' -GroupTarget 'OrchestratorGroup' -sinc
```
Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup' e vice-versa.
Todas as associacoes do 'OrchestratorGroup' que NAO existem em 'GroupUsersRedeLab' tambem serao criadas em 'GroupUsersRedeLab'.

```powershell
EXAMPLE:
PS C:\> Copy-ADGroupUserMember -GroupSource 'GroupUsersRedeLab' -GroupTarget 'OrchestratorGroup' -Complete
```

Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup'.
Todas as associacoes do 'OrchestratorGroup' que NAO existem em 'GroupUsersRedeLab' serao removidas.



### ConvertTo-TitleCase

Converter texto com a primeira letra da palavra sempre maiuscula

```powershell
PS C:\> ConvertTo-TitleCase -Text "CONVERTER TEXTO"

PS C:\> Converter Texto
```

### ConvertTo-UpperCase

Converter texto para tudo maisculo

```powershell
PS C:\> ConvertTo-UpperCase -Text "sempre maiscula"

PS C:\> SEMPRE MAISCULA
```



### Get-ADCompareGroupUser

Comparar Grupos de segurança de usuarios

```powershell
Get-ADCompareGroupUser -Identity1 aline.ribeiro -Identity2 adm.noronha

PS C:\>  --------------------------------------------------------------------------
[Aline Ribeiro - Aline.ribeiro] e [Renan Noronha - adm.noronha] tem os seguintes grupos em comum:--------------------------------------------------------------------------
Domain Users
GroupUsersRedeLab
Import
OrchestratorGroup
Sqladmin
--------------------------------------------------------------------------
Os grupos a seguir sao exclusivos para [Aline Ribeiro - Aline.ribeiro]:
--------------------------------------------------------------------------
Sqladmin
--------------------------------------------------------------------------
Os grupos a seguir sao exclusivos para [Renan Noronha - adm.noronha]:
--------------------------------------------------------------------------
Administrators
Domain Admins
Enterprise Admins
Remote Desktop Users
Remote Management Users
Schema Admins
```

### Get-ADCompareGroupUser

requer -versao 5.1
requer -module GroupPolicy,ActiveDirectory

Este comando exibira os links para objetos de Diretiva de Grupo existentes.
Voce pode filtrar links ativados ou desativados.
O dominio de usuario padrao e consultado, embora voce possa especificar um dominio alternativo e/ou um controlador de dominio especifico.
Nao ha provisao para credenciais alternativas.

O comando grava um objeto personalizado no pipeline. Existem visualizacoes de tabela personalizadas associadas que voce pode usar.

``Listando todos os links:``

```powershell
PS C:\> Get-ADGPOLink

GpoId       : 31b2f340-016d-11d2-945f-00c04fb984f9
DisplayName : Default Domain Policy
Enabled     : True
Enforced    : False
Target      : dc=rbcorporate,dc=tech
Order       : 1

GpoId       : 2928242c-d2b4-4cab-ba81-b0709b8e571f
DisplayName : SQL Ports For MECM
Enabled     : True
Enforced    : True
Target      : dc=rbcorporate,dc=tech
Order       : 2

GpoId       : 50be87c0-2508-4649-bd48-e398f9dc8434
DisplayName : PowershellPollicy
Enabled     : True
Enforced    : False
Target      : dc=rbcorporate,dc=tech
Order       : 3

GpoId       : d533032b-b31d-4e09-8c47-d57e4945ae80
DisplayName : MECM Client Push Policy
Enabled     : False
Enforced    : False
Target      : dc=rbcorporate,dc=tech
Order       : 4

GpoId       : 6ac1786c-016f-11d2-945f-00c04fb984f9
DisplayName : Default Domain Controllers Policy
Enabled     : True
Enforced    : False
Target      : ou=domain controllers,dc=rbcorporate,dc=tech
Order       : 1
```

``Listando todos os links desabilitados:``

```powershell
PS C:\> Get-ADGPOLink -Disabled

GpoId       : d533032b-b31d-4e09-8c47-d57e4945ae80
DisplayName : MECM Client Push Policy
Enabled     : False
Enforced    : False
Target      : dc=rbcorporate,dc=tech
Order       : 4
```

``Listando todos os links habilitados:``

```powershell
PS C:\> Get-ADGPOLink -Enabled

GpoId       : 31b2f340-016d-11d2-945f-00c04fb984f9
DisplayName : Default Domain Policy
Enabled     : True
Enforced    : False
Target      : dc=rbcorporate,dc=tech
Order       : 1

GpoId       : 2928242c-d2b4-4cab-ba81-b0709b8e571f
DisplayName : SQL Ports For MECM
Enabled     : True
Enforced    : True
Target      : dc=rbcorporate,dc=tech
Order       : 2

GpoId       : 50be87c0-2508-4649-bd48-e398f9dc8434
DisplayName : PowershellPollicy
Enabled     : True
Enforced    : False
Target      : dc=rbcorporate,dc=tech
Order       : 3

GpoId       : 6ac1786c-016f-11d2-945f-00c04fb984f9
DisplayName : Default Domain Controllers Policy
Enabled     : True
Enforced    : False
Target      : ou=domain controllers,dc=rbcorporate,dc=tech
Order       : 1
```

``Listando todos os links habilitados e desabilitados em formato de tabela:``

```powershell
PS C:\> Get-ADGPOLink | sort Target | Format-Table -AutoSize -Wrap

DisplayName                       GpoId                                Enabled Enforced Order Target                                       GpoDomainName
-----------                       -----                                ------- -------- ----- ------                                       -------------
PowershellPollicy                 50be87c0-2508-4649-bd48-e398f9dc8434    True    False     3 dc=rbcorporate,dc=tech                       rbcorporate.tech
MECM Client Push Policy           d533032b-b31d-4e09-8c47-d57e4945ae80   False    False     4 dc=rbcorporate,dc=tech                       rbcorporate.tech
Default Domain Policy             31b2f340-016d-11d2-945f-00c04fb984f9    True    False     1 dc=rbcorporate,dc=tech                       rbcorporate.tech
SQL Ports For MECM                2928242c-d2b4-4cab-ba81-b0709b8e571f    True     True     2 dc=rbcorporate,dc=tech                       rbcorporate.tech
Default Domain Controllers Policy 6ac1786c-016f-11d2-945f-00c04fb984f9    True    False     1 ou=domain controllers,dc=rbcorporate,dc=tech rbcorporate.tech
