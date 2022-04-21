function ConvertFrom-Color {
    [alias('Convert-FromColor')]
    [CmdletBinding()]
    param ([ValidateScript( { if ($($_ -in $Script:RGBColors.Keys -or $_ -match "^#([A-Fa-f0-9]{6})$" -or $_ -eq "") -eq $false) { throw "The Input value is not a valid colorname nor an valid color hex code." } else { $true } })]
        [alias('Colors')][string[]] $Color,
        [switch] $AsDecimal,
        [switch] $AsDrawingColor)
    $Colors = foreach ($C in $Color) {
        $Value = $Script:RGBColors."$C"
        if ($C -match "^#([A-Fa-f0-9]{6})$") { return $C }
        if ($null -eq $Value) { return }
        $HexValue = Convert-Color -RGB $Value
        Write-Verbose "Convert-FromColor - Color Name: $C Value: $Value HexValue: $HexValue"
        if ($AsDecimal) { [Convert]::ToInt64($HexValue, 16) } elseif ($AsDrawingColor) { [System.Drawing.Color]::FromArgb("#$($HexValue)") } else { "#$($HexValue)" }
    }
    $Colors
}
function ConvertFrom-ScriptBlock {
    [CmdletBinding()]
    param([ScriptBlock] $ScriptBlock)
    [Array] $Output = foreach ($Line in $ScriptBlock.Ast.EndBlock.Statements.Extent) { [string] $Line + [System.Environment]::NewLine }
    return $Output
}
function Format-PSTable {
    [CmdletBinding()]
    param ([parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][System.Collections.ICollection] $Object,
        [switch] $SkipTitle,
        [string[]] $Property,
        [string[]] $ExcludeProperty,
        [Object] $OverwriteHeaders,
        [switch] $PreScanHeaders,
        [string] $Splitter = ';')
    if ($Object[0] -is [System.Collections.IDictionary]) {
        $Array = @(if (-not $SkipTitle) { , @('Name', 'Value') }
            foreach ($O in $Object) {
                foreach ($Name in $O.Keys) {
                    $Value = $O[$Name]
                    if ($O[$Name].Count -gt 1) { $Value = $O[$Name] -join $Splitter } else { $Value = $O[$Name] }
                    , @($Name, $Value)
                }
            })
        if ($Array.Count -eq 1) { , $Array } else { $Array }
    } elseif ($Object[0].GetType().Name -match 'bool|byte|char|datetime|decimal|double|ExcelHyperLink|float|int|long|sbyte|short|string|timespan|uint|ulong|URI|ushort') { return $Object } else {
        if ($Property) { $Object = $Object | Select-Object -Property $Property }
        $Array = @(if ($PreScanHeaders) { $Titles = Get-ObjectProperties -Object $Object } elseif ($OverwriteHeaders) { $Titles = $OverwriteHeaders } else { $Titles = $Object[0].PSObject.Properties.Name }
            if (-not $SkipTitle) { , $Titles }
            foreach ($O in $Object) {
                $ArrayValues = foreach ($Name in $Titles) {
                    $Value = $O."$Name"
                    if ($Value.Count -gt 1) { $Value -join $Splitter } elseif ($Value.Count -eq 1) { if ($Value.Value) { $Value.Value } else { $Value } } else { '' }
                }
                , $ArrayValues
            })
        if ($Array.Count -eq 1) { , $Array } else { $Array }
    }
}
function Format-TransposeTable {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][System.Collections.ICollection] $Object,
        [ValidateSet("ASC", "DESC", "NONE")][String] $Sort = 'NONE')
    process {
        foreach ($myObject in $Object) {
            if ($myObject -is [System.Collections.IDictionary]) { if ($Sort -eq 'ASC') { [PSCustomObject] $myObject.GetEnumerator() | Sort-Object -Property Name -Descending:$false } elseif ($Sort -eq 'DESC') { [PSCustomObject] $myObject.GetEnumerator() | Sort-Object -Property Name -Descending:$true } else { [PSCustomObject] $myObject } } else {
                $Output = [ordered] @{}
                if ($Sort -eq 'ASC') { $myObject.PSObject.Properties | Sort-Object -Property Name -Descending:$false | ForEach-Object { $Output["$($_.Name)"] = $_.Value } } elseif ($Sort -eq 'DESC') { $myObject.PSObject.Properties | Sort-Object -Property Name -Descending:$true | ForEach-Object { $Output["$($_.Name)"] = $_.Value } } else { $myObject.PSObject.Properties | ForEach-Object { $Output["$($_.Name)"] = $_.Value } }
                $Output
            }
        }
    }
}
function Get-FileName {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Extension
    Parameter description

    .PARAMETER Temporary
    Parameter description

    .PARAMETER TemporaryFileOnly
    Parameter description

    .EXAMPLE
    Get-FileName -Temporary
    Output: 3ymsxvav.tmp

    .EXAMPLE

    Get-FileName -Temporary
    Output: C:\Users\pklys\AppData\Local\Temp\tmpD74C.tmp

    .EXAMPLE

    Get-FileName -Temporary -Extension 'xlsx'
    Output: C:\Users\pklys\AppData\Local\Temp\tmp45B6.xlsx


    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param([string] $Extension = 'tmp',
        [switch] $Temporary,
        [switch] $TemporaryFileOnly)
    if ($Temporary) { return "$($([System.IO.Path]::GetTempFileName()).Replace('.tmp','')).$Extension" }
    if ($TemporaryFileOnly) { return "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).$Extension" }
}
function Get-RandomStringName {
    [cmdletbinding()]
    param([int] $Size = 31,
        [switch] $ToLower,
        [switch] $ToUpper,
        [switch] $LettersOnly)
    [string] $MyValue = @(if ($LettersOnly) { ( -join ((1..$Size) | ForEach-Object { (65..90) + (97..122) | Get-Random } | ForEach-Object { [char]$_ })) } else { ( -join ((48..57) + (97..122) | Get-Random -Count $Size | ForEach-Object { [char]$_ })) })
    if ($ToLower) { return $MyValue.ToLower() }
    if ($ToUpper) { return $MyValue.ToUpper() }
    return $MyValue
}
function New-Runspace {
    [cmdletbinding()]
    param ([int] $minRunspaces = 1,
        [int] $maxRunspaces = [int]$env:NUMBER_OF_PROCESSORS + 1)
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool($minRunspaces, $maxRunspaces)
    $RunspacePool.Open()
    return $RunspacePool
}
function Start-Runspace {
    [cmdletbinding()]
    param ([ScriptBlock] $ScriptBlock,
        [System.Collections.IDictionary] $Parameters,
        [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool)
    if ($ScriptBlock -ne '') {
        $runspace = [PowerShell]::Create()
        $null = $runspace.AddScript($ScriptBlock)
        if ($null -ne $Parameters) { $null = $runspace.AddParameters($Parameters) }
        $runspace.RunspacePool = $RunspacePool
        [PSCustomObject]@{Pipe = $runspace
            Status             = $runspace.BeginInvoke()
        }
    }
}
function Start-TimeLog {
    [CmdletBinding()]
    param()
    [System.Diagnostics.Stopwatch]::StartNew()
}
function Stop-Runspace {
    [cmdletbinding()]
    param([Array] $Runspaces,
        [string] $FunctionName,
        [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool,
        [switch] $ExtendedOutput)
    [Array] $List = While (@($Runspaces | Where-Object -FilterScript { $null -ne $_.Status }).count -gt 0) {
        foreach ($Runspace in $Runspaces | Where-Object { $_.Status.IsCompleted -eq $true }) {
            $Errors = foreach ($e in $($Runspace.Pipe.Streams.Error)) {
                Write-Error -ErrorRecord $e
                $e
            }
            foreach ($w in $($Runspace.Pipe.Streams.Warning)) { Write-Warning -Message $w }
            foreach ($v in $($Runspace.Pipe.Streams.Verbose)) { Write-Verbose -Message $v }
            if ($ExtendedOutput) {
                @{Output   = $Runspace.Pipe.EndInvoke($Runspace.Status)
                    Errors = $Errors
                }
            } else { $Runspace.Pipe.EndInvoke($Runspace.Status) }
            $Runspace.Status = $null
        }
    }
    $RunspacePool.Close()
    $RunspacePool.Dispose()
    if ($List.Count -eq 1) { return , $List } else { return $List }
}
function Stop-TimeLog {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline = $true)][System.Diagnostics.Stopwatch] $Time,
        [ValidateSet('OneLiner', 'Array')][string] $Option = 'OneLiner',
        [switch] $Continue)
    Begin {}
    Process { if ($Option -eq 'Array') { $TimeToExecute = "$($Time.Elapsed.Days) days", "$($Time.Elapsed.Hours) hours", "$($Time.Elapsed.Minutes) minutes", "$($Time.Elapsed.Seconds) seconds", "$($Time.Elapsed.Milliseconds) milliseconds" } else { $TimeToExecute = "$($Time.Elapsed.Days) days, $($Time.Elapsed.Hours) hours, $($Time.Elapsed.Minutes) minutes, $($Time.Elapsed.Seconds) seconds, $($Time.Elapsed.Milliseconds) milliseconds" } }
    End {
        if (-not $Continue) { $Time.Stop() }
        return $TimeToExecute
    }
}
function Convert-Color {
    <#
    .Synopsis
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
    .Description
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
    .Parameter RBG
    Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
    .Parameter HEX
    Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
    .Example
    .\convert-color -hex FFFFFF
    Converts hex value FFFFFF to RGB

    .Example
    .\convert-color -RGB 123,200,255
    Converts Red = 123 Green = 200 Blue = 255 to Hex value

    #>
    param([Parameter(ParameterSetName = "RGB", Position = 0)]
        [ValidateScript( { $_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$' })]
        $RGB,
        [Parameter(ParameterSetName = "HEX", Position = 0)]
        [ValidateScript( { $_ -match '[A-Fa-f0-9]{6}' })]
        [string]
        $HEX)
    switch ($PsCmdlet.ParameterSetName) {
        "RGB" {
            if ($null -eq $RGB[2]) { Write-Error "Value missing. Please enter all three values seperated by comma." }
            $red = [convert]::Tostring($RGB[0], 16)
            $green = [convert]::Tostring($RGB[1], 16)
            $blue = [convert]::Tostring($RGB[2], 16)
            if ($red.Length -eq 1) { $red = '0' + $red }
            if ($green.Length -eq 1) { $green = '0' + $green }
            if ($blue.Length -eq 1) { $blue = '0' + $blue }
            Write-Output $red$green$blue
        }
        "HEX" {
            $red = $HEX.Remove(2, 4)
            $Green = $HEX.Remove(4, 2)
            $Green = $Green.remove(0, 2)
            $Blue = $hex.Remove(0, 4)
            $Red = [convert]::ToInt32($red, 16)
            $Green = [convert]::ToInt32($green, 16)
            $Blue = [convert]::ToInt32($blue, 16)
            Write-Output $red, $Green, $blue
        }
    }
}
function Get-ObjectProperties {
    [CmdletBinding()]
    param ([System.Collections.ICollection] $Object,
        [string[]] $AddProperties,
        [switch] $Sort,
        [bool] $RequireUnique = $true)
    $Properties = @(foreach ($O in $Object) {
            $ObjectProperties = $O.PSObject.Properties.Name
            $ObjectProperties
        }
        foreach ($Property in $AddProperties) { $Property })
    if ($Sort) { return $Properties | Sort-Object -Unique:$RequireUnique } else { return $Properties | Select-Object -Unique:$RequireUnique }
}
function ConvertTo-ScriptBlock {
    [cmdletBinding()]
    param([Array] $Code,
        [string[]] $Include,
        [string[]] $Exclude)
    if ($Include) { $Output = foreach ($Line in $Code) { foreach ($I in $Include) { if ($Line.StartsWith($I)) { $Line } } } }
    if ($Exclude) {
        $Output = foreach ($Line in $Code) {
            $Tests = foreach ($E in $Exclude) { if ($Line.StartsWith($E)) { $true } }
            if ($Tests -notcontains $true) { $Line }
        }
    }
    if ($Output) { [ScriptBlock]::Create($Output) }
}
[int] $Script:SaveCounter = 0
$Script:RGBColors = [ordered] @{None = $null
    AirForceBlue                     = 93, 138, 168
    Akaroa                           = 195, 176, 145
    AlbescentWhite                   = 227, 218, 201
    AliceBlue                        = 240, 248, 255
    Alizarin                         = 227, 38, 54
    Allports                         = 18, 97, 128
    Almond                           = 239, 222, 205
    AlmondFrost                      = 159, 129, 112
    Amaranth                         = 229, 43, 80
    Amazon                           = 59, 122, 87
    Amber                            = 255, 191, 0
    Amethyst                         = 153, 102, 204
    AmethystSmoke                    = 156, 138, 164
    AntiqueWhite                     = 250, 235, 215
    Apple                            = 102, 180, 71
    AppleBlossom                     = 176, 92, 82
    Apricot                          = 251, 206, 177
    Aqua                             = 0, 255, 255
    Aquamarine                       = 127, 255, 212
    Armygreen                        = 75, 83, 32
    Arsenic                          = 59, 68, 75
    Astral                           = 54, 117, 136
    Atlantis                         = 164, 198, 57
    Atomic                           = 65, 74, 76
    AtomicTangerine                  = 255, 153, 102
    Axolotl                          = 99, 119, 91
    Azure                            = 240, 255, 255
    Bahia                            = 176, 191, 26
    BakersChocolate                  = 93, 58, 26
    BaliHai                          = 124, 152, 171
    BananaMania                      = 250, 231, 181
    BattleshipGrey                   = 85, 93, 80
    BayOfMany                        = 35, 48, 103
    Beige                            = 245, 245, 220
    Bermuda                          = 136, 216, 192
    Bilbao                           = 42, 128, 0
    BilobaFlower                     = 181, 126, 220
    Bismark                          = 83, 104, 114
    Bisque                           = 255, 228, 196
    Bistre                           = 61, 43, 31
    Bittersweet                      = 254, 111, 94
    Black                            = 0, 0, 0
    BlackPearl                       = 31, 38, 42
    BlackRose                        = 85, 31, 47
    BlackRussian                     = 23, 24, 43
    BlanchedAlmond                   = 255, 235, 205
    BlizzardBlue                     = 172, 229, 238
    Blue                             = 0, 0, 255
    BlueDiamond                      = 77, 26, 127
    BlueMarguerite                   = 115, 102, 189
    BlueSmoke                        = 115, 130, 118
    BlueViolet                       = 138, 43, 226
    Blush                            = 169, 92, 104
    BokaraGrey                       = 22, 17, 13
    Bole                             = 121, 68, 59
    BondiBlue                        = 0, 147, 175
    Bordeaux                         = 88, 17, 26
    Bossanova                        = 86, 60, 92
    Boulder                          = 114, 116, 114
    Bouquet                          = 183, 132, 167
    Bourbon                          = 170, 108, 57
    Brass                            = 181, 166, 66
    BrickRed                         = 199, 44, 72
    BrightGreen                      = 102, 255, 0
    BrightRed                        = 146, 43, 62
    BrightTurquoise                  = 8, 232, 222
    BrilliantRose                    = 243, 100, 162
    BrinkPink                        = 250, 110, 121
    BritishRacingGreen               = 0, 66, 37
    Bronze                           = 205, 127, 50
    Brown                            = 165, 42, 42
    BrownPod                         = 57, 24, 2
    BuddhaGold                       = 202, 169, 6
    Buff                             = 240, 220, 130
    Burgundy                         = 128, 0, 32
    BurlyWood                        = 222, 184, 135
    BurntOrange                      = 255, 117, 56
    BurntSienna                      = 233, 116, 81
    BurntUmber                       = 138, 51, 36
    ButteredRum                      = 156, 124, 56
    CadetBlue                        = 95, 158, 160
    California                       = 224, 141, 60
    CamouflageGreen                  = 120, 134, 107
    Canary                           = 255, 255, 153
    CanCan                           = 217, 134, 149
    CannonPink                       = 145, 78, 117
    CaputMortuum                     = 89, 39, 32
    Caramel                          = 255, 213, 154
    Cararra                          = 237, 230, 214
    Cardinal                         = 179, 33, 52
    CardinGreen                      = 18, 53, 36
    CareysPink                       = 217, 152, 160
    CaribbeanGreen                   = 0, 222, 164
    Carmine                          = 175, 0, 42
    CarnationPink                    = 255, 166, 201
    CarrotOrange                     = 242, 142, 28
    Cascade                          = 141, 163, 153
    CatskillWhite                    = 226, 229, 222
    Cedar                            = 67, 48, 46
    Celadon                          = 172, 225, 175
    Celeste                          = 207, 207, 196
    Cello                            = 55, 79, 107
    Cement                           = 138, 121, 93
    Cerise                           = 222, 49, 99
    Cerulean                         = 0, 123, 167
    CeruleanBlue                     = 42, 82, 190
    Chantilly                        = 239, 187, 204
    Chardonnay                       = 255, 200, 124
    Charlotte                        = 167, 216, 222
    Charm                            = 208, 116, 139
    Chartreuse                       = 127, 255, 0
    ChartreuseYellow                 = 223, 255, 0
    ChelseaCucumber                  = 135, 169, 107
    Cherub                           = 246, 214, 222
    Chestnut                         = 185, 78, 72
    ChileanFire                      = 226, 88, 34
    Chinook                          = 150, 200, 162
    Chocolate                        = 210, 105, 30
    Christi                          = 125, 183, 0
    Christine                        = 181, 101, 30
    Cinnabar                         = 235, 76, 66
    Citron                           = 159, 169, 31
    Citrus                           = 141, 182, 0
    Claret                           = 95, 25, 51
    ClassicRose                      = 251, 204, 231
    ClayCreek                        = 145, 129, 81
    Clinker                          = 75, 54, 33
    Clover                           = 74, 93, 35
    Cobalt                           = 0, 71, 171
    CocoaBrown                       = 44, 22, 8
    Cola                             = 60, 48, 36
    ColumbiaBlue                     = 166, 231, 255
    CongoBrown                       = 103, 76, 71
    Conifer                          = 178, 236, 93
    Copper                           = 218, 138, 103
    CopperRose                       = 153, 102, 102
    Coral                            = 255, 127, 80
    CoralRed                         = 255, 64, 64
    CoralTree                        = 173, 111, 105
    Coriander                        = 188, 184, 138
    Corn                             = 251, 236, 93
    CornField                        = 250, 240, 190
    Cornflower                       = 147, 204, 234
    CornflowerBlue                   = 100, 149, 237
    Cornsilk                         = 255, 248, 220
    Cosmic                           = 132, 63, 91
    Cosmos                           = 255, 204, 203
    CostaDelSol                      = 102, 93, 30
    CottonCandy                      = 255, 188, 217
    Crail                            = 164, 90, 82
    Cranberry                        = 205, 96, 126
    Cream                            = 255, 255, 204
    CreamCan                         = 242, 198, 73
    Crimson                          = 220, 20, 60
    Crusta                           = 232, 142, 90
    Cumulus                          = 255, 255, 191
    Cupid                            = 246, 173, 198
    CuriousBlue                      = 40, 135, 200
    Cyan                             = 0, 255, 255
    Cyprus                           = 6, 78, 64
    DaisyBush                        = 85, 53, 146
    Dandelion                        = 250, 218, 94
    Danube                           = 96, 130, 182
    DarkBlue                         = 0, 0, 139
    DarkBrown                        = 101, 67, 33
    DarkCerulean                     = 8, 69, 126
    DarkChestnut                     = 152, 105, 96
    DarkCoral                        = 201, 90, 73
    DarkCyan                         = 0, 139, 139
    DarkGoldenrod                    = 184, 134, 11
    DarkGray                         = 169, 169, 169
    DarkGreen                        = 0, 100, 0
    DarkGreenCopper                  = 73, 121, 107
    DarkGrey                         = 169, 169, 169
    DarkKhaki                        = 189, 183, 107
    DarkMagenta                      = 139, 0, 139
    DarkOliveGreen                   = 85, 107, 47
    DarkOrange                       = 255, 140, 0
    DarkOrchid                       = 153, 50, 204
    DarkPastelGreen                  = 3, 192, 60
    DarkPink                         = 222, 93, 131
    DarkPurple                       = 150, 61, 127
    DarkRed                          = 139, 0, 0
    DarkSalmon                       = 233, 150, 122
    DarkSeaGreen                     = 143, 188, 143
    DarkSlateBlue                    = 72, 61, 139
    DarkSlateGray                    = 47, 79, 79
    DarkSlateGrey                    = 47, 79, 79
    DarkSpringGreen                  = 23, 114, 69
    DarkTangerine                    = 255, 170, 29
    DarkTurquoise                    = 0, 206, 209
    DarkViolet                       = 148, 0, 211
    DarkWood                         = 130, 102, 68
    DeepBlush                        = 245, 105, 145
    DeepCerise                       = 224, 33, 138
    DeepKoamaru                      = 51, 51, 102
    DeepLilac                        = 153, 85, 187
    DeepMagenta                      = 204, 0, 204
    DeepPink                         = 255, 20, 147
    DeepSea                          = 14, 124, 97
    DeepSkyBlue                      = 0, 191, 255
    DeepTeal                         = 24, 69, 59
    Denim                            = 36, 107, 206
    DesertSand                       = 237, 201, 175
    DimGray                          = 105, 105, 105
    DimGrey                          = 105, 105, 105
    DodgerBlue                       = 30, 144, 255
    Dolly                            = 242, 242, 122
    Downy                            = 95, 201, 191
    DutchWhite                       = 239, 223, 187
    EastBay                          = 76, 81, 109
    EastSide                         = 178, 132, 190
    EchoBlue                         = 169, 178, 195
    Ecru                             = 194, 178, 128
    Eggplant                         = 162, 0, 109
    EgyptianBlue                     = 16, 52, 166
    ElectricBlue                     = 125, 249, 255
    ElectricIndigo                   = 111, 0, 255
    ElectricLime                     = 208, 255, 20
    ElectricPurple                   = 191, 0, 255
    Elm                              = 47, 132, 124
    Emerald                          = 80, 200, 120
    Eminence                         = 108, 48, 130
    Endeavour                        = 46, 88, 148
    EnergyYellow                     = 245, 224, 80
    Espresso                         = 74, 44, 42
    Eucalyptus                       = 26, 162, 96
    Falcon                           = 126, 94, 96
    Fallow                           = 204, 153, 102
    FaluRed                          = 128, 24, 24
    Feldgrau                         = 77, 93, 83
    Feldspar                         = 205, 149, 117
    Fern                             = 113, 188, 120
    FernGreen                        = 79, 121, 66
    Festival                         = 236, 213, 64
    Finn                             = 97, 64, 81
    FireBrick                        = 178, 34, 34
    FireBush                         = 222, 143, 78
    FireEngineRed                    = 211, 33, 45
    Flamingo                         = 233, 92, 75
    Flax                             = 238, 220, 130
    FloralWhite                      = 255, 250, 240
    ForestGreen                      = 34, 139, 34
    Frangipani                       = 250, 214, 165
    FreeSpeechAquamarine             = 0, 168, 119
    FreeSpeechRed                    = 204, 0, 0
    FrenchLilac                      = 230, 168, 215
    FrenchRose                       = 232, 83, 149
    FriarGrey                        = 135, 134, 129
    Froly                            = 228, 113, 122
    Fuchsia                          = 255, 0, 255
    FuchsiaPink                      = 255, 119, 255
    Gainsboro                        = 220, 220, 220
    Gallery                          = 219, 215, 210
    Galliano                         = 204, 160, 29
    Gamboge                          = 204, 153, 0
    Ghost                            = 196, 195, 208
    GhostWhite                       = 248, 248, 255
    Gin                              = 216, 228, 188
    GinFizz                          = 247, 231, 206
    Givry                            = 230, 208, 171
    Glacier                          = 115, 169, 194
    Gold                             = 255, 215, 0
    GoldDrop                         = 213, 108, 43
    GoldenBrown                      = 150, 113, 23
    GoldenFizz                       = 240, 225, 48
    GoldenGlow                       = 248, 222, 126
    GoldenPoppy                      = 252, 194, 0
    Goldenrod                        = 218, 165, 32
    GoldenSand                       = 233, 214, 107
    GoldenYellow                     = 253, 238, 0
    GoldTips                         = 225, 189, 39
    GordonsGreen                     = 37, 53, 41
    Gorse                            = 255, 225, 53
    Gossamer                         = 49, 145, 119
    GrannySmithApple                 = 168, 228, 160
    Gray                             = 128, 128, 128
    GrayAsparagus                    = 70, 89, 69
    Green                            = 0, 128, 0
    GreenLeaf                        = 76, 114, 29
    GreenVogue                       = 38, 67, 72
    GreenYellow                      = 173, 255, 47
    Grey                             = 128, 128, 128
    GreyAsparagus                    = 70, 89, 69
    GuardsmanRed                     = 157, 41, 51
    GumLeaf                          = 178, 190, 181
    Gunmetal                         = 42, 52, 57
    Hacienda                         = 155, 135, 12
    HalfAndHalf                      = 232, 228, 201
    HalfBaked                        = 95, 138, 139
    HalfColonialWhite                = 246, 234, 190
    HalfPearlLusta                   = 240, 234, 214
    HanPurple                        = 63, 0, 255
    Harlequin                        = 74, 255, 0
    HarleyDavidsonOrange             = 194, 59, 34
    Heather                          = 174, 198, 207
    Heliotrope                       = 223, 115, 255
    Hemp                             = 161, 122, 116
    Highball                         = 134, 126, 54
    HippiePink                       = 171, 75, 82
    Hoki                             = 110, 127, 128
    HollywoodCerise                  = 244, 0, 161
    Honeydew                         = 240, 255, 240
    Hopbush                          = 207, 113, 175
    HorsesNeck                       = 108, 84, 30
    HotPink                          = 255, 105, 180
    HummingBird                      = 201, 255, 229
    HunterGreen                      = 53, 94, 59
    Illusion                         = 244, 152, 173
    InchWorm                         = 202, 224, 13
    IndianRed                        = 205, 92, 92
    Indigo                           = 75, 0, 130
    InternationalKleinBlue           = 0, 24, 168
    InternationalOrange              = 255, 79, 0
    IrisBlue                         = 28, 169, 201
    IrishCoffee                      = 102, 66, 40
    IronsideGrey                     = 113, 112, 110
    IslamicGreen                     = 0, 144, 0
    Ivory                            = 255, 255, 240
    Jacarta                          = 61, 50, 93
    JackoBean                        = 65, 54, 40
    JacksonsPurple                   = 46, 45, 136
    Jade                             = 0, 171, 102
    JapaneseLaurel                   = 47, 117, 50
    Jazz                             = 93, 43, 44
    JazzberryJam                     = 165, 11, 94
    JellyBean                        = 68, 121, 142
    JetStream                        = 187, 208, 201
    Jewel                            = 0, 107, 60
    Jon                              = 79, 58, 60
    JordyBlue                        = 124, 185, 232
    Jumbo                            = 132, 132, 130
    JungleGreen                      = 41, 171, 135
    KaitokeGreen                     = 30, 77, 43
    Karry                            = 255, 221, 202
    KellyGreen                       = 70, 203, 24
    Keppel                           = 93, 164, 147
    Khaki                            = 240, 230, 140
    Killarney                        = 77, 140, 87
    KingfisherDaisy                  = 85, 27, 140
    Kobi                             = 230, 143, 172
    LaPalma                          = 60, 141, 13
    LaserLemon                       = 252, 247, 94
    Laurel                           = 103, 146, 103
    Lavender                         = 230, 230, 250
    LavenderBlue                     = 204, 204, 255
    LavenderBlush                    = 255, 240, 245
    LavenderPink                     = 251, 174, 210
    LavenderRose                     = 251, 160, 227
    LawnGreen                        = 124, 252, 0
    LemonChiffon                     = 255, 250, 205
    LightBlue                        = 173, 216, 230
    LightCoral                       = 240, 128, 128
    LightCyan                        = 224, 255, 255
    LightGoldenrodYellow             = 250, 250, 210
    LightGray                        = 211, 211, 211
    LightGreen                       = 144, 238, 144
    LightGrey                        = 211, 211, 211
    LightPink                        = 255, 182, 193
    LightSalmon                      = 255, 160, 122
    LightSeaGreen                    = 32, 178, 170
    LightSkyBlue                     = 135, 206, 250
    LightSlateGray                   = 119, 136, 153
    LightSlateGrey                   = 119, 136, 153
    LightSteelBlue                   = 176, 196, 222
    LightYellow                      = 255, 255, 224
    Lilac                            = 204, 153, 204
    Lime                             = 0, 255, 0
    LimeGreen                        = 50, 205, 50
    Limerick                         = 139, 190, 27
    Linen                            = 250, 240, 230
    Lipstick                         = 159, 43, 104
    Liver                            = 83, 75, 79
    Lochinvar                        = 86, 136, 125
    Lochmara                         = 38, 97, 156
    Lola                             = 179, 158, 181
    LondonHue                        = 170, 152, 169
    Lotus                            = 124, 72, 72
    LuckyPoint                       = 29, 41, 81
    MacaroniAndCheese                = 255, 189, 136
    Madang                           = 193, 249, 162
    Madras                           = 81, 65, 0
    Magenta                          = 255, 0, 255
    MagicMint                        = 170, 240, 209
    Magnolia                         = 248, 244, 255
    Mahogany                         = 215, 59, 62
    Maire                            = 27, 24, 17
    Maize                            = 230, 190, 138
    Malachite                        = 11, 218, 81
    Malibu                           = 93, 173, 236
    Malta                            = 169, 154, 134
    Manatee                          = 140, 146, 172
    Mandalay                         = 176, 121, 57
    MandarianOrange                  = 146, 39, 36
    Mandy                            = 191, 79, 81
    Manhattan                        = 229, 170, 112
    Mantis                           = 125, 194, 66
    Manz                             = 217, 230, 80
    MardiGras                        = 48, 25, 52
    Mariner                          = 57, 86, 156
    Maroon                           = 128, 0, 0
    Matterhorn                       = 85, 85, 85
    Mauve                            = 244, 187, 255
    Mauvelous                        = 255, 145, 175
    MauveTaupe                       = 143, 89, 115
    MayaBlue                         = 119, 181, 254
    McKenzie                         = 129, 97, 60
    MediumAquamarine                 = 102, 205, 170
    MediumBlue                       = 0, 0, 205
    MediumCarmine                    = 175, 64, 53
    MediumOrchid                     = 186, 85, 211
    MediumPurple                     = 147, 112, 219
    MediumRedViolet                  = 189, 51, 164
    MediumSeaGreen                   = 60, 179, 113
    MediumSlateBlue                  = 123, 104, 238
    MediumSpringGreen                = 0, 250, 154
    MediumTurquoise                  = 72, 209, 204
    MediumVioletRed                  = 199, 21, 133
    MediumWood                       = 166, 123, 91
    Melon                            = 253, 188, 180
    Merlot                           = 112, 54, 66
    MetallicGold                     = 211, 175, 55
    Meteor                           = 184, 115, 51
    MidnightBlue                     = 25, 25, 112
    MidnightExpress                  = 0, 20, 64
    Mikado                           = 60, 52, 31
    MilanoRed                        = 168, 55, 49
    Ming                             = 54, 116, 125
    MintCream                        = 245, 255, 250
    MintGreen                        = 152, 255, 152
    Mischka                          = 168, 169, 173
    MistyRose                        = 255, 228, 225
    Moccasin                         = 255, 228, 181
    Mojo                             = 149, 69, 53
    MonaLisa                         = 255, 153, 153
    Mongoose                         = 179, 139, 109
    Montana                          = 53, 56, 57
    MoodyBlue                        = 116, 108, 192
    MoonYellow                       = 245, 199, 26
    MossGreen                        = 173, 223, 173
    MountainMeadow                   = 28, 172, 120
    MountainMist                     = 161, 157, 148
    MountbattenPink                  = 153, 122, 141
    Mulberry                         = 211, 65, 157
    Mustard                          = 255, 219, 88
    Myrtle                           = 25, 89, 5
    MySin                            = 255, 179, 71
    NavajoWhite                      = 255, 222, 173
    Navy                             = 0, 0, 128
    NavyBlue                         = 2, 71, 254
    NeonCarrot                       = 255, 153, 51
    NeonPink                         = 255, 92, 205
    Nepal                            = 145, 163, 176
    Nero                             = 20, 20, 20
    NewMidnightBlue                  = 0, 0, 156
    Niagara                          = 58, 176, 158
    NightRider                       = 59, 47, 47
    Nobel                            = 152, 152, 152
    Norway                           = 169, 186, 157
    Nugget                           = 183, 135, 39
    OceanGreen                       = 95, 167, 120
    Ochre                            = 202, 115, 9
    OldCopper                        = 111, 78, 55
    OldGold                          = 207, 181, 59
    OldLace                          = 253, 245, 230
    OldLavender                      = 121, 104, 120
    OldRose                          = 195, 33, 72
    Olive                            = 128, 128, 0
    OliveDrab                        = 107, 142, 35
    OliveGreen                       = 181, 179, 92
    Olivetone                        = 110, 110, 48
    Olivine                          = 154, 185, 115
    Onahau                           = 196, 216, 226
    Opal                             = 168, 195, 188
    Orange                           = 255, 165, 0
    OrangePeel                       = 251, 153, 2
    OrangeRed                        = 255, 69, 0
    Orchid                           = 218, 112, 214
    OuterSpace                       = 45, 56, 58
    OutrageousOrange                 = 254, 90, 29
    Oxley                            = 95, 167, 119
    PacificBlue                      = 0, 136, 220
    Padua                            = 128, 193, 151
    PalatinatePurple                 = 112, 41, 99
    PaleBrown                        = 160, 120, 90
    PaleChestnut                     = 221, 173, 175
    PaleCornflowerBlue               = 188, 212, 230
    PaleGoldenrod                    = 238, 232, 170
    PaleGreen                        = 152, 251, 152
    PaleMagenta                      = 249, 132, 239
    PalePink                         = 250, 218, 221
    PaleSlate                        = 201, 192, 187
    PaleTaupe                        = 188, 152, 126
    PaleTurquoise                    = 175, 238, 238
    PaleVioletRed                    = 219, 112, 147
    PalmLeaf                         = 53, 66, 48
    Panache                          = 233, 255, 219
    PapayaWhip                       = 255, 239, 213
    ParisDaisy                       = 255, 244, 79
    Parsley                          = 48, 96, 48
    PastelGreen                      = 119, 221, 119
    PattensBlue                      = 219, 233, 244
    Peach                            = 255, 203, 164
    PeachOrange                      = 255, 204, 153
    PeachPuff                        = 255, 218, 185
    PeachYellow                      = 250, 223, 173
    Pear                             = 209, 226, 49
    PearlLusta                       = 234, 224, 200
    Pelorous                         = 42, 143, 189
    Perano                           = 172, 172, 230
    Periwinkle                       = 197, 203, 225
    PersianBlue                      = 34, 67, 182
    PersianGreen                     = 0, 166, 147
    PersianIndigo                    = 51, 0, 102
    PersianPink                      = 247, 127, 190
    PersianRed                       = 192, 54, 44
    PersianRose                      = 233, 54, 167
    Persimmon                        = 236, 88, 0
    Peru                             = 205, 133, 63
    Pesto                            = 128, 117, 50
    PictonBlue                       = 102, 153, 204
    PigmentGreen                     = 0, 173, 67
    PigPink                          = 255, 218, 233
    PineGreen                        = 1, 121, 111
    PineTree                         = 42, 47, 35
    Pink                             = 255, 192, 203
    PinkFlare                        = 191, 175, 178
    PinkLace                         = 240, 211, 220
    PinkSwan                         = 179, 179, 179
    Plum                             = 221, 160, 221
    Pohutukawa                       = 102, 12, 33
    PoloBlue                         = 119, 158, 203
    Pompadour                        = 129, 20, 83
    Portage                          = 146, 161, 207
    PotPourri                        = 241, 221, 207
    PottersClay                      = 132, 86, 60
    PowderBlue                       = 176, 224, 230
    Prim                             = 228, 196, 207
    PrussianBlue                     = 0, 58, 108
    PsychedelicPurple                = 223, 0, 255
    Puce                             = 204, 136, 153
    Pueblo                           = 108, 46, 31
    PuertoRico                       = 67, 179, 174
    Pumpkin                          = 255, 99, 28
    Purple                           = 128, 0, 128
    PurpleMountainsMajesty           = 150, 123, 182
    PurpleTaupe                      = 93, 57, 84
    QuarterSpanishWhite              = 230, 224, 212
    Quartz                           = 220, 208, 255
    Quincy                           = 106, 84, 69
    RacingGreen                      = 26, 36, 33
    RadicalRed                       = 255, 32, 82
    Rajah                            = 251, 171, 96
    RawUmber                         = 123, 63, 0
    RazzleDazzleRose                 = 254, 78, 218
    Razzmatazz                       = 215, 10, 83
    Red                              = 255, 0, 0
    RedBerry                         = 132, 22, 23
    RedDamask                        = 203, 109, 81
    RedOxide                         = 99, 15, 15
    RedRobin                         = 128, 64, 64
    RichBlue                         = 84, 90, 167
    Riptide                          = 141, 217, 204
    RobinsEggBlue                    = 0, 204, 204
    RobRoy                           = 225, 169, 95
    RockSpray                        = 171, 56, 31
    RomanCoffee                      = 131, 105, 83
    RoseBud                          = 246, 164, 148
    RoseBudCherry                    = 135, 50, 96
    RoseTaupe                        = 144, 93, 93
    RosyBrown                        = 188, 143, 143
    Rouge                            = 176, 48, 96
    RoyalBlue                        = 65, 105, 225
    RoyalHeath                       = 168, 81, 110
    RoyalPurple                      = 102, 51, 152
    Ruby                             = 215, 24, 104
    Russet                           = 128, 70, 27
    Rust                             = 192, 64, 0
    RusticRed                        = 72, 6, 7
    Saddle                           = 99, 81, 71
    SaddleBrown                      = 139, 69, 19
    SafetyOrange                     = 255, 102, 0
    Saffron                          = 244, 196, 48
    Sage                             = 143, 151, 121
    Sail                             = 161, 202, 241
    Salem                            = 0, 133, 67
    Salmon                           = 250, 128, 114
    SandyBeach                       = 253, 213, 177
    SandyBrown                       = 244, 164, 96
    Sangria                          = 134, 1, 17
    SanguineBrown                    = 115, 54, 53
    SanMarino                        = 80, 114, 167
    SanteFe                          = 175, 110, 77
    Sapphire                         = 6, 42, 120
    Saratoga                         = 84, 90, 44
    Scampi                           = 102, 102, 153
    Scarlet                          = 255, 36, 0
    ScarletGum                       = 67, 28, 83
    SchoolBusYellow                  = 255, 216, 0
    Schooner                         = 139, 134, 128
    ScreaminGreen                    = 102, 255, 102
    Scrub                            = 59, 60, 54
    SeaBuckthorn                     = 249, 146, 69
    SeaGreen                         = 46, 139, 87
    Seagull                          = 140, 190, 214
    SealBrown                        = 61, 12, 2
    Seance                           = 96, 47, 107
    SeaPink                          = 215, 131, 127
    SeaShell                         = 255, 245, 238
    Selago                           = 250, 230, 250
    SelectiveYellow                  = 242, 180, 0
    SemiSweetChocolate               = 107, 68, 35
    Sepia                            = 150, 90, 62
    Serenade                         = 255, 233, 209
    Shadow                           = 133, 109, 77
    Shakespeare                      = 114, 160, 193
    Shalimar                         = 252, 255, 164
    Shamrock                         = 68, 215, 168
    ShamrockGreen                    = 0, 153, 102
    SherpaBlue                       = 0, 75, 73
    SherwoodGreen                    = 27, 77, 62
    Shilo                            = 222, 165, 164
    ShipCove                         = 119, 139, 165
    Shocking                         = 241, 156, 187
    ShockingPink                     = 255, 29, 206
    ShuttleGrey                      = 84, 98, 111
    Sidecar                          = 238, 224, 177
    Sienna                           = 160, 82, 45
    Silk                             = 190, 164, 147
    Silver                           = 192, 192, 192
    SilverChalice                    = 175, 177, 174
    SilverTree                       = 102, 201, 146
    SkyBlue                          = 135, 206, 235
    SlateBlue                        = 106, 90, 205
    SlateGray                        = 112, 128, 144
    SlateGrey                        = 112, 128, 144
    Smalt                            = 0, 48, 143
    SmaltBlue                        = 74, 100, 108
    Snow                             = 255, 250, 250
    SoftAmber                        = 209, 190, 168
    Solitude                         = 235, 236, 240
    Sorbus                           = 233, 105, 44
    Spectra                          = 53, 101, 77
    SpicyMix                         = 136, 101, 78
    Spray                            = 126, 212, 230
    SpringBud                        = 150, 255, 0
    SpringGreen                      = 0, 255, 127
    SpringSun                        = 236, 235, 189
    SpunPearl                        = 170, 169, 173
    Stack                            = 130, 142, 132
    SteelBlue                        = 70, 130, 180
    Stiletto                         = 137, 63, 69
    Strikemaster                     = 145, 92, 131
    StTropaz                         = 50, 82, 123
    Studio                           = 115, 79, 150
    Sulu                             = 201, 220, 135
    SummerSky                        = 33, 171, 205
    Sun                              = 237, 135, 45
    Sundance                         = 197, 179, 88
    Sunflower                        = 228, 208, 10
    Sunglow                          = 255, 204, 51
    SunsetOrange                     = 253, 82, 64
    SurfieGreen                      = 0, 116, 116
    Sushi                            = 111, 153, 64
    SuvaGrey                         = 140, 140, 140
    Swamp                            = 35, 43, 43
    SweetCorn                        = 253, 219, 109
    SweetPink                        = 243, 153, 152
    Tacao                            = 236, 177, 118
    TahitiGold                       = 235, 97, 35
    Tan                              = 210, 180, 140
    Tangaroa                         = 0, 28, 61
    Tangerine                        = 228, 132, 0
    TangerineYellow                  = 253, 204, 13
    Tapestry                         = 183, 110, 121
    Taupe                            = 72, 60, 50
    TaupeGrey                        = 139, 133, 137
    TawnyPort                        = 102, 66, 77
    TaxBreak                         = 79, 102, 106
    TeaGreen                         = 208, 240, 192
    Teak                             = 176, 141, 87
    Teal                             = 0, 128, 128
    TeaRose                          = 255, 133, 207
    Temptress                        = 60, 20, 33
    Tenne                            = 200, 101, 0
    TerraCotta                       = 226, 114, 91
    Thistle                          = 216, 191, 216
    TickleMePink                     = 245, 111, 161
    Tidal                            = 232, 244, 140
    TitanWhite                       = 214, 202, 221
    Toast                            = 165, 113, 100
    Tomato                           = 255, 99, 71
    TorchRed                         = 255, 3, 62
    ToryBlue                         = 54, 81, 148
    Tradewind                        = 110, 174, 161
    TrendyPink                       = 133, 96, 136
    TropicalRainForest               = 0, 127, 102
    TrueV                            = 139, 114, 190
    TulipTree                        = 229, 183, 59
    Tumbleweed                       = 222, 170, 136
    Turbo                            = 255, 195, 36
    TurkishRose                      = 152, 119, 123
    Turquoise                        = 64, 224, 208
    TurquoiseBlue                    = 118, 215, 234
    Tuscany                          = 175, 89, 62
    TwilightBlue                     = 253, 255, 245
    Twine                            = 186, 135, 89
    TyrianPurple                     = 102, 2, 60
    Ultramarine                      = 10, 17, 149
    UltraPink                        = 255, 111, 255
    Valencia                         = 222, 82, 70
    VanCleef                         = 84, 61, 55
    VanillaIce                       = 229, 204, 201
    VenetianRed                      = 209, 0, 28
    Venus                            = 138, 127, 128
    Vermilion                        = 251, 79, 20
    VeryLightGrey                    = 207, 207, 207
    VidaLoca                         = 94, 140, 49
    Viking                           = 71, 171, 204
    Viola                            = 180, 131, 149
    ViolentViolet                    = 50, 23, 77
    Violet                           = 238, 130, 238
    VioletRed                        = 255, 57, 136
    Viridian                         = 64, 130, 109
    VistaBlue                        = 159, 226, 191
    VividViolet                      = 127, 62, 152
    WaikawaGrey                      = 83, 104, 149
    Wasabi                           = 150, 165, 60
    Watercourse                      = 0, 106, 78
    Wedgewood                        = 67, 107, 149
    WellRead                         = 147, 61, 65
    Wewak                            = 255, 152, 153
    Wheat                            = 245, 222, 179
    Whiskey                          = 217, 154, 108
    WhiskeySour                      = 217, 144, 88
    White                            = 255, 255, 255
    WhiteSmoke                       = 245, 245, 245
    WildRice                         = 228, 217, 111
    WildSand                         = 229, 228, 226
    WildStrawberry                   = 252, 65, 154
    WildWatermelon                   = 255, 84, 112
    WildWillow                       = 172, 191, 96
    Windsor                          = 76, 40, 130
    Wisteria                         = 191, 148, 228
    Wistful                          = 162, 162, 208
    Yellow                           = 255, 255, 0
    YellowGreen                      = 154, 205, 50
    YellowOrange                     = 255, 174, 66
    YourPink                         = 244, 194, 194
}
$Script:RGBColors = [ordered] @{None = $null
    AirForceBlue                     = 93, 138, 168
    Akaroa                           = 195, 176, 145
    AlbescentWhite                   = 227, 218, 201
    AliceBlue                        = 240, 248, 255
    Alizarin                         = 227, 38, 54
    Allports                         = 18, 97, 128
    Almond                           = 239, 222, 205
    AlmondFrost                      = 159, 129, 112
    Amaranth                         = 229, 43, 80
    Amazon                           = 59, 122, 87
    Amber                            = 255, 191, 0
    Amethyst                         = 153, 102, 204
    AmethystSmoke                    = 156, 138, 164
    AntiqueWhite                     = 250, 235, 215
    Apple                            = 102, 180, 71
    AppleBlossom                     = 176, 92, 82
    Apricot                          = 251, 206, 177
    Aqua                             = 0, 255, 255
    Aquamarine                       = 127, 255, 212
    Armygreen                        = 75, 83, 32
    Arsenic                          = 59, 68, 75
    Astral                           = 54, 117, 136
    Atlantis                         = 164, 198, 57
    Atomic                           = 65, 74, 76
    AtomicTangerine                  = 255, 153, 102
    Axolotl                          = 99, 119, 91
    Azure                            = 240, 255, 255
    Bahia                            = 176, 191, 26
    BakersChocolate                  = 93, 58, 26
    BaliHai                          = 124, 152, 171
    BananaMania                      = 250, 231, 181
    BattleshipGrey                   = 85, 93, 80
    BayOfMany                        = 35, 48, 103
    Beige                            = 245, 245, 220
    Bermuda                          = 136, 216, 192
    Bilbao                           = 42, 128, 0
    BilobaFlower                     = 181, 126, 220
    Bismark                          = 83, 104, 114
    Bisque                           = 255, 228, 196
    Bistre                           = 61, 43, 31
    Bittersweet                      = 254, 111, 94
    Black                            = 0, 0, 0
    BlackPearl                       = 31, 38, 42
    BlackRose                        = 85, 31, 47
    BlackRussian                     = 23, 24, 43
    BlanchedAlmond                   = 255, 235, 205
    BlizzardBlue                     = 172, 229, 238
    Blue                             = 0, 0, 255
    BlueDiamond                      = 77, 26, 127
    BlueMarguerite                   = 115, 102, 189
    BlueSmoke                        = 115, 130, 118
    BlueViolet                       = 138, 43, 226
    Blush                            = 169, 92, 104
    BokaraGrey                       = 22, 17, 13
    Bole                             = 121, 68, 59
    BondiBlue                        = 0, 147, 175
    Bordeaux                         = 88, 17, 26
    Bossanova                        = 86, 60, 92
    Boulder                          = 114, 116, 114
    Bouquet                          = 183, 132, 167
    Bourbon                          = 170, 108, 57
    Brass                            = 181, 166, 66
    BrickRed                         = 199, 44, 72
    BrightGreen                      = 102, 255, 0
    BrightRed                        = 146, 43, 62
    BrightTurquoise                  = 8, 232, 222
    BrilliantRose                    = 243, 100, 162
    BrinkPink                        = 250, 110, 121
    BritishRacingGreen               = 0, 66, 37
    Bronze                           = 205, 127, 50
    Brown                            = 165, 42, 42
    BrownPod                         = 57, 24, 2
    BuddhaGold                       = 202, 169, 6
    Buff                             = 240, 220, 130
    Burgundy                         = 128, 0, 32
    BurlyWood                        = 222, 184, 135
    BurntOrange                      = 255, 117, 56
    BurntSienna                      = 233, 116, 81
    BurntUmber                       = 138, 51, 36
    ButteredRum                      = 156, 124, 56
    CadetBlue                        = 95, 158, 160
    California                       = 224, 141, 60
    CamouflageGreen                  = 120, 134, 107
    Canary                           = 255, 255, 153
    CanCan                           = 217, 134, 149
    CannonPink                       = 145, 78, 117
    CaputMortuum                     = 89, 39, 32
    Caramel                          = 255, 213, 154
    Cararra                          = 237, 230, 214
    Cardinal                         = 179, 33, 52
    CardinGreen                      = 18, 53, 36
    CareysPink                       = 217, 152, 160
    CaribbeanGreen                   = 0, 222, 164
    Carmine                          = 175, 0, 42
    CarnationPink                    = 255, 166, 201
    CarrotOrange                     = 242, 142, 28
    Cascade                          = 141, 163, 153
    CatskillWhite                    = 226, 229, 222
    Cedar                            = 67, 48, 46
    Celadon                          = 172, 225, 175
    Celeste                          = 207, 207, 196
    Cello                            = 55, 79, 107
    Cement                           = 138, 121, 93
    Cerise                           = 222, 49, 99
    Cerulean                         = 0, 123, 167
    CeruleanBlue                     = 42, 82, 190
    Chantilly                        = 239, 187, 204
    Chardonnay                       = 255, 200, 124
    Charlotte                        = 167, 216, 222
    Charm                            = 208, 116, 139
    Chartreuse                       = 127, 255, 0
    ChartreuseYellow                 = 223, 255, 0
    ChelseaCucumber                  = 135, 169, 107
    Cherub                           = 246, 214, 222
    Chestnut                         = 185, 78, 72
    ChileanFire                      = 226, 88, 34
    Chinook                          = 150, 200, 162
    Chocolate                        = 210, 105, 30
    Christi                          = 125, 183, 0
    Christine                        = 181, 101, 30
    Cinnabar                         = 235, 76, 66
    Citron                           = 159, 169, 31
    Citrus                           = 141, 182, 0
    Claret                           = 95, 25, 51
    ClassicRose                      = 251, 204, 231
    ClayCreek                        = 145, 129, 81
    Clinker                          = 75, 54, 33
    Clover                           = 74, 93, 35
    Cobalt                           = 0, 71, 171
    CocoaBrown                       = 44, 22, 8
    Cola                             = 60, 48, 36
    ColumbiaBlue                     = 166, 231, 255
    CongoBrown                       = 103, 76, 71
    Conifer                          = 178, 236, 93
    Copper                           = 218, 138, 103
    CopperRose                       = 153, 102, 102
    Coral                            = 255, 127, 80
    CoralRed                         = 255, 64, 64
    CoralTree                        = 173, 111, 105
    Coriander                        = 188, 184, 138
    Corn                             = 251, 236, 93
    CornField                        = 250, 240, 190
    Cornflower                       = 147, 204, 234
    CornflowerBlue                   = 100, 149, 237
    Cornsilk                         = 255, 248, 220
    Cosmic                           = 132, 63, 91
    Cosmos                           = 255, 204, 203
    CostaDelSol                      = 102, 93, 30
    CottonCandy                      = 255, 188, 217
    Crail                            = 164, 90, 82
    Cranberry                        = 205, 96, 126
    Cream                            = 255, 255, 204
    CreamCan                         = 242, 198, 73
    Crimson                          = 220, 20, 60
    Crusta                           = 232, 142, 90
    Cumulus                          = 255, 255, 191
    Cupid                            = 246, 173, 198
    CuriousBlue                      = 40, 135, 200
    Cyan                             = 0, 255, 255
    Cyprus                           = 6, 78, 64
    DaisyBush                        = 85, 53, 146
    Dandelion                        = 250, 218, 94
    Danube                           = 96, 130, 182
    DarkBlue                         = 0, 0, 139
    DarkBrown                        = 101, 67, 33
    DarkCerulean                     = 8, 69, 126
    DarkChestnut                     = 152, 105, 96
    DarkCoral                        = 201, 90, 73
    DarkCyan                         = 0, 139, 139
    DarkGoldenrod                    = 184, 134, 11
    DarkGray                         = 169, 169, 169
    DarkGreen                        = 0, 100, 0
    DarkGreenCopper                  = 73, 121, 107
    DarkGrey                         = 169, 169, 169
    DarkKhaki                        = 189, 183, 107
    DarkMagenta                      = 139, 0, 139
    DarkOliveGreen                   = 85, 107, 47
    DarkOrange                       = 255, 140, 0
    DarkOrchid                       = 153, 50, 204
    DarkPastelGreen                  = 3, 192, 60
    DarkPink                         = 222, 93, 131
    DarkPurple                       = 150, 61, 127
    DarkRed                          = 139, 0, 0
    DarkSalmon                       = 233, 150, 122
    DarkSeaGreen                     = 143, 188, 143
    DarkSlateBlue                    = 72, 61, 139
    DarkSlateGray                    = 47, 79, 79
    DarkSlateGrey                    = 47, 79, 79
    DarkSpringGreen                  = 23, 114, 69
    DarkTangerine                    = 255, 170, 29
    DarkTurquoise                    = 0, 206, 209
    DarkViolet                       = 148, 0, 211
    DarkWood                         = 130, 102, 68
    DeepBlush                        = 245, 105, 145
    DeepCerise                       = 224, 33, 138
    DeepKoamaru                      = 51, 51, 102
    DeepLilac                        = 153, 85, 187
    DeepMagenta                      = 204, 0, 204
    DeepPink                         = 255, 20, 147
    DeepSea                          = 14, 124, 97
    DeepSkyBlue                      = 0, 191, 255
    DeepTeal                         = 24, 69, 59
    Denim                            = 36, 107, 206
    DesertSand                       = 237, 201, 175
    DimGray                          = 105, 105, 105
    DimGrey                          = 105, 105, 105
    DodgerBlue                       = 30, 144, 255
    Dolly                            = 242, 242, 122
    Downy                            = 95, 201, 191
    DutchWhite                       = 239, 223, 187
    EastBay                          = 76, 81, 109
    EastSide                         = 178, 132, 190
    EchoBlue                         = 169, 178, 195
    Ecru                             = 194, 178, 128
    Eggplant                         = 162, 0, 109
    EgyptianBlue                     = 16, 52, 166
    ElectricBlue                     = 125, 249, 255
    ElectricIndigo                   = 111, 0, 255
    ElectricLime                     = 208, 255, 20
    ElectricPurple                   = 191, 0, 255
    Elm                              = 47, 132, 124
    Emerald                          = 80, 200, 120
    Eminence                         = 108, 48, 130
    Endeavour                        = 46, 88, 148
    EnergyYellow                     = 245, 224, 80
    Espresso                         = 74, 44, 42
    Eucalyptus                       = 26, 162, 96
    Falcon                           = 126, 94, 96
    Fallow                           = 204, 153, 102
    FaluRed                          = 128, 24, 24
    Feldgrau                         = 77, 93, 83
    Feldspar                         = 205, 149, 117
    Fern                             = 113, 188, 120
    FernGreen                        = 79, 121, 66
    Festival                         = 236, 213, 64
    Finn                             = 97, 64, 81
    FireBrick                        = 178, 34, 34
    FireBush                         = 222, 143, 78
    FireEngineRed                    = 211, 33, 45
    Flamingo                         = 233, 92, 75
    Flax                             = 238, 220, 130
    FloralWhite                      = 255, 250, 240
    ForestGreen                      = 34, 139, 34
    Frangipani                       = 250, 214, 165
    FreeSpeechAquamarine             = 0, 168, 119
    FreeSpeechRed                    = 204, 0, 0
    FrenchLilac                      = 230, 168, 215
    FrenchRose                       = 232, 83, 149
    FriarGrey                        = 135, 134, 129
    Froly                            = 228, 113, 122
    Fuchsia                          = 255, 0, 255
    FuchsiaPink                      = 255, 119, 255
    Gainsboro                        = 220, 220, 220
    Gallery                          = 219, 215, 210
    Galliano                         = 204, 160, 29
    Gamboge                          = 204, 153, 0
    Ghost                            = 196, 195, 208
    GhostWhite                       = 248, 248, 255
    Gin                              = 216, 228, 188
    GinFizz                          = 247, 231, 206
    Givry                            = 230, 208, 171
    Glacier                          = 115, 169, 194
    Gold                             = 255, 215, 0
    GoldDrop                         = 213, 108, 43
    GoldenBrown                      = 150, 113, 23
    GoldenFizz                       = 240, 225, 48
    GoldenGlow                       = 248, 222, 126
    GoldenPoppy                      = 252, 194, 0
    Goldenrod                        = 218, 165, 32
    GoldenSand                       = 233, 214, 107
    GoldenYellow                     = 253, 238, 0
    GoldTips                         = 225, 189, 39
    GordonsGreen                     = 37, 53, 41
    Gorse                            = 255, 225, 53
    Gossamer                         = 49, 145, 119
    GrannySmithApple                 = 168, 228, 160
    Gray                             = 128, 128, 128
    GrayAsparagus                    = 70, 89, 69
    Green                            = 0, 128, 0
    GreenLeaf                        = 76, 114, 29
    GreenVogue                       = 38, 67, 72
    GreenYellow                      = 173, 255, 47
    Grey                             = 128, 128, 128
    GreyAsparagus                    = 70, 89, 69
    GuardsmanRed                     = 157, 41, 51
    GumLeaf                          = 178, 190, 181
    Gunmetal                         = 42, 52, 57
    Hacienda                         = 155, 135, 12
    HalfAndHalf                      = 232, 228, 201
    HalfBaked                        = 95, 138, 139
    HalfColonialWhite                = 246, 234, 190
    HalfPearlLusta                   = 240, 234, 214
    HanPurple                        = 63, 0, 255
    Harlequin                        = 74, 255, 0
    HarleyDavidsonOrange             = 194, 59, 34
    Heather                          = 174, 198, 207
    Heliotrope                       = 223, 115, 255
    Hemp                             = 161, 122, 116
    Highball                         = 134, 126, 54
    HippiePink                       = 171, 75, 82
    Hoki                             = 110, 127, 128
    HollywoodCerise                  = 244, 0, 161
    Honeydew                         = 240, 255, 240
    Hopbush                          = 207, 113, 175
    HorsesNeck                       = 108, 84, 30
    HotPink                          = 255, 105, 180
    HummingBird                      = 201, 255, 229
    HunterGreen                      = 53, 94, 59
    Illusion                         = 244, 152, 173
    InchWorm                         = 202, 224, 13
    IndianRed                        = 205, 92, 92
    Indigo                           = 75, 0, 130
    InternationalKleinBlue           = 0, 24, 168
    InternationalOrange              = 255, 79, 0
    IrisBlue                         = 28, 169, 201
    IrishCoffee                      = 102, 66, 40
    IronsideGrey                     = 113, 112, 110
    IslamicGreen                     = 0, 144, 0
    Ivory                            = 255, 255, 240
    Jacarta                          = 61, 50, 93
    JackoBean                        = 65, 54, 40
    JacksonsPurple                   = 46, 45, 136
    Jade                             = 0, 171, 102
    JapaneseLaurel                   = 47, 117, 50
    Jazz                             = 93, 43, 44
    JazzberryJam                     = 165, 11, 94
    JellyBean                        = 68, 121, 142
    JetStream                        = 187, 208, 201
    Jewel                            = 0, 107, 60
    Jon                              = 79, 58, 60
    JordyBlue                        = 124, 185, 232
    Jumbo                            = 132, 132, 130
    JungleGreen                      = 41, 171, 135
    KaitokeGreen                     = 30, 77, 43
    Karry                            = 255, 221, 202
    KellyGreen                       = 70, 203, 24
    Keppel                           = 93, 164, 147
    Khaki                            = 240, 230, 140
    Killarney                        = 77, 140, 87
    KingfisherDaisy                  = 85, 27, 140
    Kobi                             = 230, 143, 172
    LaPalma                          = 60, 141, 13
    LaserLemon                       = 252, 247, 94
    Laurel                           = 103, 146, 103
    Lavender                         = 230, 230, 250
    LavenderBlue                     = 204, 204, 255
    LavenderBlush                    = 255, 240, 245
    LavenderPink                     = 251, 174, 210
    LavenderRose                     = 251, 160, 227
    LawnGreen                        = 124, 252, 0
    LemonChiffon                     = 255, 250, 205
    LightBlue                        = 173, 216, 230
    LightCoral                       = 240, 128, 128
    LightCyan                        = 224, 255, 255
    LightGoldenrodYellow             = 250, 250, 210
    LightGray                        = 211, 211, 211
    LightGreen                       = 144, 238, 144
    LightGrey                        = 211, 211, 211
    LightPink                        = 255, 182, 193
    LightSalmon                      = 255, 160, 122
    LightSeaGreen                    = 32, 178, 170
    LightSkyBlue                     = 135, 206, 250
    LightSlateGray                   = 119, 136, 153
    LightSlateGrey                   = 119, 136, 153
    LightSteelBlue                   = 176, 196, 222
    LightYellow                      = 255, 255, 224
    Lilac                            = 204, 153, 204
    Lime                             = 0, 255, 0
    LimeGreen                        = 50, 205, 50
    Limerick                         = 139, 190, 27
    Linen                            = 250, 240, 230
    Lipstick                         = 159, 43, 104
    Liver                            = 83, 75, 79
    Lochinvar                        = 86, 136, 125
    Lochmara                         = 38, 97, 156
    Lola                             = 179, 158, 181
    LondonHue                        = 170, 152, 169
    Lotus                            = 124, 72, 72
    LuckyPoint                       = 29, 41, 81
    MacaroniAndCheese                = 255, 189, 136
    Madang                           = 193, 249, 162
    Madras                           = 81, 65, 0
    Magenta                          = 255, 0, 255
    MagicMint                        = 170, 240, 209
    Magnolia                         = 248, 244, 255
    Mahogany                         = 215, 59, 62
    Maire                            = 27, 24, 17
    Maize                            = 230, 190, 138
    Malachite                        = 11, 218, 81
    Malibu                           = 93, 173, 236
    Malta                            = 169, 154, 134
    Manatee                          = 140, 146, 172
    Mandalay                         = 176, 121, 57
    MandarianOrange                  = 146, 39, 36
    Mandy                            = 191, 79, 81
    Manhattan                        = 229, 170, 112
    Mantis                           = 125, 194, 66
    Manz                             = 217, 230, 80
    MardiGras                        = 48, 25, 52
    Mariner                          = 57, 86, 156
    Maroon                           = 128, 0, 0
    Matterhorn                       = 85, 85, 85
    Mauve                            = 244, 187, 255
    Mauvelous                        = 255, 145, 175
    MauveTaupe                       = 143, 89, 115
    MayaBlue                         = 119, 181, 254
    McKenzie                         = 129, 97, 60
    MediumAquamarine                 = 102, 205, 170
    MediumBlue                       = 0, 0, 205
    MediumCarmine                    = 175, 64, 53
    MediumOrchid                     = 186, 85, 211
    MediumPurple                     = 147, 112, 219
    MediumRedViolet                  = 189, 51, 164
    MediumSeaGreen                   = 60, 179, 113
    MediumSlateBlue                  = 123, 104, 238
    MediumSpringGreen                = 0, 250, 154
    MediumTurquoise                  = 72, 209, 204
    MediumVioletRed                  = 199, 21, 133
    MediumWood                       = 166, 123, 91
    Melon                            = 253, 188, 180
    Merlot                           = 112, 54, 66
    MetallicGold                     = 211, 175, 55
    Meteor                           = 184, 115, 51
    MidnightBlue                     = 25, 25, 112
    MidnightExpress                  = 0, 20, 64
    Mikado                           = 60, 52, 31
    MilanoRed                        = 168, 55, 49
    Ming                             = 54, 116, 125
    MintCream                        = 245, 255, 250
    MintGreen                        = 152, 255, 152
    Mischka                          = 168, 169, 173
    MistyRose                        = 255, 228, 225
    Moccasin                         = 255, 228, 181
    Mojo                             = 149, 69, 53
    MonaLisa                         = 255, 153, 153
    Mongoose                         = 179, 139, 109
    Montana                          = 53, 56, 57
    MoodyBlue                        = 116, 108, 192
    MoonYellow                       = 245, 199, 26
    MossGreen                        = 173, 223, 173
    MountainMeadow                   = 28, 172, 120
    MountainMist                     = 161, 157, 148
    MountbattenPink                  = 153, 122, 141
    Mulberry                         = 211, 65, 157
    Mustard                          = 255, 219, 88
    Myrtle                           = 25, 89, 5
    MySin                            = 255, 179, 71
    NavajoWhite                      = 255, 222, 173
    Navy                             = 0, 0, 128
    NavyBlue                         = 2, 71, 254
    NeonCarrot                       = 255, 153, 51
    NeonPink                         = 255, 92, 205
    Nepal                            = 145, 163, 176
    Nero                             = 20, 20, 20
    NewMidnightBlue                  = 0, 0, 156
    Niagara                          = 58, 176, 158
    NightRider                       = 59, 47, 47
    Nobel                            = 152, 152, 152
    Norway                           = 169, 186, 157
    Nugget                           = 183, 135, 39
    OceanGreen                       = 95, 167, 120
    Ochre                            = 202, 115, 9
    OldCopper                        = 111, 78, 55
    OldGold                          = 207, 181, 59
    OldLace                          = 253, 245, 230
    OldLavender                      = 121, 104, 120
    OldRose                          = 195, 33, 72
    Olive                            = 128, 128, 0
    OliveDrab                        = 107, 142, 35
    OliveGreen                       = 181, 179, 92
    Olivetone                        = 110, 110, 48
    Olivine                          = 154, 185, 115
    Onahau                           = 196, 216, 226
    Opal                             = 168, 195, 188
    Orange                           = 255, 165, 0
    OrangePeel                       = 251, 153, 2
    OrangeRed                        = 255, 69, 0
    Orchid                           = 218, 112, 214
    OuterSpace                       = 45, 56, 58
    OutrageousOrange                 = 254, 90, 29
    Oxley                            = 95, 167, 119
    PacificBlue                      = 0, 136, 220
    Padua                            = 128, 193, 151
    PalatinatePurple                 = 112, 41, 99
    PaleBrown                        = 160, 120, 90
    PaleChestnut                     = 221, 173, 175
    PaleCornflowerBlue               = 188, 212, 230
    PaleGoldenrod                    = 238, 232, 170
    PaleGreen                        = 152, 251, 152
    PaleMagenta                      = 249, 132, 239
    PalePink                         = 250, 218, 221
    PaleSlate                        = 201, 192, 187
    PaleTaupe                        = 188, 152, 126
    PaleTurquoise                    = 175, 238, 238
    PaleVioletRed                    = 219, 112, 147
    PalmLeaf                         = 53, 66, 48
    Panache                          = 233, 255, 219
    PapayaWhip                       = 255, 239, 213
    ParisDaisy                       = 255, 244, 79
    Parsley                          = 48, 96, 48
    PastelGreen                      = 119, 221, 119
    PattensBlue                      = 219, 233, 244
    Peach                            = 255, 203, 164
    PeachOrange                      = 255, 204, 153
    PeachPuff                        = 255, 218, 185
    PeachYellow                      = 250, 223, 173
    Pear                             = 209, 226, 49
    PearlLusta                       = 234, 224, 200
    Pelorous                         = 42, 143, 189
    Perano                           = 172, 172, 230
    Periwinkle                       = 197, 203, 225
    PersianBlue                      = 34, 67, 182
    PersianGreen                     = 0, 166, 147
    PersianIndigo                    = 51, 0, 102
    PersianPink                      = 247, 127, 190
    PersianRed                       = 192, 54, 44
    PersianRose                      = 233, 54, 167
    Persimmon                        = 236, 88, 0
    Peru                             = 205, 133, 63
    Pesto                            = 128, 117, 50
    PictonBlue                       = 102, 153, 204
    PigmentGreen                     = 0, 173, 67
    PigPink                          = 255, 218, 233
    PineGreen                        = 1, 121, 111
    PineTree                         = 42, 47, 35
    Pink                             = 255, 192, 203
    PinkFlare                        = 191, 175, 178
    PinkLace                         = 240, 211, 220
    PinkSwan                         = 179, 179, 179
    Plum                             = 221, 160, 221
    Pohutukawa                       = 102, 12, 33
    PoloBlue                         = 119, 158, 203
    Pompadour                        = 129, 20, 83
    Portage                          = 146, 161, 207
    PotPourri                        = 241, 221, 207
    PottersClay                      = 132, 86, 60
    PowderBlue                       = 176, 224, 230
    Prim                             = 228, 196, 207
    PrussianBlue                     = 0, 58, 108
    PsychedelicPurple                = 223, 0, 255
    Puce                             = 204, 136, 153
    Pueblo                           = 108, 46, 31
    PuertoRico                       = 67, 179, 174
    Pumpkin                          = 255, 99, 28
    Purple                           = 128, 0, 128
    PurpleMountainsMajesty           = 150, 123, 182
    PurpleTaupe                      = 93, 57, 84
    QuarterSpanishWhite              = 230, 224, 212
    Quartz                           = 220, 208, 255
    Quincy                           = 106, 84, 69
    RacingGreen                      = 26, 36, 33
    RadicalRed                       = 255, 32, 82
    Rajah                            = 251, 171, 96
    RawUmber                         = 123, 63, 0
    RazzleDazzleRose                 = 254, 78, 218
    Razzmatazz                       = 215, 10, 83
    Red                              = 255, 0, 0
    RedBerry                         = 132, 22, 23
    RedDamask                        = 203, 109, 81
    RedOxide                         = 99, 15, 15
    RedRobin                         = 128, 64, 64
    RichBlue                         = 84, 90, 167
    Riptide                          = 141, 217, 204
    RobinsEggBlue                    = 0, 204, 204
    RobRoy                           = 225, 169, 95
    RockSpray                        = 171, 56, 31
    RomanCoffee                      = 131, 105, 83
    RoseBud                          = 246, 164, 148
    RoseBudCherry                    = 135, 50, 96
    RoseTaupe                        = 144, 93, 93
    RosyBrown                        = 188, 143, 143
    Rouge                            = 176, 48, 96
    RoyalBlue                        = 65, 105, 225
    RoyalHeath                       = 168, 81, 110
    RoyalPurple                      = 102, 51, 152
    Ruby                             = 215, 24, 104
    Russet                           = 128, 70, 27
    Rust                             = 192, 64, 0
    RusticRed                        = 72, 6, 7
    Saddle                           = 99, 81, 71
    SaddleBrown                      = 139, 69, 19
    SafetyOrange                     = 255, 102, 0
    Saffron                          = 244, 196, 48
    Sage                             = 143, 151, 121
    Sail                             = 161, 202, 241
    Salem                            = 0, 133, 67
    Salmon                           = 250, 128, 114
    SandyBeach                       = 253, 213, 177
    SandyBrown                       = 244, 164, 96
    Sangria                          = 134, 1, 17
    SanguineBrown                    = 115, 54, 53
    SanMarino                        = 80, 114, 167
    SanteFe                          = 175, 110, 77
    Sapphire                         = 6, 42, 120
    Saratoga                         = 84, 90, 44
    Scampi                           = 102, 102, 153
    Scarlet                          = 255, 36, 0
    ScarletGum                       = 67, 28, 83
    SchoolBusYellow                  = 255, 216, 0
    Schooner                         = 139, 134, 128
    ScreaminGreen                    = 102, 255, 102
    Scrub                            = 59, 60, 54
    SeaBuckthorn                     = 249, 146, 69
    SeaGreen                         = 46, 139, 87
    Seagull                          = 140, 190, 214
    SealBrown                        = 61, 12, 2
    Seance                           = 96, 47, 107
    SeaPink                          = 215, 131, 127
    SeaShell                         = 255, 245, 238
    Selago                           = 250, 230, 250
    SelectiveYellow                  = 242, 180, 0
    SemiSweetChocolate               = 107, 68, 35
    Sepia                            = 150, 90, 62
    Serenade                         = 255, 233, 209
    Shadow                           = 133, 109, 77
    Shakespeare                      = 114, 160, 193
    Shalimar                         = 252, 255, 164
    Shamrock                         = 68, 215, 168
    ShamrockGreen                    = 0, 153, 102
    SherpaBlue                       = 0, 75, 73
    SherwoodGreen                    = 27, 77, 62
    Shilo                            = 222, 165, 164
    ShipCove                         = 119, 139, 165
    Shocking                         = 241, 156, 187
    ShockingPink                     = 255, 29, 206
    ShuttleGrey                      = 84, 98, 111
    Sidecar                          = 238, 224, 177
    Sienna                           = 160, 82, 45
    Silk                             = 190, 164, 147
    Silver                           = 192, 192, 192
    SilverChalice                    = 175, 177, 174
    SilverTree                       = 102, 201, 146
    SkyBlue                          = 135, 206, 235
    SlateBlue                        = 106, 90, 205
    SlateGray                        = 112, 128, 144
    SlateGrey                        = 112, 128, 144
    Smalt                            = 0, 48, 143
    SmaltBlue                        = 74, 100, 108
    Snow                             = 255, 250, 250
    SoftAmber                        = 209, 190, 168
    Solitude                         = 235, 236, 240
    Sorbus                           = 233, 105, 44
    Spectra                          = 53, 101, 77
    SpicyMix                         = 136, 101, 78
    Spray                            = 126, 212, 230
    SpringBud                        = 150, 255, 0
    SpringGreen                      = 0, 255, 127
    SpringSun                        = 236, 235, 189
    SpunPearl                        = 170, 169, 173
    Stack                            = 130, 142, 132
    SteelBlue                        = 70, 130, 180
    Stiletto                         = 137, 63, 69
    Strikemaster                     = 145, 92, 131
    StTropaz                         = 50, 82, 123
    Studio                           = 115, 79, 150
    Sulu                             = 201, 220, 135
    SummerSky                        = 33, 171, 205
    Sun                              = 237, 135, 45
    Sundance                         = 197, 179, 88
    Sunflower                        = 228, 208, 10
    Sunglow                          = 255, 204, 51
    SunsetOrange                     = 253, 82, 64
    SurfieGreen                      = 0, 116, 116
    Sushi                            = 111, 153, 64
    SuvaGrey                         = 140, 140, 140
    Swamp                            = 35, 43, 43
    SweetCorn                        = 253, 219, 109
    SweetPink                        = 243, 153, 152
    Tacao                            = 236, 177, 118
    TahitiGold                       = 235, 97, 35
    Tan                              = 210, 180, 140
    Tangaroa                         = 0, 28, 61
    Tangerine                        = 228, 132, 0
    TangerineYellow                  = 253, 204, 13
    Tapestry                         = 183, 110, 121
    Taupe                            = 72, 60, 50
    TaupeGrey                        = 139, 133, 137
    TawnyPort                        = 102, 66, 77
    TaxBreak                         = 79, 102, 106
    TeaGreen                         = 208, 240, 192
    Teak                             = 176, 141, 87
    Teal                             = 0, 128, 128
    TeaRose                          = 255, 133, 207
    Temptress                        = 60, 20, 33
    Tenne                            = 200, 101, 0
    TerraCotta                       = 226, 114, 91
    Thistle                          = 216, 191, 216
    TickleMePink                     = 245, 111, 161
    Tidal                            = 232, 244, 140
    TitanWhite                       = 214, 202, 221
    Toast                            = 165, 113, 100
    Tomato                           = 255, 99, 71
    TorchRed                         = 255, 3, 62
    ToryBlue                         = 54, 81, 148
    Tradewind                        = 110, 174, 161
    TrendyPink                       = 133, 96, 136
    TropicalRainForest               = 0, 127, 102
    TrueV                            = 139, 114, 190
    TulipTree                        = 229, 183, 59
    Tumbleweed                       = 222, 170, 136
    Turbo                            = 255, 195, 36
    TurkishRose                      = 152, 119, 123
    Turquoise                        = 64, 224, 208
    TurquoiseBlue                    = 118, 215, 234
    Tuscany                          = 175, 89, 62
    TwilightBlue                     = 253, 255, 245
    Twine                            = 186, 135, 89
    TyrianPurple                     = 102, 2, 60
    Ultramarine                      = 10, 17, 149
    UltraPink                        = 255, 111, 255
    Valencia                         = 222, 82, 70
    VanCleef                         = 84, 61, 55
    VanillaIce                       = 229, 204, 201
    VenetianRed                      = 209, 0, 28
    Venus                            = 138, 127, 128
    Vermilion                        = 251, 79, 20
    VeryLightGrey                    = 207, 207, 207
    VidaLoca                         = 94, 140, 49
    Viking                           = 71, 171, 204
    Viola                            = 180, 131, 149
    ViolentViolet                    = 50, 23, 77
    Violet                           = 238, 130, 238
    VioletRed                        = 255, 57, 136
    Viridian                         = 64, 130, 109
    VistaBlue                        = 159, 226, 191
    VividViolet                      = 127, 62, 152
    WaikawaGrey                      = 83, 104, 149
    Wasabi                           = 150, 165, 60
    Watercourse                      = 0, 106, 78
    Wedgewood                        = 67, 107, 149
    WellRead                         = 147, 61, 65
    Wewak                            = 255, 152, 153
    Wheat                            = 245, 222, 179
    Whiskey                          = 217, 154, 108
    WhiskeySour                      = 217, 144, 88
    White                            = 255, 255, 255
    WhiteSmoke                       = 245, 245, 245
    WildRice                         = 228, 217, 111
    WildSand                         = 229, 228, 226
    WildStrawberry                   = 252, 65, 154
    WildWatermelon                   = 255, 84, 112
    WildWillow                       = 172, 191, 96
    Windsor                          = 76, 40, 130
    Wisteria                         = 191, 148, 228
    Wistful                          = 162, 162, 208
    Yellow                           = 255, 255, 0
    YellowGreen                      = 154, 205, 50
    YellowOrange                     = 255, 174, 66
    YourPink                         = 244, 194, 194
}
function Add-ExcelWorkSheet {
    [cmdletBinding()]
    param ([OfficeOpenXml.ExcelPackage] $ExcelDocument,
        [alias('Name')][string] $WorksheetName,
        [ValidateSet("Replace", "Skip", "Rename")][string] $Option = 'Skip',
        [alias('Supress')][bool] $Suppress)
    $WorksheetName = $WorksheetName.Trim()
    if ($WorksheetName.Length -eq 0) {
        $WorksheetName = Get-RandomStringName -Size 31
        Write-Warning "Add-ExcelWorkSheet - Name is empty. Generated random name: '$WorksheetName'"
    } elseif ($WorksheetName.Length -gt 31) { $WorksheetName = $WorksheetName.Substring(0, 31) }
    $PreviousWorksheet = Get-ExcelWorkSheet -ExcelDocument $ExcelDocument -Name $WorksheetName
    if ($PreviousWorksheet) {
        if ($Option -eq 'Skip') {
            Write-Warning "Add-ExcelWorkSheet - Worksheet '$WorksheetName' already exists. Skipping creation of new worksheet. Option: $Option"
            $Data = $PreviousWorksheet
        } elseif ($Option -eq 'Replace') {
            Write-Verbose "Add-ExcelWorkSheet - WorksheetName: '$WorksheetName' - exists. Replacing worksheet with empty worksheet."
            Remove-ExcelWorksheet -ExcelDocument $ExcelDocument -ExcelWorksheet $PreviousWorksheet
            $Data = Add-ExcelWorkSheet -ExcelDocument $ExcelDocument -WorksheetName $WorksheetName -Option $Option -Suppress $False
        } elseif ($Option -eq 'Rename') {
            Write-Verbose "Add-ExcelWorkSheet - Worksheet: '$WorksheetName' already exists. Renaming worksheet to random value."
            $WorksheetName = Get-RandomStringName -Size 31
            $Data = Add-ExcelWorkSheet -ExcelDocument $ExcelDocument -WorksheetName $WorksheetName -Option $Option -Suppress $False
            Write-Verbose "Add-ExcelWorkSheet - New worksheet name $WorksheetName"
        } else {}
    } else {
        Write-Verbose "Add-ExcelWorkSheet - WorksheetName: '$WorksheetName' doesn't exists in Workbook. Continuing..."
        $Data = $ExcelDocument.Workbook.Worksheets.Add($WorksheetName)
    }
    if ($Suppress) { return } else { return $data }
}
function Add-ExcelWorkSheetCell {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [int] $CellRow,
        [int] $CellColumn,
        [Object] $CellValue,
        [string] $CellFormula)
    if ($ExcelWorksheet) {
        if ($PSBoundParameters.Keys -contains 'CellValue') {
            Switch ($CellValue) {
                { $_ -is [PSCustomObject] } {
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value = $CellValue
                    break
                }
                { $_ -is [Array] } {
                    $Value = $CellValue -join [System.Environment]::NewLine
                    if ($Value.Length -gt 32767) {
                        Write-Warning "Add-ExcelWorkSheetCell - Triming cell lenght from $($CellValue.Length) to 32767 as maximum limit to prevent errors (Worksheet: $($ExcelWorksheet.Name) Row: $CellRow Column: $CellColumn)."
                        $Value = $Value.Substring(0, 32767)
                    }
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value = $Value
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.WrapText = $true
                    break
                }
                { $_ -is [DateTime] } {
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value = $CellValue
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Numberformat.Format = 'm/d/yy h:mm'
                    break
                }
                { $_ -is [TimeSpan] } {
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value = $CellValue
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Numberformat.Format = 'hh:mm:ss'
                    break
                }
                { $_ -is [Int64] } {
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value = $CellValue
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Numberformat.Format = '#'
                    break
                }
                Default {
                    if ($CellValue.Length -gt 32767) {
                        Write-Warning "Add-ExcelWorkSheetCell - Triming cell lenght from $($CellValue.Length) to 32767 as maximum limit to prevent errors (Worksheet: $($ExcelWorksheet.Name) Row: $CellRow Column: $CellColumn)."
                        $CellValue = $CellValue.Substring(0, 32767)
                    }
                    $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value = $CellValue
                }
            }
        } elseif ($PSBoundParameters.Keys -contains 'CellFormula') {
            if ($CellFormula.StartsWith('=')) { $CellFormula = $CellFormula.Substring(1) }
            $ExcelWorksheet.Cells[$CellRow, $CellColumn].Formula = $CellFormula
        }
    }
}
function Add-ExcelWorksheetData {
    [CmdletBinding()]
    Param([alias('ExcelWorkbook')][OfficeOpenXml.ExcelPackage] $ExcelDocument,
        [OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [Parameter(ValueFromPipeline = $true)][Array] $DataTable,
        [ValidateSet("Replace", "Skip", "Rename")][string] $Option = 'Replace',
        [int]$StartRow = 1,
        [int]$StartColumn = 1,
        [alias("Autosize")][switch] $AutoFit,
        [switch] $AutoFilter,
        [Switch] $FreezeTopRow,
        [Switch] $FreezeFirstColumn,
        [Switch] $FreezeTopRowFirstColumn,
        [int[]]$FreezePane,
        [alias('Name', 'WorksheetName')][string] $ExcelWorksheetName,
        [alias('Rotate', 'RotateData', 'TransposeColumnsRows', 'TransposeData')][switch] $Transpose,
        [ValidateSet("ASC", "DESC", "NONE")][string] $TransposeSort = 'NONE',
        [alias('PreScanHeaders')][switch] $AllProperties,
        [alias('TableStyles')][nullable[OfficeOpenXml.Table.TableStyles]] $TableStyle,
        [string] $TableName,
        [string] $TabColor,
        [alias('Supress')][bool] $Suppress)
    Begin {
        $FirstRun = $True
        $RowNr = if ($null -ne $StartRow -and $StartRow -ne 0) { $StartRow } else { 1 }
        $ColumnNr = if ($null -ne $StartColumn -and $StartColumn -ne 0) { $StartColumn } else { 1 }
        if ($null -ne $ExcelWorksheet) { Write-Verbose "Add-ExcelWorkSheetData - ExcelWorksheet given. Continuing..." } else {
            if ($ExcelDocument) {
                $ExcelWorkSheet = Add-ExcelWorkSheet -ExcelDocument $ExcelDocument -Name $ExcelWorksheetName -Option $Option
                Write-Verbose "Add-ExcelWorkSheetData - ExcelWorksheet $($ExcelWorkSheet.Name)"
            } else { Write-Warning 'Add-ExcelWorksheetData - ExcelDocument and ExcelWorksheet not given. No data will be added...' }
        }
        if ($AutoFilter -and $TableStyle) { Write-Warning 'Add-ExcelWorksheetData - Using AutoFilter and TableStyle is not supported at same time. TableStyle will be skipped.' }
    }
    Process {
        if ($DataTable.Count -gt 0) {
            if ($FirstRun) {
                $FirstRun = $false
                if ($Transpose) { $DataTable = Format-TransposeTable -Object $DataTable -Sort $TransposeSort }
                $Data = Format-PSTable -Object $DataTable -ExcludeProperty $ExcludeProperty -PreScanHeaders:$AllProperties.IsPresent
                $WorksheetHeaders = $Data[0]
                if ($NoHeader) { $Data.RemoveAt(0) }
                $ArrRowNr = 0
                foreach ($RowData in $Data) {
                    $ArrColumnNr = 0
                    $ColumnNr = $StartColumn
                    foreach ($Value in $RowData) {
                        Add-ExcelWorkSheetCell -ExcelWorksheet $ExcelWorksheet -CellRow $RowNr -CellColumn $ColumnNr -CellValue $Value
                        $ColumnNr++
                        $ArrColumnNr++
                    }
                    $ArrRowNr++
                    $RowNr++
                }
            } else {
                if ($Transpose) { $DataTable = Format-TransposeTable -Object $DataTable -Sort $TransposeSort }
                $Data = Format-PSTable -Object $DataTable -SkipTitle -ExcludeProperty $ExcludeProperty -OverwriteHeaders $WorksheetHeaders -PreScanHeaders:$PreScanHeaders
                $ArrRowNr = 0
                foreach ($RowData in $Data) {
                    $ArrColumnNr = 0
                    $ColumnNr = $StartColumn
                    foreach ($Value in $RowData) {
                        Add-ExcelWorkSheetCell -ExcelWorksheet $ExcelWorksheet -CellRow $RowNr -CellColumn $ColumnNr -CellValue $Value
                        $ColumnNr++; $ArrColumnNr++
                    }
                    $RowNr++; $ArrRowNr++
                }
            }
        }
    }
    End {
        if ($null -ne $ExcelWorksheet) {
            if ($AutoFit) { Set-ExcelWorksheetAutoFit -ExcelWorksheet $ExcelWorksheet }
            if ($AutoFilter) { Set-ExcelWorksheetAutoFilter -ExcelWorksheet $ExcelWorksheet -DataRange $ExcelWorksheet.Dimension -AutoFilter $AutoFilter }
            if ($FreezeTopRow -or $FreezeFirstColumn -or $FreezeTopRowFirstColumn -or $FreezePane) { Set-ExcelWorkSheetFreezePane -ExcelWorksheet $ExcelWorksheet -FreezeTopRow:$FreezeTopRow -FreezeFirstColumn:$FreezeFirstColumn -FreezeTopRowFirstColumn:$FreezeTopRowFirstColumn -FreezePane $FreezePane }
            if ($TableStyle) { Set-ExcelWorkSheetTableStyle -ExcelWorksheet $ExcelWorksheet -TableStyle $TableStyle -DataRange $ExcelWorksheet.Dimension -TableName $TableName }
            if ($TabColor) { $ExcelWorksheet.TabColor = ConvertFrom-Color -Color $TabColor -AsDrawingColor }
            if ($Suppress) { return } else { return $ExcelWorkSheet }
        }
    }
}
$ScriptBlockColors = { param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $Script:RGBColors.Keys | Where-Object { $_ -like "$wordToComplete*" } }
Register-ArgumentCompleter -CommandName Add-ExcelWorksheetData -ParameterName TabColor -ScriptBlock $ScriptBlockColors
function ConvertFrom-Excel {
    [CmdletBinding()]
    param([alias('Excel', 'Path')][string] $FilePath,
        [alias('WorksheetName', 'Name')][string] $ExcelWorksheetName)
    if (Test-Path $FilePath) {
        $ExcelDocument = Get-ExcelDocument -Path $FilePath
        if ($ExcelWorksheetName) {
            $ExcelWorksheet = Get-ExcelWorkSheet -ExcelDocument $ExcelDocument -Name $ExcelWorksheetName
            if ($ExcelWorksheet) {
                $Data = Get-ExcelWorkSheetData -ExcelDocument $ExcelDocument -ExcelWorkSheet $ExcelWorksheet
                return $Data
            } else { Write-Warning "ConvertFrom-Excel - Worksheet with name $ExcelWorksheetName doesn't exists. Conversion terminated." }
        }
    } else { Write-Warning "ConvertFrom-Excel - File $FilePath doesn't exists. Conversion terminated." }
}
function ConvertTo-Excel {
    [CmdletBinding()]
    param([alias("path")][string] $FilePath,
        [OfficeOpenXml.ExcelPackage] $Excel,
        [alias('Name', 'WorksheetName')][string] $ExcelWorkSheetName,
        [alias("TargetData")][Parameter(ValueFromPipeline = $true)][Array] $DataTable,
        [ValidateSet("Replace", "Skip", "Rename")][string] $Option = 'Replace',
        [switch] $AutoFilter,
        [alias("Autosize")][switch] $AutoFit,
        [Switch] $FreezeTopRow,
        [Switch] $FreezeFirstColumn,
        [Switch] $FreezeTopRowFirstColumn,
        [int[]]$FreezePane,
        [alias('Rotate', 'RotateData', 'TransposeColumnsRows', 'TransposeData')][switch] $Transpose,
        [ValidateSet("ASC", "DESC", "NONE")][string] $TransposeSort = 'NONE',
        [alias('TableStyles')][nullable[OfficeOpenXml.Table.TableStyles]] $TableStyle,
        [string] $TableName,
        [switch] $OpenWorkBook,
        [alias('PreScanHeaders')][switch] $AllProperties)
    Begin {
        $Fail = $false
        $Data = [System.Collections.Generic.List[Object]]::new()
        if ($FilePath -like '*.xlsx') {
            if (Test-Path $FilePath) {
                $Excel = Get-ExcelDocument -Path $FilePath
                Write-Verbose "ConvertTo-Excel - Excel exists, Excel is loaded from file"
            }
        } else {
            $Fail = $true
            Write-Warning "ConvertTo-Excel - Excel path not given or incorrect (no .xlsx file format)"
            return
        }
        if ($null -eq $Excel) {
            Write-Verbose "ConvertTo-Excel - Excel is null, creating new Excel"
            $Excel = New-ExcelDocument
        }
    }
    Process {
        if ($Fail) { return }
        foreach ($_ in $DataTable) { $Data.Add($_) }
    }
    End {
        if ($Fail) { return }
        Add-ExcelWorksheetData -DataTable $Data -ExcelDocument $Excel -AutoFit:$AutoFit -AutoFilter:$AutoFilter -ExcelWorksheetName $ExcelWorkSheetName -FreezeTopRow:$FreezeTopRow -FreezeFirstColumn:$FreezeFirstColumn -FreezeTopRowFirstColumn:$FreezeTopRowFirstColumn -FreezePane $FreezePane -Transpose:$Transpose -TransposeSort $TransposeSort -Option $Option -TableStyle $TableStyle -TableName $TableName -AllProperties:$AllProperties.IsPresent -Suppress $true
        Save-ExcelDocument -ExcelDocument $Excel -FilePath $FilePath -OpenWorkBook:$OpenWorkBook
    }
}
function Excel {
    [CmdletBinding()]
    param([Parameter(Position = 0)][ValidateNotNull()][ScriptBlock] $Content = $(Throw "Excel requires opening and closing brace."),
        [string] $FilePath,
        [switch] $Open,
        [switch] $Parallel)
    $Time = Start-TimeLog
    $ExcelDocument = New-ExcelDocument
    $Script:Excel = @{}
    $Script:Excel.ExcelDocument = $ExcelDocument
    $Script:Excel.Runspaces = @{}
    $Script:Excel.Runspaces.Parallel = $Parallel.IsPresent
    $Script:Excel.Runspaces.RunspacesPool = New-Runspace
    $Script:Excel.Runspaces.Runspaces = [System.Collections.Generic.List[PSCustomObject]]::new()
    [Array] $Output = ConvertFrom-ScriptBlock -ScriptBlock $Content
    $WorkbookProperties = ConvertTo-ScriptBlock -Code $Output -Include 'WorkbookProperties'
    $Everything = ConvertTo-ScriptBlock -Code $Output -Exclude 'WorkbookProperties'
    if ($Everything) {
        & $Everything
        $Script:Excel.Runspaces.End = Stop-Runspace -Runspaces $Script:Excel.Runspaces.Runspaces -FunctionName "Excel" -RunspacePool $Script:RunspacesPool -Verbose:$Verbose -ErrorAction SilentlyContinue -ErrorVariable +AllErrors -ExtendedOutput:$ExtendedOutputF
    }
    if ($WorkbookProperties) { & $WorkbookProperties }
    $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
    Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $FilePath -OpenWorkBook:$Open
    $Script:Excel = $null
    Write-Verbose "Excel - Time to create - $EndTime"
}
function WorkbookProperties {
    [CmdletBinding()]
    param([string] $Title,
        [string] $Subject,
        [string] $Author,
        [string] $Comments,
        [string] $Keywords,
        [string] $LastModifiedBy,
        [string] $LastPrinted,
        [nullable[DateTime]] $Created,
        [string] $Category,
        [string] $Status,
        [string] $Application,
        [string] $HyperlinkBase,
        [string] $AppVersion,
        [string] $Company,
        [string] $Manager,
        [nullable[DateTime]] $Modified,
        [nullable[bool]] $LinksUpToDate,
        [nullable[bool]] $HyperlinksChanged,
        [nullable[bool]] $ScaleCrop,
        [nullable[bool]] $SharedDoc)
    $ExcelProperties = @{HyperlinksChanged = $HyperlinksChanged
        ScaleCrop                          = $ScaleCrop
        HyperlinkBase                      = $HyperlinkBase
        Subject                            = $Subject
        LastModifiedBy                     = $LastModifiedBy
        Author                             = $Author
        LinksUpToDate                      = $LinksUpToDate
        Modified                           = $Modified
        LastPrinted                        = $LastPrinted
        Company                            = $Company
        Comments                           = $Comments
        Title                              = $Title
        SharedDoc                          = $SharedDoc
        Created                            = $Created
        Category                           = $Category
        ExcelDocument                      = $Script:Excel.ExcelDocument
        Status                             = $Status
        AppVersion                         = $AppVersion
        Keywords                           = $Keywords
        Application                        = $Application
        Manager                            = $Manager
    }
    Set-ExcelProperties @ExcelProperties
}
function Find-ExcelDocumentText {
    [CmdletBinding()]
    param([string] $FilePath,
        [string] $FilePathTarget,
        [string] $Find,
        [switch] $Replace,
        [string] $ReplaceWith,
        [switch] $Regex,
        [switch] $OpenWorkBook,
        [alias('Supress')][bool] $Suppress)
    $Excel = Get-ExcelDocument -Path $FilePath
    if ($Excel) {
        $Addresses = @()
        $ExcelWorksheets = $Excel.Workbook.Worksheets
        foreach ($WorkSheet in $ExcelWorksheets) {
            $StartRow = $WorkSheet.Dimension.Start.Row
            $StartColumn = $WorkSheet.Dimension.Start.Column
            $EndRow = $WorkSheet.Dimension.End.Row + 1
            $EndColumn = $WorkSheet.Dimension.End.Column + 1
            for ($Row = $StartRow; $Row -le $EndRow; $Row++) {
                for ($Column = $StartColumn; $Column -le $EndColumn; $Column++) {
                    $Value = $Worksheet.Cells[$Column, $Row].Value
                    if ($Value -like "*$Find*") {
                        if ($Replace) { if ($Regex) { $Worksheet.Cells[$Column, $Row].Value = $Value -Replace $Find, $ReplaceWith } else { $Worksheet.Cells[$Column, $Row].Value = $Value.Replace($Find, $ReplaceWith) } }
                        $Addresses += $WorkSheet.Cells[$Column, $Row].FullAddress
                    }
                }
            }
        }
        if ($Replace) { Save-ExcelDocument -ExcelDocument $Excel -FilePath $FilePathTarget -OpenWorkBook:$OpenWorkBook }
        if ($Suppress) { return } else { return $Addresses }
    }
}
function Get-ExcelDocument {
    [CmdletBinding()]
    param([alias("FilePath")][string] $Path)
    $Script:SaveCounter = 0
    if (Test-Path $Path) {
        $Excel = New-Object -TypeName OfficeOpenXml.ExcelPackage -ArgumentList $Path
        return $Excel
    } else { return }
}
function Get-ExcelProperties {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelPackage] $ExcelDocument)
    if ($ExcelDocument) {
        $Properties = [ordered] @{}
        foreach ($Key in $ExcelDocument.Workbook.Properties.PsObject.Properties.Name | where { $_ -notlike '*Xml' }) { $Properties.$Key = $ExcelDocument.Workbook.Properties.$Key }
        return $Properties
    }
}
function Get-ExcelTranslateFromR1C1 {
    [alias('Set-ExcelTranslateFromR1C1')]
    [CmdletBinding()]
    param([int]$Row,
        [int]$Column = 1)
    $Range = [OfficeOpenXml.ExcelAddress]::TranslateFromR1C1("R[$Row]C[$Column]", 0, 0)
    return $Range
}
function Get-ExcelTranslateToR1C1 {
    [alias('Set-ExcelTranslateToR1C1')]
    [CmdletBinding()]
    param([string] $Value)
    if ($Value -eq '') { return } else {
        $Range = [OfficeOpenXml.ExcelAddress]::TranslateToR1C1($Value, 0, 0)
        return $Range
    }
}
function Get-ExcelWorkSheet {
    [OutputType([OfficeOpenXml.ExcelWorksheet])]
    [cmdletBinding()]
    param ([OfficeOpenXml.ExcelPackage] $ExcelDocument,
        [string] $Name,
        [nullable[int]] $Index,
        [switch] $All)
    if ($ExcelDocument) {
        if ($Name -and $Index) {
            Write-Warning 'Get-ExcelWorkSheet - Only $Name or $Index of Worksheet can be used.'
            return
        }
        if ($All) { $Data = $ExcelDocument.Workbook.Worksheets } elseif ($Name -or $null -ne $Index) {
            if ($Name) { $Data = $ExcelDocument.Workbook.Worksheets | Where-Object { $_.Name -eq $Name } }
            if ($null -ne $Index) {
                if ($PSEdition -ne 'Core') { $Index = $Index + 1 }
                Write-Verbose "Get-ExcelWorkSheet - Index: $Index"
                $Data = $ExcelDocument.Workbook.Worksheets[$Index]
            }
        }
    }
    return $Data
}
function Get-ExcelWorkSheetCell {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [int] $CellRow,
        [int] $CellColumn,
        [alias('Supress')][bool] $Suppress)
    if ($ExcelWorksheet) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Value }
}
function Get-ExcelWorkSheetData {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelPackage] $ExcelDocument,
        [OfficeOpenXml.ExcelWorksheet] $ExcelWorkSheet)
    $Dimensions = $ExcelWorkSheet.Dimension
    $CellRow = 1
    $ExcelDataArray = @()
    $Headers = @()
    for ($CellColumn = 1; $CellColumn -lt $Dimensions.Columns + 1; $CellColumn++) {
        $Heading = $ExcelWorkSheet.Cells[$CellRow, $CellColumn].Value
        if ([string]::IsNullOrEmpty($Heading)) { $Heading = $ExcelWorkSheet.Cells[$CellRow, $CellColumn].Address }
        $Headers += $Heading
    }
    Write-Verbose "Get-ExcelWorkSheetData - Headers: $($Headers -join ',')"
    for ($CellRow = 2; $CellRow -lt $Dimensions.Rows + 1; $CellRow++) {
        $ExcelData = [PsCustomObject] @{}
        for ($CellColumn = 1; $CellColumn -lt $Dimensions.Columns + 1; $CellColumn++) {
            $ValueContent = $ExcelWorkSheet.Cells[$CellRow, $CellColumn].Value
            $ColumnName = $Headers[$CellColumn - 1]
            Add-Member -InputObject $ExcelData -MemberType NoteProperty -Name $ColumnName -Value $ValueContent
            $ExcelData.$ColumnName = $ValueContent
        }
        $ExcelDataArray += $ExcelData
    }
    return $ExcelDataArray
}
function New-ExcelDocument {
    [CmdletBinding()]
    param()
    $Script:SaveCounter = 0
    [OfficeOpenXml.ExcelPackage]::new()
}
function Remove-ExcelWorksheet {
    [CmdletBinding()]
    param ([alias('ExcelWorkbook')][OfficeOpenXml.ExcelPackage] $ExcelDocument,
        [OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet)
    if ($ExcelDocument -and $ExcelWorksheet) { $ExcelDocument.Workbook.Worksheets.Delete($ExcelWorksheet) }
}
function Request-ExcelWorkSheetCalculation {
    [cmdletBinding(DefaultParameterSetName = 'ExcelWorkSheetName')]
    param([Parameter(ParameterSetName = 'ExcelWorkSheet')][OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [Parameter(ParameterSetName = 'ExcelWorkSheetName', Mandatory)]
        [Parameter(ParameterSetName = 'ExcelWorkSheetIndex', Mandatory)]
        [OfficeOpenXml.ExcelPackage] $Excel,
        [Parameter(ParameterSetName = 'ExcelWorkSheetName')][string] $Name,
        [Parameter(ParameterSetName = 'ExcelWorkSheetIndex')][int] $Index)
    if ($ExcelWorksheet) { [OfficeOpenXml.CalculationExtension]::Calculate($ExcelWorkSheet) } elseif ($Name -and $Excel) {
        $ExcelWorksheet = Get-ExcelWorkSheet -Name $Name -ExcelDocument $Excel
        if ($ExcelWorksheet) { [OfficeOpenXml.CalculationExtension]::Calculate($ExcelWorkSheet) }
    } else {
        if ($PSBoundParameters.Contains('Index') -and $Excel) {
            $ExcelWorksheet = Get-ExcelWorkSheet -Index $Index -ExcelDocument $Excel
            if ($ExcelWorksheet) { [OfficeOpenXml.CalculationExtension]::Calculate($ExcelWorkSheet) }
        }
    }
}
function Save-ExcelDocument {
    [CmdletBinding()]
    param ([parameter(Mandatory = $false, ValueFromPipeline = $true)][Alias('Document', 'Excel', 'Package')] $ExcelDocument,
        [string] $FilePath,
        [alias('Show', 'Open')][switch] $OpenWorkBook)
    if (-not $ExcelDocument -or $ExcelDocument.Workbook.Worksheets.Count -eq 0) {
        Write-Warning "Save-ExcelDocument - Saving workbook $FilePath was terminated. No worksheets/data exists."
        return
    }
    if ($Script:SaveCounter -gt 5) {
        Write-Warning "Save-ExcelDocument - Couldnt save Excel. Terminating.."
        return
    }
    try {
        Write-Verbose "Save-ExcelDocument - Saving workbook $FilePath"
        $ExcelDocument.SaveAs($FilePath)
        $Script:SaveCounter = 0
    } catch {
        $Script:SaveCounter++
        $ErrorMessage = $_.Exception.Message
        if ($ErrorMessage -like "*The process cannot access the file*because it is being used by another process.*" -or
            $ErrorMessage -like "*Error saving file*") {
            $FilePath = Get-FileName -Temporary -Extension 'xlsx'
            Write-Warning "Save-ExcelDocument - Couldn't save file as it was in use or otherwise. Trying different name $FilePath"
            $ExcelDocument.File = $FilePath
            Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $FilePath -OpenWorkBook:$OpenWorkBook
        } else { Write-Warning "Save-ExcelDocument - Error: $ErrorMessage" }
    }
    if ($OpenWorkBook) { if (Test-Path $FilePath) { Invoke-Item -Path $FilePath } else { Write-Warning "Save-ExcelDocument - File $FilePath doesn't exists. Can't open Excel document." } }
}
function Set-ExcelProperties {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelPackage] $ExcelDocument,
        [string] $Title,
        [string] $Subject,
        [string] $Author,
        [string] $Comments,
        [string] $Keywords,
        [string] $LastModifiedBy,
        [string] $LastPrinted,
        [nullable[DateTime]] $Created,
        [string] $Category,
        [string] $Status,
        [string] $Application,
        [string] $HyperlinkBase,
        [string] $AppVersion,
        [string] $Company,
        [string] $Manager,
        [nullable[DateTime]] $Modified,
        [nullable[bool]] $LinksUpToDate,
        [nullable[bool]] $HyperlinksChanged,
        [nullable[bool]] $ScaleCrop,
        [nullable[bool]] $SharedDoc)
    if ($Title) { $ExcelDocument.Workbook.Properties.Title = $Title }
    if ($Subject) { $ExcelDocument.Workbook.Properties.Subject = $Subject }
    if ($Author) { $ExcelDocument.Workbook.Properties.Author = $Author }
    if ($Comments) { $ExcelDocument.Workbook.Properties.Comments = $Comments }
    if ($Keywords) { $ExcelDocument.Workbook.Properties.Keywords = $Keywords }
    if ($LastModifiedBy) { $ExcelDocument.Workbook.Properties.LastModifiedBy = $LastModifiedBy }
    if ($LastPrinted) { $ExcelDocument.Workbook.Properties.LastPrinted = $LastPrinted }
    if ($Created) { $ExcelDocument.Workbook.Properties.Created = $Created }
    if ($Category) { $ExcelDocument.Workbook.Properties.Category = $Category }
    if ($Status) { $ExcelDocument.Workbook.Properties.Status = $Status }
    if ($Application) { $ExcelDocument.Workbook.Properties.Application = $Application }
    if ($HyperlinkBase) { if ($HyperlinkBase -like '*://*') { $ExcelDocument.Workbook.Properties.HyperlinkBase = $HyperlinkBase } else { Write-Warning "Set-ExcelProperties - Hyperlinkbase is not an URL (doesn't contain ://)" } }
    if ($AppVersion) { $ExcelDocument.Workbook.Properties.AppVersion = $AppVersion }
    if ($Company) { $ExcelDocument.Workbook.Properties.Company = $Company }
    if ($Manager) { $ExcelDocument.Workbook.Properties.Manager = $Manager }
    if ($Modified) { $ExcelDocument.Workbook.Properties.Modified = $Modified }
    if ($LinksUpToDate -ne $null) { $ExcelDocument.Workbook.Properties.LinksUpToDate = $LinksUpToDate }
    if ($HyperlinksChanged -ne $null) { $ExcelDocument.Workbook.Properties.HyperlinksChanged = $HyperlinksChanged }
    if ($ScaleCrop -ne $null) { $ExcelDocument.Workbook.Properties.ScaleCrop = $ScaleCrop }
    if ($SharedDoc -ne $null) { $ExcelDocument.Workbook.Properties.SharedDoc = $SharedDoc }
}
function Set-ExcelWorksheetAutoFilter {
    [CmdletBinding()]
    param ([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [string] $DataRange,
        [bool] $AutoFilter)
    if ($ExcelWorksheet) {
        if (-not $DataRange) { $DataRange = $ExcelWorksheet.Dimension }
        try { $ExcelWorksheet.Cells[$DataRange].AutoFilter = $AutoFilter } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            Write-Warning "Set-ExcelWorksheetAutoFilter - Failed AutoFilter with error message: $ErrorMessage"
        }
    }
}
function Set-ExcelWorksheetAutoFit {
    [CmdletBinding()]
    param ([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet)
    if ($ExcelWorksheet) {
        Write-Verbose "Set-ExcelWorksheetAutoFit - Columns Count: $($ExcelWorksheet.Dimension.Columns)"
        if ($ExcelWorksheet.Dimension.Columns -gt 0) {
            try { $ExcelWorksheet.Cells.AutoFitColumns() } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning "Set-ExcelWorksheetAutoFit - Failed AutoFit with error message: $ErrorMessage"
            }
        }
    }
}
function Set-ExcelWorkSheetCellStyle {
    [alias('Set-ExcelWorkSheetCellStyleFont')]
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [int] $CellRow,
        [int] $CellColumn,
        [alias('FontName')][string] $Name,
        [switch] $Bold,
        [System.Drawing.KnownColor] $Color,
        [switch] $Italic,
        [int] $Size,
        [switch] $Strike,
        [switch] $UnderLine,
        [OfficeOpenXml.Style.ExcelUnderLineType] $UnderLineType,
        [OfficeOpenXml.Style.ExcelVerticalAlignment] $VerticalAlignment,
        [OfficeOpenXml.Style.ExcelFillStyle] $PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid)
    if (-not $ExcelWorksheet) { return }
    if ($PatternType) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Fill.PatternType = $PatternType }
    if ($Bold) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.Bold = $Bold.IsPresent }
    if ($Color) {
        $DrawingColor = [System.Drawing.Color]::FromKnownColor($Color)
        $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Fill.BackgroundColor.SetColor($DrawingColor)
    }
    if ($Italic) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.Italic = $Italic }
    if ($Name) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.Name = $Name }
    if ($Size) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.Size = $Size }
    if ($Strike) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.Strike = $Strike }
    if ($UnderLine) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.UnderLine = $UnderLine }
    if ($UnderLineType) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.UnderLineType = $UnderLineType }
    if ($VerticalAlign) { $ExcelWorksheet.Cells[$CellRow, $CellColumn].Style.Font.VerticalAlign = $VerticalAlignment }
}
function Set-ExcelWorkSheetFreezePane {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [Switch] $FreezeTopRow,
        [Switch] $FreezeFirstColumn,
        [Switch] $FreezeTopRowFirstColumn,
        [int[]]$FreezePane)
    try {
        if ($ExcelWorksheet -ne $null) {
            if ($FreezeTopRowFirstColumn) {
                Write-Verbose 'Set-ExcelWorkSheetFreezePane - Processing freezing panes FreezeTopRowFirstColumn'
                $ExcelWorksheet.View.FreezePanes(2, 2)
            } elseif ($FreezeTopRow -and $FreezeFirstColumn) {
                Write-Verbose 'Set-ExcelWorkSheetFreezePane - Processing freezing panes FreezeTopRow and FreezeFirstColumn'
                $ExcelWorksheet.View.FreezePanes(2, 2)
            } elseif ($FreezeTopRow) {
                Write-Verbose 'Set-ExcelWorkSheetFreezePane - Processing freezing panes FreezeTopRow'
                $ExcelWorksheet.View.FreezePanes(2, 1)
            } elseif ($FreezeFirstColumn) {
                Write-Verbose 'Set-ExcelWorkSheetFreezePane - Processing freezing panes FreezeFirstColumn'
                $ExcelWorksheet.View.FreezePanes(1, 2)
            }
            if ($FreezePane) {
                Write-Verbose 'Set-ExcelWorkSheetFreezePane - Processing freezing panes FreezePane'
                if ($FreezePane.Count -eq 2) { if ($FreezePane -notcontains 0) { if ($FreezePane[1] -gt 1) { $ExcelWorksheet.View.FreezePanes($FreezePane[0], $FreezePane[1]) } } }
            }
        }
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning "Set-ExcelWorkSheetFreezePane - Worksheet: $($ExcelWorksheet.Name) error: $ErrorMessage"
    }
}
function Set-ExcelWorkSheetTableStyle {
    [CmdletBinding()]
    param([OfficeOpenXml.ExcelWorksheet] $ExcelWorksheet,
        [string] $DataRange,
        [alias('TableStyles')][nullable[OfficeOpenXml.Table.TableStyles]] $TableStyle,
        [string] $TableName = $(Get-RandomStringName -LettersOnly -Size 5 -ToLower))
    try {
        if ($null -ne $ExcelWorksheet) {
            if ($ExcelWorksheet.AutoFilterAddress) { return }
            if (-not $DataRange) { $DataRange = $ExcelWorksheet.Dimension }
            if ($null -ne $TableStyle) {
                Write-Verbose "Set-ExcelWorkSheetTableStyle - Setting style to $TableStyle"
                $ExcelWorkSheetTables = $ExcelWorksheet.Tables.Add($DataRange, $TableName)
                $ExcelWorkSheetTables.TableStyle = $TableStyle
            }
        }
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning "Set-ExcelWorkSheetTableStyle - Worksheet: $($ExcelWorksheet.Name) error: $ErrorMessage"
    }
}
function Worksheet {
    [CmdletBinding()]
    param([Array] $DataTable,
        [string] $Name,
        [ValidateSet("Replace", "Skip", "Rename")][string] $Option = 'Replace',
        [string] $TabColor,
        [switch] $AutoFilter,
        [switch] $AutoFit)
    $ScriptBlock = { Param ($ExcelDocument,
            [Array] $DataTable,
            [string] $Name,
            [ValidateSet("Replace", "Skip", "Rename")][string] $Option = 'Replace',
            [string] $TabColor,
            [alias('Supress')][bool] $Suppress,
            [switch] $AutoFilter,
            [switch] $AutoFit)
        $addExcelWorkSheetDataSplat = @{DataTable = $DataTable
            TabColor                              = $TabColor
            Suppress                              = $Suppress
            Option                                = $Option
            ExcelDocument                         = $ExcelDocument
            ExcelWorksheetName                    = $Name
            AutoFit                               = $AutoFit
            AutoFilter                            = $AutoFilter
        }
        Add-ExcelWorksheetData @addExcelWorkSheetDataSplat -Verbose }
    $ExcelWorkSheetParameters = [ordered] @{DataTable = $DataTable
        TabColor                                      = $TabColor
        Suppress                                      = $true
        Option                                        = $Option
        ExcelDocument                                 = $Script:Excel.ExcelDocument
        Name                                          = $Name
        AutoFit                                       = $AutoFit
        AutoFilter                                    = $AutoFilter
    }
    if ($Script:Excel.Runspaces.Parallel) {
        $RunSpace = Start-Runspace -ScriptBlock $ScriptBlock -Parameters $ExcelWorkSheetParameters -RunspacePool $Script:Excel.Runspaces.RunspacesPool -Verbose:$Verbose
        $Script:Excel.Runspaces.Runspaces.Add($RunSpace)
    } else { & $ScriptBlock -Parameters @ExcelWorkSheetParameters }
}
$ScriptBlockColors = { param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $Script:RGBColors.Keys | Where-Object { $_ -like "$wordToComplete*" } }
Register-ArgumentCompleter -CommandName Worksheet -ParameterName TabColor -ScriptBlock $ScriptBlockColors
if ($PSEdition -eq 'Core') {
    Add-Type -Path $PSScriptRoot\Lib\Core\EPPlus.NetCORE.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.Configuration.Abstractions.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.Configuration.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.Configuration.FileExtensions.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.Configuration.Json.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.FileProviders.Abstractions.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.FileProviders.Physical.dll
    Add-Type -Path $PSScriptRoot\Lib\Core\Microsoft.Extensions.Primitives.dll
} else { Add-Type -Path $PSScriptRoot\Lib\Default\EPPlus.Net40.dll }
Export-ModuleMember -Function @('Add-ExcelWorkSheet', 'Add-ExcelWorkSheetCell', 'Add-ExcelWorksheetData', 'ConvertFrom-Excel', 'ConvertTo-Excel', 'Excel', 'Find-ExcelDocumentText', 'Get-ExcelDocument', 'Get-ExcelProperties', 'Get-ExcelTranslateFromR1C1', 'Get-ExcelTranslateToR1C1', 'Get-ExcelWorkSheet', 'Get-ExcelWorkSheetCell', 'Get-ExcelWorkSheetData', 'New-ExcelDocument', 'Remove-ExcelWorksheet', 'Request-ExcelWorkSheetCalculation', 'Save-ExcelDocument', 'Set-ExcelProperties', 'Set-ExcelWorksheetAutoFilter', 'Set-ExcelWorksheetAutoFit', 'Set-ExcelWorkSheetCellStyle', 'Set-ExcelWorkSheetFreezePane', 'Set-ExcelWorkSheetTableStyle', 'WorkbookProperties', 'Worksheet') -Alias @('Set-ExcelTranslateFromR1C1', 'Set-ExcelTranslateToR1C1', 'Set-ExcelWorkSheetCellStyleFont')
# SIG # Begin signature block
# MIIgQAYJKoZIhvcNAQcCoIIgMTCCIC0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFpvWLaWSD6NjkVRioDxuHiy9
# sFSgghtvMIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMzExMTEwMDAwMDAwWjBlMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3Qg
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtDhXO5EOAXLGH87dg
# +XESpa7cJpSIqvTO9SA5KFhgDPiA2qkVlTJhPLWxKISKityfCgyDF3qPkKyK53lT
# XDGEKvYPmDI2dsze3Tyoou9q+yHyUmHfnyDXH+Kx2f4YZNISW1/5WBg1vEfNoTb5
# a3/UsDg+wRvDjDPZ2C8Y/igPs6eD1sNuRMBhNZYW/lmci3Zt1/GiSw0r/wty2p5g
# 0I6QNcZ4VYcgoc/lbQrISXwxmDNsIumH0DJaoroTghHtORedmTpyoeb6pNnVFzF1
# roV9Iq4/AUaG9ih5yLHa5FcXxH4cDrC0kqZWs72yl+2qp/C3xag/lRbQ/6GW6whf
# GHdPAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBRF66Kv9JLLgjEtUYunpyGd823IDzAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAog683+Lt8ONyc3pklL/3
# cmbYMuRCdWKuh+vy1dneVrOfzM4UKLkNl2BcEkxY5NM9g0lFWJc1aRqoR+pWxnmr
# EthngYTffwk8lOa4JiwgvT2zKIn3X/8i4peEH+ll74fg38FnSbNd67IJKusm7Xi+
# fT8r87cmNW1fiQG2SVufAQWbqz0lwcy2f8Lxb4bG+mRo64EtlOtCt/qMHt1i8b5Q
# Z7dsvfPxH2sMNgcWfzd8qVttevESRmCD1ycEvkvOl77DZypoEd+A5wwzZr8TDRRu
# 838fYxAe+o0bJW1sj6W3YQGx0qMmoRBxna3iw/nDmVG3KwcIzi7mULKn+gpFL6Lw
# 8jCCBTAwggQYoAMCAQICEAQJGBtf1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAw
# ZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBS
# b290IENBMB4XDTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/
# DhGvZ3cH0wsxSRnP0PtFmbE620T1f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2
# qvCchqXYJawOeSg6funRZ9PG+yknx9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrsk
# acLCUvIUZ4qJRdQtoaPpiCwgla4cSocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/
# 6XzLkqHlOzEcz+ryCuRXu0q16XTmK/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE
# 94zRICUj6whkPlKWwfIPEvTFjg/BougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8
# np+mM6n9Gd8lk9ECAwEAAaOCAc0wggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYD
# VR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0w
# azAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUF
# BzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# ME8GA1UdIARIMEYwOAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7
# KgqjpepxA8Bg+S32ZXUOWDAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823I
# DzANBgkqhkiG9w0BAQsFAAOCAQEAPuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh
# 134LYP3DPQ/Er4v97yrfIFU3sOH20ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63X
# X0R58zYUBor3nEZOXP+QsRsHDpEV+7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPA
# JRHinBRHoXpoaK+bp1wgXNlxsQyPu6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC
# /i9yfhzXSUWW6Fkd6fp0ZGuy62ZD2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG
# /AeB+ova+YJJ92JuoVP6EpQYhS6SkepobEQysmah5xikmmRR7zCCBT0wggQloAMC
# AQICEATV3B9I6snYUgC6zZqbKqcwDQYJKoZIhvcNAQELBQAwcjELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2ln
# bmluZyBDQTAeFw0yMDA2MjYwMDAwMDBaFw0yMzA3MDcxMjAwMDBaMHoxCzAJBgNV
# BAYTAlBMMRIwEAYDVQQIDAnFmmzEhXNraWUxETAPBgNVBAcTCEthdG93aWNlMSEw
# HwYDVQQKDBhQcnplbXlzxYJhdyBLxYJ5cyBFVk9URUMxITAfBgNVBAMMGFByemVt
# eXPFgmF3IEvFgnlzIEVWT1RFQzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAL+ygd4sga4ZC1G2xXvasYSijwWKgwapZ69wLaWaZZIlY6YvXTGQnIUnk+Tg
# 7EoT7mQiMSaeSPOrn/Im6N74tkvRfQJXxY1cnt3U8//U5grhh/CULdd6M3/Z4h3n
# MCq7LQ1YVaa4MYub9F8WOdXO84DANoNVG/t7YotL4vzqZil3S9pHjaidp3kOXGJc
# vxrCPAkRFBKvUmYo23QPFa0Rd0qA3bFhn97WWczup1p90y2CkOf28OVOOObv1fNE
# EqMpLMx0Yr04/h+LPAAYn6K4YtIu+m3gOhGuNc3B+MybgKePAeFIY4EQzbqvCMy1
# iuHZb6q6ggRyqrJ6xegZga7/gV0CAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBQYsTUn6BxQICZOCZA0CxS0TZSU
# ZjAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGE
# BggrBgEFBQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBOBggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQC
# MAAwDQYJKoZIhvcNAQELBQADggEBAJq9bM+JbCwEYuMBtXoNAfH1SRaMLXnLe0py
# VK6el0Z1BtPxiNcF4iyHqMNVD4iOrgzLEVzx1Bf/sYycPEnyG8Gr2tnl7u1KGSjY
# enX4LIXCZqNEDQCeTyMstNv931421ERByDa0wrz1Wz5lepMeCqXeyiawqOxA9fB/
# 106liR12vL2tzGC62yXrV6WhD6W+s5PpfEY/chuIwVUYXp1AVFI9wi2lg0gaTgP/
# rMfP1wfVvaKWH2Bm/tU5mwpIVIO0wd4A+qOhEia3vn3J2Zz1QDxEprLcLE9e3Gmd
# G5+8xEypTR23NavhJvZMgY2kEXBEKEEDaXs0LoPbn6hMcepR2A4wggZqMIIFUqAD
# AgECAhADAZoCOv9YsWvW1ermF/BmMA0GCSqGSIb3DQEBBQUAMGIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTAeFw0xNDEw
# MjIwMDAwMDBaFw0yNDEwMjIwMDAwMDBaMEcxCzAJBgNVBAYTAlVTMREwDwYDVQQK
# EwhEaWdpQ2VydDElMCMGA1UEAxMcRGlnaUNlcnQgVGltZXN0YW1wIFJlc3BvbmRl
# cjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKNkXfx8s+CCNeDg9sYq
# 5kl1O8xu4FOpnx9kWeZ8a39rjJ1V+JLjntVaY1sCSVDZg85vZu7dy4XpX6X51Id0
# iEQ7Gcnl9ZGfxhQ5rCTqqEsskYnMXij0ZLZQt/USs3OWCmejvmGfrvP9Enh1DqZb
# FP1FI46GRFV9GIYFjFWHeUhG98oOjafeTl/iqLYtWQJhiGFyGGi5uHzu5uc0LzF3
# gTAfuzYBje8n4/ea8EwxZI3j6/oZh6h+z+yMDDZbesF6uHjHyQYuRhDIjegEYNu8
# c3T6Ttj+qkDxss5wRoPp2kChWTrZFQlXmVYwk/PJYczQCMxr7GJCkawCwO+k8IkR
# j3cCAwEAAaOCAzUwggMxMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYG
# A1UdJQEB/wQMMAoGCCsGAQUFBwMIMIIBvwYDVR0gBIIBtjCCAbIwggGhBglghkgB
# hv1sBwEwggGSMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20v
# Q1BTMIIBZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAA
# dABoAGkAcwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQA
# dQB0AGUAcwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQA
# aQBnAGkAQwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIA
# ZQBsAHkAaQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcA
# aABpAGMAaAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQA
# IABhAHIAZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4A
# IABiAHkAIAByAGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTAfBgNVHSME
# GDAWgBQVABIrE5iymQftHt+ivlcNK2cCzTAdBgNVHQ4EFgQUYVpNJLZJMp1KKnka
# g0v0HonByn0wfQYDVR0fBHYwdDA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwOKA2oDSGMmh0dHA6Ly9jcmw0
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMHcGCCsGAQUF
# BwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEG
# CCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURDQS0xLmNydDANBgkqhkiG9w0BAQUFAAOCAQEAnSV+GzNNsiaBXJuG
# ziMgD4CH5Yj//7HUaiwx7ToXGXEXzakbvFoWOQCd42yE5FpA+94GAYw3+puxnSR+
# /iCkV61bt5qwYCbqaVchXTQvH3Gwg5QZBWs1kBCge5fH9j/n4hFBpr1i2fAnPTgd
# KG86Ugnw7HBi02JLsOBzppLA044x2C/jbRcTBu7kA7YUq/OPQ6dxnSHdFMoVXZJB
# 2vkPgdGZdA0mxA5/G7X1oPHGdwYoFenYk+VVFvC7Cqsc21xIJ2bIo4sKHOWV2q7E
# LlmgYd3a822iYemKC23sEhi991VUQAOSK2vCUcIKSK+w1G7g9BQKOhvjjz3Kr2qN
# e9zYRDCCBs0wggW1oAMCAQICEAb9+QOWA63qAArrPye7uhswDQYJKoZIhvcNAQEF
# BQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJ
# RCBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTIxMTExMDAwMDAwMFowYjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6IItmfnKwkKVpYBzQHDSnlZU
# XKnE0kEGj8kz/E1FkVyBn+0snPgWWd+etSQVwpi5tHdJ3InECtqvy15r7a2wcTHr
# zzpADEZNk+yLejYIA6sMNP4YSYL+x8cxSIB8HqIPkg5QycaH6zY/2DDD/6b3+6LN
# b3Mj/qxWBZDwMiEWicZwiPkFl32jx0PdAug7Pe2xQaPtP77blUjE7h6z8rwMK5nQ
# xl0SQoHhg26Ccz8mSxSQrllmCsSNvtLOBq6thG9IhJtPQLnxTPKvmPv2zkBdXPao
# 8S+v7Iki8msYZbHBc63X8djPHgp0XEK4aH631XcKJ1Z8D2KkPzIUYJX9BwSiCQID
# AQABo4IDejCCA3YwDgYDVR0PAQH/BAQDAgGGMDsGA1UdJQQ0MDIGCCsGAQUFBwMB
# BggrBgEFBQcDAgYIKwYBBQUHAwMGCCsGAQUFBwMEBggrBgEFBQcDCDCCAdIGA1Ud
# IASCAckwggHFMIIBtAYKYIZIAYb9bAABBDCCAaQwOgYIKwYBBQUHAgEWLmh0dHA6
# Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9yeS5odG0wggFkBggr
# BgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAA
# QwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAA
# YQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUA
# cgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4A
# ZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAA
# bABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAA
# aQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIA
# ZQBmAGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMBIGA1UdEwEB/wQIMAYBAf8C
# AQAweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcmwwHQYDVR0OBBYEFBUAEisTmLKZB+0e36K+Vw0rZwLN
# MB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUA
# A4IBAQBGUD7Jtygkpzgdtlspr1LPUukxR6tWXHvVDQtBs+/sdR90OPKyXGGinJXD
# UOSCuSPRujqGcq04eKx1XRcXNHJHhZRW0eu7NoR3zCSl8wQZVann4+erYs37iy2Q
# wsDStZS9Xk+xBdIOPRqpFFumhjFiqKgz5Js5p8T1zh14dpQlc+Qqq8+cdkvtX8JL
# FuRLcEwAiR78xXm8TBJX/l/hHrwCXaj++wc4Tw3GXZG5D2dFzdaD7eeSDY2xaYxP
# +1ngIw/Sqq4AfO6cQg7PkdcntxbuD8O9fAqg7iwIVYUiuOsYGk38KiGtSTGDR5V3
# cdyxG0tLHBCcdxTBnU8vWpUIKRAmMYIEOzCCBDcCAQEwgYYwcjELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2ln
# bmluZyBDQQIQBNXcH0jqydhSALrNmpsqpzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU77YbIkgL
# 9/FW+3K7JR2fX9KDXZIwDQYJKoZIhvcNAQEBBQAEggEAchpFR+RCg8YSv3TTgCQE
# qAkyu50K6RfCV2pBGCCf4YE9gsLL9W32/SPBFvIHskh5uHooFGw7n11BDivylYq/
# QpKazSk93i1CsbZF050d0jvbog1vnyKju67+pLrnHIVQNsaKlPOdGedqQPhU/xia
# gL+LwsNZzO67mohuTvT73zCBn5FSEzZPE7pYES4uAxErBV09frCpOsC7RZNCDZd+
# uwU/cUB3UA8LhvtUgPyokv4Hpk9jt5nz3v/pfMSsZtvEr06BdsxWRI0OKMAlyxgu
# 34LNvK1zZTPjpR8el0fp2qONlr4lruVejsN2n8hDFuiNhGK1Camqr4zoPYJ+NAy6
# +aGCAg8wggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGaAjr/WLFr
# 1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMjAxMTIxMDg1ODAwWjAjBgkqhkiG9w0BCQQxFgQU3h0R
# yGRwCU4VhCS3ygYkvSmWOGcwDQYJKoZIhvcNAQEBBQAEggEAa3WGIwrfVfS3WYVr
# 5z+hDAfTt8594BGylidTLq24OO83VBZ5DMswSqrgz8KRNOaHsunT8aBKVlbW31bk
# BlymX55Pydg9e3/dLzHXnG2ZyZWv2iyE2lqs1cn7gYG2I/uJ9fEyeK8C8QTqiW+8
# iZD8Z1RwZVd7Ssm9wW6nZLLYiO0K32LtkY0j+UzY9SPLKy9e41/y2Fr5TWJ7x6lq
# u9D2ryUXINxGOxDFSMucRDdN4cGG6iniMdRGjKxcU86S15GQaHYnrkZZobob18Tb
# IHjld5DOquJFo+EoEncKOsyfLqFLWP7c3U78S7D7alTSpwl3qIGHstxdOD2i5odd
# l79Z1Q==
# SIG # End signature block
