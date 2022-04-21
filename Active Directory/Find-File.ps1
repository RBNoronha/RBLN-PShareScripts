function Find-File {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String]$Path,
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$Filename,
        [Switch]$CaseSensitive)

    if (!$(Test-Path $Path)) { throw "O caminho especificado nao foi encontrado:  $Path" }

    Switch ($CaseSensitive) {
        $True {
            Get-ChildItem -Recurse $Path -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.BaseName -cmatch $Filename) { $_.FullName } }
        }
        $False {
            Get-ChildItem -Recurse $Path -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.BaseName -match $Filename) { $_.FullName } }
        }
    }
}