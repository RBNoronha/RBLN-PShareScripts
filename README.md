# Sobre RBLN-PShareScripts*

## Active Directory

### Copy-ADGroupUserMember

Copie a associacao de um determinado grupo para outro grupo no Active Directory

Copie a associacao de um determinado grupo para outro grupo no Active Directory. Por padrao, apenas os membros do grupo de origem serao copiados para o
   grupo de destino. Se o parametro Complete for usado, os membros do Target Group que nao sao membros do Source Group serao removidos.  Se o parametro SINC
    for usado, a associacao sera sincronizada entre os dois grupos.  Se um usuario for apenas membro do grupo-alvo, essa associacao tambem sera copiada
    para a origem.
    
    EXAMPLE
         Copy-ADGroupUserMember -GroupSource GroupUsersRedeLab -GroupTarget OrchestratorGroup

         Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup'
         
    EXAMPLE
         Copy-ADGroupUserMember -GroupSource 'GroupUsersRedeLab' -GroupTarget 'OrchestratorGroup' -sinc

         Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup' e vice-versa.
         Todas as associacoes do 'OrchestratorGroup' que NAO existem em 'GroupUsersRedeLab' tambem serao criadas em 'GroupUsersRedeLab'.

    EXAMPLE
         Copy-ADGroupUserMember -GroupSource 'GroupUsersRedeLab' -GroupTarget 'OrchestratorGroup' -Complete

         Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup'.
         Todas as associacoes do 'OrchestratorGroup' que NAO existem em 'GroupUsersRedeLab' serao removidas.


### ConvertTo-TitleCase

Converter texto com a primeira letra da palavra sempre maiuscula


         EXAMPLE
         PS C:\> ConvertTo-TitleCase -Text "CONVERTER TEXTO"
   
         PS C:\> Converter Texto


### ConvertTo-UpperCase

Converter texto para tudo maisculo

         EXAMPLE
         PS C:\> ConvertTo-UpperCase -Text "sempre maiscula"
   
         PS C:\> SEMPRE MAISCULA



### Get-ADCompareGroupUser

Comparar Grupos de segurança de usuarios 

     EXAMPLE
         Get-ADCompareGroupUser -Identity1 aline.ribeiro -Identity2 adm.noronha
         
     PS C:\>  --------------------------------------------------------------------------
     [Aline Ribeiro - Aline.ribeiro] e [Renan Noronha - adm.noronha] tem os seguintes grupos em comum:
     --------------------------------------------------------------------------
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


