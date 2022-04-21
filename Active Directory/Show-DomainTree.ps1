Function Show-DomainTree {
    [cmdletbinding()]
    [OutputType("String")]
    [alias("dt")]
    Param(
        [Parameter(Position = 0, HelpMessage = "Especifique o nome de dominio. O padrao e o dominio do usuario.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name = $env:USERDOMAIN,
        [Parameter(HelpMessage = "Especifique um controlador de dominio para consultar.")]
        [alias("dc", "domaincontroller")]
        [string]$Server,
        [Parameter(HelpMessage = "Especificar uma credencial alternativa.")]
        [alias("RunAs")]
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Exibir a arvore de dominio usando nomes distintos.")]
        [alias("dn")]
        [switch]$UseDN,
        [Parameter(HelpMessage = "Inclua conteineres e elementos nao OU. Itens com um GUID no nome serao omitidos.")]
        [alias("cn")]
        [switch]$Containers
    )
    Write-Verbose "Starting $($myinvocation.MyCommand)"
    Function Get-OUTree {
        [cmdletbinding()]
        Param(
            [string]$Path = (Get-ADDomain).DistinguishedName,
            [string]$Server,
            [Parameter(HelpMessage = "Especificar uma credencial alternativa")]
            [PSCredential]$Credential,
            [Parameter(HelpMessage = "Exibir o nome distinto")]
            [switch]$UseDN,
            [Parameter(HelpMessage = "Incluir containers")]
            [alias("cn")]
            [switch]$Containers,
            [Parameter(HelpMessage = "Usado apenas em recursao. Voce nao precisa especificar nada")]
            [Int]$Indent = 1,
            [Parameter(HelpMessage = "Usado apenas em recursao. Voce nao precisa especificar nada")]
            [switch]$Children
        )
        Write-Verbose "Pesquisando caminho $path"
        function GetIndentString {
            [CmdletBinding()]
            Param([int]$Indent)
            $charHash = @{
                upperLeft  = [char]0x250c
                upperRight = [char]0x2510
                lowerRight = [char]0x2518
                lowerLeft  = [char]0x2514
                horizontal = [char]0x2500
                vertical   = [char]0x2502
                join       = [char]0x251c
            }
            if ($Children) {
                if ($indent -eq 5) {
                    $indent += 2
                } elseif ($indent -eq 7) {
                    $indent += 4
                }
                $pad = " " * ($Indent)
                if ($script:IsLast) {
                    $str += " $pad{0}{1} " -f $charHash.join, ([string]$charHash.horizontal * 2 )
                } else {
                    $str += "{0}$pad{1}{2} " -f $charHash.vertical, $charHash.join, ([string]$charHash.horizontal * 2 )
                }
            } else {
                if ($script:IsLast) {
                    $c = $charHash.lowerleft
                } else {
                    $c = $charHash.join
                }
                $str = "{0}{1} " -f $c, ([string]$charHash.horizontal * 2 )
            }
            $str
        }
        [regex]$Guid = "\w{8}-(\w{4}-){3}\w{12}"
        if ($Containers) {
            $filter = "(|(objectclass=container)(objectclass=organizationalUnit))"
        } else {
            $filter = "objectclass=organizationalUnit"
        }
        $search = @{
            LDAPFilter  = $filter
            SearchScope = "OneLevel"
            SearchBase  = $path
            Properties  = "ProtectedFromAccidentalDeletion"
        }
        "Server", "Credential" | foreach-Object {
            if ($PSBoundParameters.ContainsKey($_)) {
                $search.Add($_, $PSBoundParameters[$_])
            }
        }
        $data = Get-ADObject @search | Sort-Object -Property DistinguishedName
        if ($Containers) {
            $data = $data | where-object { $_.name -notmatch $GUID }
        }
        if ($path -match "^DC\=") {
            $top = $data
            $last = $top[-1].distinguishedname
            $script:IsLast = $False
            Write-Verbose "O ultimo nivel superior e $last"
        }
        if ($data ) {
            $data | Foreach-Object {
                if ($UseDN) {
                    $name = $_.distinguishedname
                } else {
                    $name = $_.name
                }
                if ($script:IsLast) {
                    Write-Verbose "Processando ultimos itens"
                } else {
                    $script:IsLast = $_.distinguishedname -eq $last
                }
                if ($_.ProtectedFromAccidentalDeletion) {
                    $nameValue = "$([char]0x1b)[38;5;199m$name$([char]0x1b)[0m"
                } elseif ($_.objectclass -eq 'container') {
                    $nameValue = "$([char]0x1b)[38;5;3m$name$([char]0x1b)[0m"
                } elseif ($_.objectclass -ne 'organizationalUnit') {
                    $nameValue = "$([char]0x1b)[38;5;211m$name$([char]0x1b)[0m"
                } else {
                    $nameValue = "$([char]0x1b)[38;5;191m$name$([char]0x1b)[0m"
                }
                "{0}{1}" -f (GetIndentString -indent $indent), $nameValue
                $PSBoundParameters["Path"] = $_.DistinguishedName
                $PSBoundParameters["Indent"] = $Indent + 2
                $PSBoundParameters["children"] = $True
                Get-OUTree @PSBoundParameters
            }
        }
    }
    if ($host.name -eq 'ConsoleHost') {
        $getAD = @{
            ErrorAction = "stop"
            Identity    = $Name
        }
        "Server", "Credential" | foreach-Object {
            if ($PSBoundParameters.ContainsKey($_)) {
                $getAD.Add($_, $PSBoundParameters[$_])
            }
        }
        Try {
            Write-Verbose "Obtendo nome distinto para $($Name.toUpper())"
            $getAD | Out-String | Write-Verbose
            [string]$Path = (Get-ADDomain @getAD).DistinguishedName
            $PSBoundParameters.add("Path", $Path)
            [void]($PSBoundParameters.remove("Name"))
        } Catch {
            Throw $_
        }
        $top = @"

$([char]0x1b)[1;4;92m$Path$([char]0x1b)[0m
$([char]0x2502)
"@
        $top
        Get-OUTree @PSBoundParameters
        $tz = Get-TimeZone
        if ((Get-Date).IsDaylightSavingTime()) {
            $tzname = $tz.daylightName
        } else {
            $tzname = $tz.StandardName
        }
        $date = Get-Date -format g
        $footer = @"

$([char]0x1b)[38;5;191mUnidades organizacionais$([char]0x1b)[0m
$([char]0x1b)[38;5;199mProtegido contra exclusao$([char]0x1b)[0m
$([char]0x1b)[38;5;3mContainers$([char]0x1b)[0m
$([char]0x1b)[38;5;211mOutro$([char]0x1b)[0m

$([char]0x1b)[38;5;11m$date $tzname$([char]0x1b)[0m
"@
        $footer
    } else {
        Write-Host "Esse comando deve ser executado em um host do console do PowerShell." -ForegroundColor magenta
    }
    Write-Verbose "Final $($myinvocation.MyCommand)"
}