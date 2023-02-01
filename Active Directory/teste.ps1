param(
    [Parameter(Mandatory,
        HelpMessage = "Enter the pattern for filtering groups"
    )]
    $Pattern,
    [Parameter(Mandatory = $false,
        HelpMessage = "Enter the range for filtering groups"
    )]
    $Range = 150
)

# Excel file path
$ExcelFilePath = "$($PSScriptroot)\GroupMembers.xlsx"

# Azure AD App details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Getting all the groups with displayname starting with the provided pattern
$Groups = Get-MgGroup -filter "startswith(displayname,'$Pattern')" -Top 2000

# Looping through all the filtered groups and exporting their members to the csv files
$Count = 0
foreach ($Group in $Groups) {
    $Count += 1
    $WorkSheetName = "Group$($Count)"
    Try{
    (Get-MgGroupMember -GroupId $Group.id -Top $Range).AdditionalProperties | `
            Select-Object @{n = "DisplayName"; e = { $_.displayName } }, @{n = "UserprincipalName"; e = { $_.userPrincipalName } } |`
            Export-Excel -path $ExcelFilePath -WorksheetName $WorkSheetName -Append -TableStyle 'Medium16' `
            -Title $Group.Displayname -TitleSize 14 -TitleBold
    }
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor 'Red'
        Break
    }
}
