function Search-ADDeletedAccounts {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [System.String]
        [ValidateSet("Users", "Groups", "Computers")]
        $ObjectType
    )

    begin {

    }
    process {
        switch ($ObjectType) {
            'Users' {
                $search = [ADSISEARCHER]"(&(isDeleted=TRUE)(!objectClass=computer)(objectClass=User))"
                $search.tombstone = $true
                $deletedusers = $search.Findall()
            }
            'Computers' {
                $search = [ADSISEARCHER]"(&(isDeleted=TRUE)(objectclass=computer))"
                $search.tombstone = $true
                $deletedusers = $search.Findall()
            }
            'Groups' {
                $search = [ADSISEARCHER]"(&(isDeleted=TRUE)(objectclass=group))"
                $search.tombstone = $true
                $deletedusers = $search.Findall()
            }
            default {
                $search = [ADSISEARCHER]"(&(isDeleted=TRUE)(!objectClass=computer)(objectClass=User))"
                $search.tombstone = $true
                $deletedusers = $search.Findall()
            }
        }

        $search.tombstone = $true
        $deletedusers = $search.Findall()
        foreach ($user in $deletedusers) {

            [PSCustomObject]@{
                SamAccountName    = [String]$($user.Properties.samaccountname)
                Deleted           = [bool]$($user.Properties.isdeleted)
                whenChanged       = [String]$($user.Properties.whenchanged)
                LastKnownParent   = [String]$($user.Properties.lastknownparent)
                distinguishedName = [String]$($user.Properties.distinguishedname)
            }
        }
    }
    end {

    }
}