param(
    [Parameter(Mandatory,
        HelpMessage = "Enter the pattern for filtering groups"
    )]
    $Pattern
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

# Getting all the groups with display name starting with the provided pattern
$Groups = Get-MgGroup -Filter "startswith(displayname,'$Pattern')" -Top 2000

# Looping through all the filtered groups and exporting their members to the Excel files
$Count = 0
foreach ($Group in $Groups) {
    $Count += 1
    $WorkSheetName = "Group$($Count)"
    Try{
    $Range = "A1:B1" # defining the cell range
    (Get-MgGroupMember -GroupId $Group.id -Top 150).AdditionalProperties | `
            Select-Object @{n = "DisplayName"; e = { $_.displayName } }, @{n = "UserPrincipalName"; e = { $_.userPrincipalName } } |`
            Export-Excel -Path $ExcelFilePath -WorksheetName $WorkSheetName -Append -TableStyle 'Medium16' `
            -Title $Group.DisplayName -TitleSize 14 -TitleBold -Range $Range
    }
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor 'Red'
        Break
    }
}
