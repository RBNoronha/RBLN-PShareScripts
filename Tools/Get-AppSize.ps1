Function Get-AppSize {

    [cmdletbinding()]
    
    [Alias('app')]
    Param()

    Get-AppxProvisionedPackage -online | ForEach-Object {
        $SPL = Split-Path ( [Environment]::ExpandEnvironmentVariables($_.InstallLocation) ) -Parent
        If ((Split-Path $SPL -Leaf) -ieq 'AppxMetadata') {
            $SPL = Split-Path $SPL -Parent
        }
        $MTH = Join-Path -Path (Split-Path $SPL -Parent) -ChildPath "$($_.DisplayName)*"
        $Size = (Get-ChildItem $MTH -Recurse -ErrorAction Ignore | Measure-Object -Property Length -Sum).Sum
        $_ | Add-Member -NotePropertyName Size -NotePropertyValue $Size
        $_ | Add-Member -NotePropertyName InstallFolder -NotePropertyValue $SPL
        $_
    } | Select-Object DisplayName, PackageName, Version, InstallFolder, Size

}
