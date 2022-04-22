Function Get-FolderSizeDetails {

    [cmdletbinding()]
    [Alias('gsize')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path

    )
    $dirs = get-childitem -path "$Path" -Directory -Recurse
    $paths = $dirs.fullname
    $paths += $Path
    $data = @()
    foreach ($item in $paths) {
        $name = $item.replace("\", "\\")
        Write-Host "Processing $name" -ForegroundColor cyan
        $data += Get-CimInstance -ClassName Win32_directory -filter "Name = '$name'" |
            Get-CimAssociatedInstance -ResultClassName CIM_Datafile -ov +a |
            Measure-object -Property FileSize -sum
    }
    $stats = $data | Measure-object Count, Sum -Sum
    [pscustomobject]@{
        Path             = $top
        TotalDirectories = $stats[0].count
        TotalFiles       = $stats[0].sum
        TotalSize        = $stats[1].sum
        TotalSizeMB      = $stats[1].sum / 1MB -as [int]
        TotalSizeGB      = $stats[1].sum / 1GB -as [int]
    }

}