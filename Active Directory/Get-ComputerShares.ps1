function Get-ComputerShares {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if (!$ComputerName) { throw 'No comps.' }

    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $result = $ping.Send($ComputerName)
    } catch {
        $result = $null
    }

    $sharename = $type = $comment = $ip = '-'
    if ($result.Status -eq 'Success') {
        # get the ip address
        $ip = $result.Address.ToString()

        # THE MAIN COMMAND
        $netview = iex "cmd /c net view $ComputerName 2>&1" | ? { $_ }

        # if there are less than 5 lines, no shares found
        if ($netview.count -lt 5) {
            [pscustomobject]@{
                Computer  = $ComputerName
                IP        = $ip
                ShareName = $sharename
                Type      = $type
                Comment   = $comment
            }
            return
        }

        $netview = $netview | ? { $_ -match '\s{2}' } | select -Skip 1

        foreach ($line in $netview) {
            $line = $line -split '\s{2,}'

            $sharename = $line[0]
            $type = $line[1]
            $comment = $line[2]

            [pscustomobject]@{
                Computer  = $ComputerName
                IP        = $ip
                ShareName = $sharename
                Type      = $type
                Comment   = $comment
            }
        }
    } else {
        [pscustomobject]@{
            Computer  = $ComputerName
            IP        = $ip
            ShareName = $sharename
            Type      = $type
            Comment   = $comment
        }
    }
}