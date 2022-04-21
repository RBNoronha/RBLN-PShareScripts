<#

#Configure the following variables
# Convert the following to a list of strings if you have multiple servers
# Convert text Title case




#>

Function ConvertTo-TitleCase {
    [cmdletbinding()]
    [alias("totc", "title")]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Text
    )
    Process {
        $low = $text.toLower()
      (Get-Culture).TextInfo.ToTitleCase($low)
    }
}