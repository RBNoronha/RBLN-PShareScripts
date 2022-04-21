function Get-ADCompareGroupUser {


    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $True, ValueFromPipeline = $True,
            HelpMessage = "A primeira conta de usuario que voce gostaria de comparar")]
        [string]$Identity1,

        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true, ValueFromPipeline = $True,
            HelpMessage = "A segunda conta de usuario que voce gostaria de comparar")]
        [string]$Identity2
    )

    $user1 = (Get-ADPrincipalGroupMembership -Identity $Identity1 | Select-Object Name | Sort-Object -Property Name).Name
    Write-Verbose ($Identity1 -join "; ")
    $user2 = (Get-ADPrincipalGroupMembership -Identity $Identity2 | Select-Object Name | Sort-Object -Property Name).Name
    Write-Verbose ""
    Write-Verbose ($Identity2 -join "; ")
    $SameGroups = (Compare-Object $user1 $user2 -PassThru -IncludeEqual -ExcludeDifferent)
    Write-Verbose ""
    Write-Verbose ($SameGroups -join "; ")
    $UniqueID1 = (Compare-Object $user1 $user2 -PassThru | Where-Object { $_.SideIndicator -eq "<=" })
    Write-Verbose ""
    Write-Verbose ($UniqueID1 -join "; ")
    $UniqueID2 = (Compare-Object $user1 $user2 -PassThru | Where-Object { $_.SideIndicator -eq "=>" })
    Write-Verbose ""
    Write-Verbose ($UniqueID2 -join "; ")
    $ID1Name = (Get-ADUser -Identity $Identity1 | Select-Object Name).Name
    Write-Verbose ""
    Write-Verbose ($ID1Name -join "; ")
    $ID2Name = (Get-ADUser -Identity $Identity2 | Select-Object Name).Name
    Write-Verbose ""
    Write-Verbose ($ID2Name -join "; ")

    Write-Host "--------------------------------------------------------------------------"
    Write-Host "[$ID1Name - $Identity1] e [$ID2Name - $Identity2] tem os seguintes grupos em comum:" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------"
    $SameGroups
    Write-Host ""

    Write-Host "--------------------------------------------------------------------------"
    Write-Host "Os grupos a seguir sao exclusivos para [$ID1Name - $Identity1]:" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------"
    $UniqueID1
    Write-Host ""
    Write-Host "--------------------------------------------------------------------------"
    Write-Host "Os grupos a seguir sao exclusivos para [$ID2Name - $Identity2]:" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------------"
    $UniqueID2

}