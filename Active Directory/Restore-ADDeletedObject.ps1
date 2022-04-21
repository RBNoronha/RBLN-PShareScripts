Function Restore-ADDeletedObject {

    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateNotNull()]
        [string[]]
        $SamAccountName
    )

    Begin {

    }
    Process {
        $search = [ADSISEARCHER]"(&(isDeleted=TRUE)(samaccountname=$SamAccountName))"
        $search.tombstone = $true
        $deletedusers = $search.Findall()
        $user = $deletedusers

        [String]$cn = "CN=$($user.Properties["cn"][0].ToString().Split("`n")[0])"
        $newDN = "$cn, $($user.Properties['lastKnownParent'][0])"

        $credential = [System.Net.CredentialCache]::DefaultNetworkCredentials

        $LdapDirectoryIdentifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier (([ADSI]"LDAP://RootDSE").servername.tostring().split(",")[0].Split("=")[1])

        $AuthenticationType = ([System.DirectoryServices.Protocols.AuthType]::Negotiate)

        $connection = New-Object System.DirectoryServices.Protocols.LdapConnection ($LdapDirectoryIdentifier, $credential, $AuthenticationType)

        $connection.Bind()
        $connection.SessionOptions.ProtocolVersion = 3


        $search.tombstone = $true
        $deletedusers = $search.Findall()

        $isDeleteAttributeMod = New-Object -TypeName System.DirectoryServices.Protocols.DirectoryAttributeModification
        $isDeleteAttributeMod.Name = "isDeleted"
        $isDeleteAttributeMod.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Delete


        $dnAttributeMod = New-Object -TypeName System.DirectoryServices.Protocols.DirectoryAttributeModification
        $dnAttributeMod.Name = "distinguishedName"
        $dnAttributeMod.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
        $dnAttributeMod.Add($newDN)

        $request = New-Object -TypeName System.DirectoryServices.Protocols.ModifyRequest
        $request.DistinguishedName = $($user.properties.distinguishedname)
        $request.Modifications.Add($isDeleteAttributeMod)
        $request.Modifications.Add($dnAttributeMod)

        $ShowDeletedControl = New-Object -TypeName System.DirectoryServices.Protocols.ShowDeletedControl
        $request.Controls.Add($ShowDeletedControl)
        try {
            $response = $connection.SendRequest($request)

            if ($response.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-output "A conta $SamAccountName foi restaurada com sucesso!"
            } else {
                Write-Output "Houve um erro ao processar a solicitacao"
            }
        } catch { }
    }
    End {

    }
}