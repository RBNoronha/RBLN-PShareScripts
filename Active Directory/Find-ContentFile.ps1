function Find-ContentFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String]$Path,
        [Parameter(Mandatory = $True, Position = 2)]
        [String]$Content,
        [Switch]$CaseSensitive)

    if (!$(Test-Path $Path)) { throw "O caminho especificado nao foi encontrado:  $Path" }

    Switch ($CaseSensitive) {
        $True {
            Get-ChildItem -Recurse $Path -ErrorAction SilentlyContinue | ForEach-Object {
                if ( -not $_.psiscontainer -and (Select-String -Case $Content $_ -ea SilentlyContinue )) { $_ } }
        }
        $False {
            Get-ChildItem -Recurse $Path -ErrorAction SilentlyContinue | ForEach-Object {
                if ( -not $_.psiscontainer -and (Select-String $Content $_ -ea SilentlyContinue)) { $_ } }
        }
    }
}