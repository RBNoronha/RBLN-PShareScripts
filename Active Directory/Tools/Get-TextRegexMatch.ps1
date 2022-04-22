function Get-TextRegexMatch {
    <#
        .SYNOPSIS

            Obter o texto entre dois caracteres ao redor (por exemplo, colchetes, aspas ou caracteres personalizados)

        .DESCRIPTION

            Use RegEx para recuperar o texto dentro de caracteres delimitadores.

	    .PARAMETER Text

          O texto do qual recuperar as correspondencias.

        .PARAMETER WithinChar

          Caractere unico, indicando os caracteres ao redor para recuperar o texto de fechamento
          Se parametro for usado, o caractere final correspondente sera "adivinhado" (por exemplo, '(' = ')')

        .PARAMETER StartChar

           Caractere unico, indicando o inicio dos caracteres circundantes para os quais recuperar o texto de fechamento.

        .PARAMETER EndChar

            Caractere unico, indicando o final dos caracteres ao redor para os quais recuperar o texto de fechamento.

        .EXAMPLE

            # Recupere todo o texto entre aspas simples
		    $s=@'
here is 'some data'
here is "some other data"
this is 'even more data'
'@

             Get-TextRegexMatch $s "'"
    .EXAMPLE

    # Recupere todo o texto em caracteres de inicio e fim personalizados
    $s=@'
here is /some data\
here is /some other data/
this is /even more data\
'@
    Get-TextRegexMatch $s -StartChar / -EndChar \

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            ValueFromPipeline = $true,
            Position = 0)]
        $Text,
        [Parameter(ParameterSetName = 'Single', Position = 1)]
        [char]$WithinChar = '"',
        [Parameter(ParameterSetName = 'Double')]
        [char]$StartChar,
        [Parameter(ParameterSetName = 'Double')]
        [char]$EndChar
    )
    $htPairs = @{
        '(' = ')'
        '[' = ']'
        '{' = '}'
        '<' = '>'
    }
    if ($PSBoundParameters.ContainsKey('WithinChar')) {
        $StartChar = $EndChar = $WithinChar
        if ($htPairs.ContainsKey([string]$WithinChar)) {
            $EndChar = $htPairs[[string]$WithinChar]
        }
    }
    $pattern = @"
(?<=\$StartChar).+?(?=\$EndChar)
"@
    [regex]::Matches($Text, $pattern).Value
}