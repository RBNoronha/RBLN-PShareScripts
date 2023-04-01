function Download-RawFileGitHub {
    
    <#
    
    .SYNOPSIS
        Download a raw file from GitHub

    .DESCRIPTION
        Download a raw file from GitHub and verify if the content of the downloaded file matches the content of the file on GitHub, and that the downloaded file name is the same as the file on GitHub.

    .PARAMETER Uri
        GitHub Raw file URI

    .EXAMPLE
        Download-RawFileGitHub -Uri https://raw.githubusercontent.com/RBNoronha/RBLN-PShareScripts/main/Active%20Directory/Get-ADCompareGroupUser.ps1"

    .NOTES
        Autor: Renan B. Noronha
        Data: 2023-03-31
        Versao: 1.0

    .LINK
        GitHub: https://github.com/RBNoronha/RBLN-PShareScripts/Download-RawFileGitHub.ps1

    #>

    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    $WebClient = New-Object System.Net.WebClient
    $WebClient.UseDefaultCredentials = $true

    $FileName = $Uri.Split("/")[-1]
    $OutFile = Join-Path (Get-Location) $FileName

    $WebClient.DownloadFile($Uri, $OutFile)

    $ExpectedContent = (Invoke-WebRequest -Uri $Uri -UseBasicParsing).Content
    $ActualContent = Get-Content -Path $OutFile -Raw

    if ($ExpectedContent -eq $ActualContent) {

        Write-Output "The file '$OutFile' has been successfully downloaded and its contents match the expected."

    } else {

        Write-Warning "The file '$OutFile' was not downloaded or its contents do not match the expected."
    }
}
