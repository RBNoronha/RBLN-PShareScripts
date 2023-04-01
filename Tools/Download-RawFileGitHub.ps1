function Download-RawFileGitHub {
    
    <#
    
    .SYNOPSIS
        Download a raw file from GitHub

    .DESCRIPTION
        Download a Raw file from GitHub and check if the content of the downloaded file matches the content of the file on GitHub, and if the name of the downloaded file is the same as the file on GitHub. If the file already exists in the destination directory, the user is prompted whether they want to replace it.

    .PARAMETER Uri
        GitHub Raw file URI

    .PARAMETER Path
        Directory path of the destination file. The default value is the current directory.

    .EXAMPLE
        Download-RawFileGitHub -Uri https://raw.githubusercontent.com/RBNoronha/RBLN-PShareScripts/main/Active%20Directory/Get-ADCompareGroupUser.ps1

    .EXAMPLE
        Download-RawFileGitHub -Uri https://raw.githubusercontent.com/RBNoronha/RBLN-PShareScripts/main/Active%20Directory/Get-ADCompareGroupUser.ps1 -Path C:\Temp

    .NOTES
        Autor: Renan B. Noronha
        Data: 2023-03-31
        Versao: 1.1

    .LINK
        GitHub: https://github.com/RBNoronha/RBLN-PShareScripts/Download-RawFileGitHub.ps1

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $false)]
        [string]$Path = $PWD.Path
    )

    $fileName = Split-Path -Leaf $Uri
    $outFile = Join-Path $Path $fileName

    if (Test-Path -Path $outFile) {
        $response = Read-Host "The file '$fileName' already exists in the '$Path' directory. Do you want to replace it? (y/n)"
        if ($response -ne "y") {
            Write-Output "Download of file '$fileName' was cancelled by user."
            throw "Download of file '$fileName' was cancelled by user."
        }
    }

    try {
        $client = New-Object System.Net.WebClient
        $client.UseDefaultCredentials = $true
        $client.DownloadFile($Uri, $outFile)

        $expectedContent = (Invoke-WebRequest -Uri $Uri -UseBasicParsing).Content
        $actualContent = Get-Content -Path $outFile -Raw -Encoding UTF8

        if ($expectedContent -eq $actualContent) {
            Write-Output "File '$fileName' was downloaded successfully and its content matches the expected content."
        } else {
            Write-Warning "File '$fileName' was not downloaded or its content does not match the expected content."
        }
    } finally {
        $client.Dispose()
    }
}
