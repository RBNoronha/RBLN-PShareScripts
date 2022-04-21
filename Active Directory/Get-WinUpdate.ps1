function Get-WinUpdate {
    [CmdletBinding()]

    param([string[]] $ComputerName = $Env:COMPUTERNAME,
        [ValidateSet('Default', 'Dcom', 'Wsman')][string] $Protocol = 'Default',
        [switch] $All)

    [string] $Class = 'Win32_QuickFixEngineering'

    if ($All) { [string] $Properties = '*' } else { [string[]] $Properties = 'PSComputerName', 'Description', 'HotFixID', 'Caption', 'InstalledOn' }
    $Information = Get-CimInstance -ComputerName $ComputerName -ClassName $Class -Property $Properties

    if ($All) { $Information } else {
        foreach ($Info in $Information) {
            foreach ($Data in $Info) {
                [PSCustomObject] @{

                    NomeDoComputador = if ($Data.PSComputerName) { $Data.PSComputerName } else { $Env:COMPUTERNAME }
                    Categoria        = $Data.Description
                    IDHotfix         = $Data.HotFixID
                    Caption          = $Data.Caption
                    DataInstalacao   = $Data.InstalledOn

                }

            }

        }

    }
}