function Copy-ADGroupUserMember {
    <#
         .SYNOPSIS
         Copie a associacao de um determinado grupo para outro grupo no Active Directory

         .DESCRIPTION

         Copie a associacao de um determinado grupo para outro grupo no Active Directory. Por padrao, apenas os membros do grupo de origem serao copiados para o grupo de destino. Se o parametro FULL for usado, os membros do Target Group que nao sao membros do Source Group serao removidos.  Se o parametro SYNC for usado, a associacao sera sincronizada entre os dois grupos.  Se um usuario for apenas membro do grupo-alvo, essa associacao tambem sera copiada para a origem.

         .PARAMETER GroupSource
         Objeto de grupo de fonte.

         Especifica um objeto Grupo Active Directory, fornecendo um dos seguintes valores.O identificador dentro
         Parênteses é o nome de exibição LDAP para o atributo.

         Nome Distinto (DistinguishedName)

         Exemplo: CN=OrchestratorGroup,CN=Users,DC=rbcorporate,DC=tech

         GUID (ObjectGuid)

         Exemplo: 2907565c-97b4-4335-9d1c-e50ef356278d

         Identificador de segurança (ObjectSID)

         Exemplo: S-1-5-21-4262554454-3312046685-1669053188-7103

         Nome da conta do Gerenciador de Contas de Segurança (SAM) (SamaccountName)

         Exemplo: OrchestratorGroup

         O cmdlet procura o contexto ou particao de nomeacao padrao para encontrar o objeto.Se dois ou mais objetos sao
         encontrado, o cmdlet retorna um erro.

         Este parametro tambem pode obter este objeto atraves do pipeline ou voce pode definir este parametro para um objeto
         ou instancia.

         .PARAMETER GroupTarget
         Objeto de grupo alvo.

         Especifica um objeto Grupo Active Directory, fornecendo um dos seguintes valores.O identificador dentro
         Parênteses é o nome de exibição LDAP para o atributo.

         Nome Distinto

         Exemplo: CN=GroupUsersRedeLab,OU=GrupoRedeLab,OU=RedeLab,DC=rbcorporate,DC=tech

         GUID (ObjectGuid)

         Exemplo: ceb16c43-0cee-4afa-8f90-7b2cc93023c4

         Identificador de segurança (ObjectSID)

         Exemplo: S-1-5-21-4262554454-3312046685-1669053188-7605

         Nome da conta do Gerenciador de Contas de Segurança (SAM) (SamaccountName)

         Exemplo: GroupUsersRedeLab

         O cmdlet procura o contexto ou particao de nomeacao padrao para encontrar o objeto.Se dois ou mais objetos sao
         encontrado, o cmdlet retorna um erro.

         Este parametro tambem pode obter este objeto atraves do pipeline ou voce pode definir este parametro para um objeto
         ou instancia.

         .PARAMETER Complete

         Remova todas as associacoes do Target que NAO existem no Source.

         .PARAMETER sinc

         Sincroniza a associacao de grupo entre o grupo de origem e o grupo de destino.
         Mesmo que um usuario seja membro apenas do GroupTarget, ele tambem sera copiado para o GroupSource.

         .EXAMPLE
         PS C:\> Copy-ADGroupUserMember -GroupSource GroupUsersRedeLab -GroupTarget OrchestratorGroup

         Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup'

         .EXAMPLE
         PS C:\> Copy-ADGroupUserMember -GroupSource 'GroupUsersRedeLab' -GroupTarget 'OrchestratorGroup' -sinc

         Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup' e vice-versa.
         Todas as associacoes do 'OrchestratorGroup' que NAO existem em 'GroupUsersRedeLab' tambem serao criadas em 'GroupUsersRedeLab'.

         .EXAMPLE
         PS C:\> Copy-ADGroupUserMember -GroupSource 'GroupUsersRedeLab' -GroupTarget 'OrchestratorGroup' -Complete

         Copie a associacao do Grupo 'GroupUsersRedeLab' para 'OrchestratorGroup'.
         Todas as associacoes do 'OrchestratorGroup' que NAO existem em 'GroupUsersRedeLab' serao removidas.

         .LINK
         https://github.com/RBNoronha/RBLN-PShareScripts

   #>
    [CmdletBinding(DefaultParameterSetName = 'default',
        ConfirmImpact = 'Low',
        SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0,
            HelpMessage = 'Objeto do grupo de origem.')]
        [ValidateNotNullOrEmpty()]
        [Alias('Source')]
        [string]
        $GroupSource,
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 1,
            HelpMessage = 'Objeto do grupo alvo.')]
        [ValidateNotNullOrEmpty()]
        [Alias('Target')]
        [string]
        $GroupTarget,
        [Parameter(ParameterSetName = 'Complete',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('RemoveTargetOnlyMembers')]
        [switch]
        $Complete = $null,
        [Parameter(ParameterSetName = 'sinc',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('MakeFullSync')]
        [switch]
        $sinc = $null
    )

    begin {
        if ($pscmdlet.ShouldProcess('Groups', 'Get information from Active Directory')) {
            try {
                $SourceMembers = (Get-ADGroupMember -Identity $GroupSource -ErrorAction Stop | Select-Object -ExpandProperty distinguishedName | Sort-Object)
                $TargetMembers = (Get-ADGroupMember -Identity $GroupTarget -ErrorAction Stop | Select-Object -ExpandProperty distinguishedName | Sort-Object)

                # Check if we have any diferences
                if (($SourceMembers) -and ($TargetMembers)) {
                    # Yep, there are differences
                    $Differences = (Compare-Object -ReferenceObject $SourceMembers -DifferenceObject $TargetMembers)
                } elseif (($SourceMembers) -and (-not($TargetMembers))) {
                    # Target has no members
                    $Differences = 'SourceOnly'
                } elseif (-not($SourceMembers)) {
                    # Source has no members
                    Write-Error -Message ('{0} has no members!' -f $GroupSource) -ErrorAction Stop
                } else {
                    # Nope, there are no differences
                    $Differences = $null
                }
            } catch {
                # get error record
                [Management.Automation.ErrorRecord]$e = $_

                # retrieve information about runtime error
                $info = [PSCustomObject]@{
                    Exception = $e.Exception.Message
                    Reason    = $e.CategoryInfo.Reason
                    Target    = $e.CategoryInfo.TargetName
                    Script    = $e.InvocationInfo.ScriptName
                    Line      = $e.InvocationInfo.ScriptLineNumber
                    Column    = $e.InvocationInfo.OffsetInLine
                }

                $info | Out-String | Write-Verbose

                Write-Error -Message $e.Exception.Message -ErrorAction Stop

                break
            }
        }
    }

    process {

        switch ($pscmdlet.ParameterSetName) {
            'Complete' {
                if ($pscmdlet.ShouldProcess($GroupTarget, 'Set')) {
                    if ($Differences) {
                        Write-Verbose -Message 'Remove Target-User from all groups where the Source-User is not a member of.'

                        $TargetOnlyMembers = ($Differences | Where-Object -Property SideIndicator -EQ -Value '=>')

                        if ($TargetOnlyMembers) {
                            try {
                                foreach ($TargetOnlyMember in $TargetOnlyMembers.InputObject) {
                                    Write-Verbose -Message ('Process: {0}' -f $TargetOnlyMember)

                                    $paramRemoveADGroupMember = @{
                                        Identity    = $GroupTarget
                                        Members     = $TargetOnlyMember
                                        ErrorAction = 'Stop'
                                        Confirm     = $false
                                    }
                                    $null = (Remove-ADGroupMember @paramRemoveADGroupMember -Verbose)
                                }
                            } catch {
                                # get error record
                                [Management.Automation.ErrorRecord]$e = $_

                                # retrieve information about runtime error
                                $info = [PSCustomObject]@{
                                    Exception = $e.Exception.Message
                                    Reason    = $e.CategoryInfo.Reason
                                    Target    = $e.CategoryInfo.TargetName
                                    Script    = $e.InvocationInfo.ScriptName
                                    Line      = $e.InvocationInfo.ScriptLineNumber
                                    Column    = $e.InvocationInfo.OffsetInLine
                                }

                                $info | Out-String | Write-Verbose

                                Write-Warning -Message $e.Exception.Message -ErrorAction Continue -WarningAction Continue
                            }
                        } else {
                            Write-Verbose -Message 'No group difference found where the Target-User is a member and Source-User is not.'
                        }
                    }
                }
            }
            'sinc' {
                if ($pscmdlet.ShouldProcess($GroupSource, 'Set')) {
                    if ($Differences) {
                        Write-Verbose -Message 'Make the Source-user a Member of all Groups only the Target-User is a member of.'

                        $TargetOnlyMembers = ($Differences | Where-Object -Property SideIndicator -EQ -Value '=>')

                        if ($TargetOnlyMembers) {
                            Write-Verbose -Message ('Process: {0}' -f $TargetOnlyMembers)

                            try {
                                $paramAddADGroupMember = @{
                                    Identity    = $GroupSource
                                    Members     = $TargetOnlyMembers.InputObject
                                    ErrorAction = 'Stop'
                                    Confirm     = $false
                                }
                                $null = (Add-ADGroupMember @paramAddADGroupMember)
                            } catch {
                                # get error record
                                [Management.Automation.ErrorRecord]$e = $_

                                # retrieve information about runtime error
                                $info = [PSCustomObject]@{
                                    Exception = $e.Exception.Message
                                    Reason    = $e.CategoryInfo.Reason
                                    Target    = $e.CategoryInfo.TargetName
                                    Script    = $e.InvocationInfo.ScriptName
                                    Line      = $e.InvocationInfo.ScriptLineNumber
                                    Column    = $e.InvocationInfo.OffsetInLine
                                }

                                $info | Out-String | Write-Verbose

                                Write-Warning -Message $e.Exception.Message -ErrorAction Continue -WarningAction Continue
                            }
                        } else {
                            Write-Verbose -Message 'No group difference found where the Target-User is a member and Source-User is not.'
                        }
                    }
                }
            }
            'default' {
                # Do nothing special
            }
        }

        if ($pscmdlet.ShouldProcess($GroupTarget, 'Set')) {
            if ($Differences) {
                try {
                    Write-Verbose -Message 'Process all Source-Group only members.'

                    $paramAddADGroupMember = @{
                        Identity    = $GroupTarget
                        ErrorAction = 'Stop'
                        Confirm     = $false
                    }

                    if ($Differences -eq 'SourceOnly') {
                        # Target has no members
                        $paramAddADGroupMember.Members = $SourceMembers
                    } else {
                        $paramAddADGroupMember.Members = ($Differences | Where-Object -Property SideIndicator -EQ -Value '<=' | Select-Object -ExpandProperty InputObject)
                    }

                    $null = (Add-ADGroupMember @paramAddADGroupMember)
                } catch {
                    # get error record
                    [Management.Automation.ErrorRecord]$e = $_

                    # retrieve information about runtime error
                    $info = [PSCustomObject]@{
                        Exception = $e.Exception.Message
                        Reason    = $e.CategoryInfo.Reason
                        Target    = $e.CategoryInfo.TargetName
                        Script    = $e.InvocationInfo.ScriptName
                        Line      = $e.InvocationInfo.ScriptLineNumber
                        Column    = $e.InvocationInfo.OffsetInLine
                    }

                    $info | Out-String | Write-Verbose

                    Write-Warning -Message $e.Exception.Message -ErrorAction Continue -WarningAction Continue
                }
            }
        }
    }
}



