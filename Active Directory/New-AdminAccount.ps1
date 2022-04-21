function New-AdminAccount {
    [CmdletBinding()]
    param(
        [string] $ComputerName = $Env:COMPUTERNAME,
        [string] $User,
        [string] $DisplayName = 'Local Admin',
        [string] $Description
    )
    $LocalUsers = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=true and Name LIKE '$User'"
    if (!$LocalUsers) {
        #"Running New-AdminAccount - $UserName" | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
        $RandomPassword = Get-RandomPassword -LettersLowerCase 7 -LettersHigherCase 7 -Numbers 3 -SpecialChars 10
        if ($User -ne '' -and $DisplayName -ne '') {
            # Create new local Admin user for script purposes
            $Computer = [ADSI]"WinNT://$ComputerName,Computer"
            $LocalAdmin = $Computer.Create("User", $User)
            try {
                $LocalAdmin.SetPassword($RandomPassword)
                $LocalAdmin.SetInfo()
                $LocalAdmin.FullName = $DisplayName
                $LocalAdmin.SetInfo()
                $LocalAdmin.Description = $Description
                #$LocalAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
                $LocalAdmin.UserFlags = 65536 # ADS_UF_DONT_EXPIRE_PASSWD
                $LocalAdmin.SetInfo()
            } catch {
                $ErrorMessage = $_.Exception.Message -replace [System.Environment]::NewLine
                Write-Warning "New-AdminAccount - Modification of local account failed: $ErrorMessage"
                #"New-AdminAccount - Modification of local account failed: $ErrorMessage" | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
                return
            }
        } else {
            #"New-AdminAccount - Account not created. UserName $User / DisplayName $DisplayName " | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
            Write-Warning "New-AdminAccount - Account not created. UserName $User / DisplayName $DisplayName"
        }
    }
}


function Get-RandomCharacters {
    [CmdletBinding()]
    param(
        [int] $length,
        [string] $characters
    )
    if ($length -ne 0 -and $characters -ne '') {
        $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
        $private:ofs = "" # https://blogs.msdn.microsoft.com/powershell/2006/07/15/psmdtagfaq-what-is-ofs/
        return [String]$characters[$random]
    } else {
        return
    }
}
function Get-RandomPassword {
    [CmdletBinding()]
    param(
        [int] $LettersLowerCase = 4,
        [int] $LettersHigherCase = 2,
        [int] $Numbers = 1,
        [int] $SpecialChars = 0,
        [int] $SpecialCharsLimited = 1
    )
    $Password = @(
        Get-RandomCharacters -length $LettersLowerCase -characters 'abcdefghiklmnoprstuvwxyz'
        Get-RandomCharacters -length $LettersHigherCase -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
        Get-RandomCharacters -length $Numbers -characters '1234567890'
        Get-RandomCharacters -length $SpecialChars -characters '!$%()=?{@#'
        Get-RandomCharacters -length $SpecialCharsLimited -characters '!$#'
    )
    $StringPassword = $Password -join ''
    $StringPassword = ($StringPassword.ToCharArray() | Get-Random -Count $StringPassword.Length) -join ''
    return $StringPassword
}
function Get-InvariantGroup {
    [CmdletBinding()]
    param(
        [ValidateSet(
            'Access Control Assistance Operators',
            'Administrators'                     ,
            'Backup Operators'                   ,
            'Cryptographic Operators'            ,
            'Device Owners'                      ,
            'Distributed COM Users'              ,
            'Event Log Readers'                  ,
            'Guests'                             ,
            'Hyper-V Administrators'             ,
            'IIS_IUSRS'                          ,
            'Network Configuration Operators'    ,
            'Performance Log Users'              ,
            'Performance Monitor Users'          ,
            'Power Users'                        ,
            'Remote Desktop Users'               ,
            'Remote Management Users'            ,
            'Replicator'                         ,
            'System Managed Accounts Group'      ,
            'Users'
        )] $GroupName
    )
    $GroupSID = @{
        'Access Control Assistance Operators' = 'S-1-5-32-579'
        'Administrators'                      = 'S-1-5-32-544'
        'Backup Operators'                    = 'S-1-5-32-551'
        'Cryptographic Operators'             = 'S-1-5-32-569'
        'Device Owners'                       = 'S-1-5-32-583'
        'Distributed COM Users'               = 'S-1-5-32-562'
        'Event Log Readers'                   = 'S-1-5-32-573'
        'Guests'                              = 'S-1-5-32-546'
        'Hyper-V Administrators'              = 'S-1-5-32-578'
        'IIS_IUSRS'                           = 'S-1-5-32-568'
        'Network Configuration Operators'     = 'S-1-5-32-556'
        'Performance Log Users'               = 'S-1-5-32-559'
        'Performance Monitor Users'           = 'S-1-5-32-558'
        'Power Users'                         = 'S-1-5-32-547'
        'Remote Desktop Users'                = 'S-1-5-32-555'
        'Remote Management Users'             = 'S-1-5-32-580'
        'Replicator'                          = 'S-1-5-32-552'
        'System Managed Accounts Group'       = 'S-1-5-32-581'
        'Users'                               = 'S-1-5-32-545'
    }
    $GroupSID[$GroupName]
}
function Add-LocalUserToGroups {
    [CmdletBinding()]
    param(
        [string] $Computer = $Env:ComputerName,
        [string] $User,
        [ValidateSet(
            'Access Control Assistance Operators',
            'Administrators'                     ,
            'Backup Operators'                   ,
            'Cryptographic Operators'            ,
            'Device Owners'                      ,
            'Distributed COM Users'              ,
            'Event Log Readers'                  ,
            'Guests'                             ,
            'Hyper-V Administrators'             ,
            'IIS_IUSRS'                          ,
            'Network Configuration Operators'    ,
            'Performance Log Users'              ,
            'Performance Monitor Users'          ,
            'Power Users'                        ,
            'Remote Desktop Users'               ,
            'Remote Management Users'            ,
            'Replicator'                         ,
            'System Managed Accounts Group'      ,
            'Users'
        )] $GroupName
    )
    # "Running Add-LocalUserToGroup" | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
    $LocalUsers = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=true and Name LIKE '$User'"
    if ($LocalUsers) {
        $SID = Get-InvariantGroup -GroupName $GroupName
        $ObjSID = New-Object System.Security.Principal.SecurityIdentifier($SID)
        $LocalAdminsGroup = (($ObjSID.Translate([System.Security.Principal.NTAccount]) ).Value).Split("\")[1]
        try {
            Write-Verbose "Adding security principal: $User to the $LocalAdminsGroup group..."
            #"Add-LocalUserToGroup - Adding security principal: $User to the $LocalAdminsGroup group..." | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
            $group = [ADSI]"WinNT://$Computer/$LocalAdminsGroup,group"
            $ismember = $false
            @($group.Invoke("Members")) | ForEach-Object {
                If ($User -eq $_.GetType.Invoke().InvokeMember("Name", 'GetProperty', $null, $_, $null)) {
                    $ismember = $true
                }
            }
            If ($ismember -eq $true) {
                Write-Verbose "User $User is already a member of $localadminsgroup"
                #"Add-LocalUserToGroup- User $User is already a member of $localadminsgroup" | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
            } Else {
                $result = $group.Add("WinNT://$User,user")
                Write-Verbose "User $User is added to $localadminsgroup"
                #"Add-LocalUserToGroup - User $User is added to $localadminsgroup" | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
            }
        } Catch {
            $ErrorMessage = $_.Exception.Message -replace [System.Environment]::NewLine
            Write-Verbose "Add-LocalUserToGroup - $ErrorMessage"
            #"Add-LocalUserToGroup - Adding $User to $LocalAdminsGroup failed: $ErrorMessage" | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
        }
    } else {
        Write-Warning "Add-LocalUserToGroup - $User doesn't exists. Terminating."
        #"Add-LocalUserToGroup - $User doesn't exists. Terminating." | Add-Content -Path 'C:\Temp\ScriptRunning.txt'
    }
}
New-AdminAccount -User 'LocalAdmin' -DisplayName 'Local Administrator'
Add-LocalUserToGroup -User 'LocalAdmin' -GroupName Administrators
