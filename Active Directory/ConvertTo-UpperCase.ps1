Function ConvertTo-UpperCase {
    [cmdletbinding()]
    [alias("Uppec", "Upper")]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Text
    )
    Process {
        $low = $text.toLower()
      (Get-Culture).TextInfo.ToUpper($low)
    }
}