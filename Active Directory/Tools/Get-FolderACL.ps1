function Get-FolderACL {
    param (
        [string]$Path,
        [switch]$ExpandGroups = $false,
        [string]$RightsRegex
    )
    begin {
        function Get-Member ([string]$GroupName) {
            if ($GroupName -match 'S-\d-\d-\d+') {
                $GroupName = $GroupName.Substring(3).Split(',', 2)[0]
                try {
                    $GroupName = ([System.Security.Principal.SecurityIdentifier]($GroupName)).Translate([System.Security.Principal.NTAccount]).Value
                    $GroupName = ([adsisearcher]"samaccountname=$GroupName").FindOne().Path.Substring(7)
                } catch {
                    Write-Warning "Could not translate $GroupName to name."
                }
            }
            $Grouppath = "LDAP://" + $GroupName
            $GroupObj = [adsi]$Grouppath
            $users = foreach ($member in $GroupObj.Member) {
                $UserPath = "LDAP://" + $member
                $UserObj = [adsi]$UserPath
                if (-not ($UserObj.groupType.Value -ne $null)) {
                    $member
                } else {
                    Get-Member -GroupName $member
                }
            }
            $users | select -Unique
        }
    }
    process {
        Write-Host "Running Get-FolderACL for $Path..."
        $arraylist = New-Object System.Collections.ArrayList
        try {
            $CurrentACL = Get-Acl -Path $Path
        } catch {
            Write-Warning "Could not Get-Acl for $Path"
            continue
        }
        $owner = $CurrentACL.Owner
        $CurrentACL.Access | ForEach-Object {
            $FileSystemRights = $_.FileSystemRights.ToString()
            if ($RightsRegex -and !($FileSystemRights -match $RightsRegex)) {
                return
            }
            $IdentityReference = ''
            $IdentityReference = $_.IdentityReference.ToString()
            $UserDomain = ''
            $UserAccount = ''
            if ($IdentityReference -match '\\') {
                $UserDomain = $IdentityReference.Substring(0, $IdentityReference.IndexOf('\'))
                $UserAccount = $IdentityReference.Substring($IdentityReference.IndexOf('\') + 1)
            }
            if ($UserAccount -match 'S-\d-\d-\d+') {
                try {
                    $UserAccount = ([System.Security.Principal.SecurityIdentifier]($UserAccount)).Translate([System.Security.Principal.NTAccount]).Value
                } catch {
                    Write-Warning "Could not translate $UserAccount to name."
                }
            }
            $ObjectCategory = ''
            $Enabled = ''
            $hash = New-Object System.Collections.Specialized.OrderedDictionary
            $hash.Add('Path', $Path)
            $hash.Add('Owner', $owner)
            $hash.Add('ObjectCategory', $ObjectCategory)
            $hash.Add('Enabled', $Enabled)
            $hash.Add('IdentityReference', $IdentityReference)
            $hash.Add('FileSystemRights', $FileSystemRights)
            $hash.Add('AsMemberOf', '')
            $hash.Add('IsInherited', $_.IsInherited.ToString())
            $hash.Add('InheritanceFlags', $_.InheritanceFlags.ToString())
            $hash.Add('PropagationFlags', $_.PropagationFlags.ToString())
            $hash.Add('AccessControlType', $_.AccessControlType.ToString())
            $obj = New-Object psobject -Property $hash
            if ($UserDomain -eq $env:COMPUTERNAME -or $UserDomain -eq 'BUILTIN') {
                $winnt = [adsi]"WinNT://$env:COMPUTERNAME/$UserAccount"
                if (-not $winnt.groupType.Value.GetType().ToString().EndsWith('Int32')) {
                    $obj.ObjectCategory = 'User'
                    if (($winnt.userflags[0] -band 2) -ne 0) {
                        $obj.Enabled = $false
                    } else {
                        $obj.Enabled = $true
                    }
                } else {
                    $obj.ObjectCategory = 'Group'
                }
            } elseif ($UserDomain -eq 'NT AUTHORITY') {
                $obj.ObjectCategory = ''
                $obj.Enabled = ''
            } else {
                try {
                    $searcher = [adsisearcher]"samaccountname=$UserAccount"
                    $searcher.PropertiesToLoad.AddRange(('distinguishedname', 'objectcategory', 'useraccountcontrol'))
                    $result1 = New-Object psobject -Property $([hashtable]$searcher.FindOne().Properties)
                    $obj.ObjectCategory = [string]$result1.ObjectCategory -replace '^cn=|,.*'
                    $obj.Enabled = if (([string]$result1.UserAccountControl -band 2) -eq 0) { $true } else { $false }
                } catch {
                    $result1 = $null
                }
            }
            [void]$arraylist.Add($obj)
            if ($ExpandGroups -and $obj.ObjectCategory -eq 'Group' -and -not ($UserDomain -eq 'NT AUTHORITY') -and -not ($UserAccount -match '(domain )?administrators')) {
                Get-Member $result1.distinguishedname | ForEach-Object {
                    $newobj = $obj.PsObject.Copy()
                    $newobj.AsMemberOf = $IdentityReference
                    if ($_ -match 'S-\d-\d-\d+') {
                        $newobj.ObjectCategory = ''
                        $newobj.Enabled = ''
                        $UserAccount = $_.Substring(3).Split(',', 2)[0]
                        try {
                            $UserAccount = ([System.Security.Principal.SecurityIdentifier]($UserAccount)).Translate([System.Security.Principal.NTAccount]).Value
                        } catch {
                            Write-Warning "Could not translate $UserAccount to name."
                        }
                    } else {
                        $searcher = [adsisearcher]"distinguishedname=$_"
                        $searcher.PropertiesToLoad.AddRange(('userprincipalname', 'objectcategory', 'useraccountcontrol'))
                        $result2 = New-Object psobject -Property $([hashtable]$searcher.FindOne().Properties)
                        $newobj.ObjectCategory = [string]$result2.ObjectCategory -replace '^cn=|,.*'
                        $newobj.Enabled = if (([string]$result2.UserAccountControl -band 2) -eq 0) { $true } else { $false }
                        $UserAccount = $result2.UserPrincipalName.Split('@', 2)[0]
                    }
                    $UserDomain = ($_.Split(',') | ? { $_.StartsWith('DC=') })[0].Substring(3).ToUpper()
                    $newobj.IdentityReference = $UserDomain + '\' + $UserAccount
                    [void]$arraylist.Add($newobj)
                }
            }
        }
        Write-Output $arraylist | select * -Unique
    }
}