function Show-Progress {


        Param(
                [Parameter()][string]$Activity = "Current Task",
                [Parameter()][ValidateScript({ $_ -gt 0 })][long]$PercentComplete = 1,
                [Parameter()][ValidateScript({ $_ -gt 0 })][long]$Total = 100,
                [Parameter()][ValidateRange(1, 60)][int]$RefreshInterval = 1
        )
        Process {
                #Continue exibindo o progresso na mesma linha / posição
                $CurrentLine = $host.UI.RawUI.CursorPosition
                #Width of the progress bar
                if ($host.UI.RawUI.WindowSize.Width -gt 70) { $Width = 50 }
                else { $Width = ($host.UI.RawUI.WindowSize.Width) - 20 }
                if ($Width -lt 20) { "Window size is too small to display the progress bar"; break }
                $Percentage = ($PercentComplete / $Total) * 100
                #Write-Host -ForegroundColor Magenta "Percentage: $Percentage"
                for ($i = 0; $i -le 100; $i += $Percentage) {

                        $Percentage = ($PercentComplete / $Total) * 100
                        $ProgressBar = 0
                        $host.UI.RawUI.CursorPosition = $CurrentLine

                        Write-Host -NoNewline -ForegroundColor Cyan "["
                        while ($ProgressBar -le $i * $Width / 100) {
                                Write-Host -NoNewline "="
                                $ProgressBar++
                        }
                        while (($ProgressBar -le $Width) -and ($ProgressBar -gt $i * $Width / 100)  ) {
                                Write-Host -NoNewline " "
                                $ProgressBar++
                        }
                        #Write-Host -NoNewline $i
                        Write-Host -NoNewline -ForegroundColor Cyan "] "
                        Write-Host -NoNewline "$Activity`: "

                        Write-Host -NoNewline "$([math]::round($i,2)) %, please wait"

                        Start-Sleep -Seconds $RefreshInterval
                        #Write-Host ""
                } #for
                #
                $host.UI.RawUI.CursorPosition = $CurrentLine

                Write-Host -NoNewline -ForegroundColor Cyan "["
                while ($end -le ($Width)) {
                        Write-Host -NoNewline -ForegroundColor Green "="
                        $end += 1
                }
                Write-Host -NoNewline -ForegroundColor Cyan "] "
                Write-Host -NoNewline "$Activity complete                    "

        } #Process
} #function
$TargetFolder = 'C:\users'
$FolderResult = @()
Get-ChildItem -force $TargetFolder -ErrorAction SilentlyContinue | Where-Object { $_ -is [io.directoryinfo] } | ForEach-Object {
    $len = 0
    Get-ChildItem -recurse -force $_.FullName -ErrorAction SilentlyContinue | ForEach-Object { $len += $_.length }
    $FolderName = $_.BaseName
    $FolderUNC = $_.FullName
    $FolderSizeGB = '{0:N2}' -f ($len / 1Gb)
    $FolderSizeMB = '{0:N2}' -f ($len / 1Mb)
    $FolderObject = New-Object PSObject
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "Nome da pasta" -value $FolderName
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "Tamanho(GB)" -value $FolderSizeGB
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "Tamanho(MB)" -value $FolderSizeMB
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "UNC" -value $FolderUNC
    $FolderResult += $FolderObject
}

Write-Host -ForegroundColor yellow "<#######################################################""#######################################################>"
""
Write-Host -ForegroundColor Green "Script PowerShell para excluir cache , cookies em navegadores do Firefox, Chrome, e IE"
""
Write-Host -ForegroundColor yellow "-------------------                   RENAN BESSERRA                -------------------"
""
Write-Host -ForegroundColor yellow "<#######################################################""#######################################################>"
""
Write-Host -ForegroundColor Green "Atualmente essa e a volumetria das pastas de usuarios"
""
    Write-Host -ForegroundColor Green "Aguarde, gerando uma nova volumetria "
    start-sleep -Second 30
$FolderResult
"-------------------"
Write-Host -ForegroundColor Green "Obtendo a lista de usuarios para exportacao"
start-sleep -Second 30
"-------------------"
# Informar local do arquivo de usuarios
Write-Host -ForegroundColor yellow "Exportando a lista de usuarios para C:\Usuarios\%NomeDoUsuario%\Users.csv"
"-------------------"
#Listar os usuarios em C:\users e exportar para o perfil d
""
Get-ChildItem C:\Users | Select-Object Name | Export-Csv -Path C:\users\$env:USERNAME\users.csv -NoTypeInformation
""
"-------------------"
#Remover arquivo temporarios
Write-Host -ForegroundColor Green "Secao 1: Removendo arquivos temporarios"
"-------------------"
Write-Host -ForegroundColor yellow "Removendo arquivo temporarios"
"-------------------"
Set-Location "C:\Windows\Temp"
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\Windows\Prefetch" -ErrorAction SilentlyContinue -Verbose
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\Documents and Settings" -ErrorAction SilentlyContinue -Verbose
Remove-Item ".\*\Local Settings\temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\windows\logs\cbs\*.log" -ErrorAction SilentlyContinue -Verbose
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\Windows\Logs\MoSetup\*.log" -ErrorAction SilentlyContinue -Verbose
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\Windows\Panther\*.log" -ErrorAction SilentlyContinue -Verbose
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\Windows\inf\*.log" -ErrorAction SilentlyContinue -Verbose
Remove-Item * -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "C:\Windows\logs\" -ErrorAction SilentlyContinue -Verbose
Remove-Item "*.log" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Set-Location "c:\windows\logs\" -ErrorAction SilentlyContinue -Verbose
Remove-Item "*.old" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Remove-Item -path "C:\windows\logs\*.old\" -Recurse -Force -EA SilentlyContinue -Verbose
Remove-Item -path "C:\Windows\SoftwareDistribution\*.log\" -Recurse -Force -EA SilentlyContinue -Verbose
Remove-Item -path "C:\Windows\Microsoft.NET\*.log\" -Recurse -Force -EA SilentlyContinue -Verbose
Import-CSV -Path C:\users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
    Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Windows\WebCache\*.log\" -Recurse -Force -EA SilentlyContinue -Verbose
    Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Windows\SettingSync\*.log\" -Recurse -Force -EA SilentlyContinue -Verbose
    Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Windows\Explorer\ThumbCacheToDelete\*.tmp\" -Recurse -Force -EA SilentlyContinue -Verbose
    Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Terminal Server Client\Cache\*.bin\*\" -Recurse -Force -EA SilentlyContinue -Verbose
    Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Windows\INetCache\" -Recurse -Force -EA SilentlyContinue -Verbose
}

Write-Host -ForegroundColor yellow "Finalizado..."

if ($list) {
    "-------------------"
    #Remover cache do Teams
    Write-Host -ForegroundColor Green "Secao 2: Removendo cache do Microsoft Teams"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do Microsoft Teams"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\application cache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\Roaming\Microsoft\Teams\blob_storage\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\databases\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\GPUcache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\IndexedDB\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\Local Storage\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\tmp\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Roaming\Microsoft\Teams\Service Worker\*" -Recurse -Force -EA SilentlyContinue -Verbose

    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    #Limpar o cache do Mozilla Firefox
    Write-Host -ForegroundColor Green "Secao 3: Removendo Cache do Mozilla Firefox"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do Mozilla Firefox"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\*.*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries\*.*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\cookies.sqlite" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\cache2\entries\*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\startupCache\*.bin\*\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\startupCache\*.lz*\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\cache2\index*.*\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\startupCache\*.little\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\cache2\*.log\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\cache2\entries\*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\startupCache\*.bin\*\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\startupCache\*.lz*\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\cache2\index*.*\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\startupCache\*.little\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\local\Mozilla\Firefox\Profiles\%folder%\cache2\*.log\" -Recurse -Force -EA SilentlyContinue -Verbose
    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    # Cache Google Chrome
    Write-Host -ForegroundColor Green "Secao 5: Removendo cache do Google Chrome"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do Google Chrome"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv -Header Name | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cache2\entries\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cookies" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Media Cache" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cookies-Journal" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Cache\index." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\GrShaderCache\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\ShaderCache\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Default\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 1\Storage\ext\" -Recurse -Force -EA SilentlyContinue -verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Google\Chrome\User Data\Profile 2\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    #Remover Cache do Internet Explorer
    Write-Host -ForegroundColor Green "Secao 6: Removendo cache do Internet Explorer"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do Internet Explorer"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Temp\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\`$recycle.bin\" -Recurse -Force -EA SilentlyContinue -Verbose -Recurse -Force -EA SilentlyContinue -Verbose
    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    #Remover Cache do Edge
    Write-Host -ForegroundColor Green "Secao 7: Removendo cache do Edge"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do Edge"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Cache\index." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\Database\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\ScriptCache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\GrShaderCache\GPUCache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\ShaderCache\GPUCache\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Default\Storage\ext\*" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Cache\data.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Cache\index." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 1\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Cache\index." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Microsoft\Edge\User Data\Profile 2\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose

    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    #Remover Cache do Internet Explorer
    Write-Host -ForegroundColor Green "Secao 8: Removendo cache do Vivaldi"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do Vivaldi"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Cache\index." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\GrShaderCache\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\ShaderCache\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Default\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 1\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\Vivaldi\User Data\Profile 2\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    #Remover Cache do BraveSoftware
    Write-Host -ForegroundColor Green "Secao 9: Removendo cache do BraveSoftware"
    "-------------------"
    Write-Host -ForegroundColor yellow "Removendo cache do BraveSoftware"
    Write-Host -ForegroundColor cyan
    Import-CSV -Path C:\users\$env:USERNAME\users.csv | ForEach-Object {
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\index." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\GrShaderCache\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\ShaderCache\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 1\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\Cache\data*.\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\Cache\f*." -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\Service Worker\Database\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\Service Worker\CacheStorage\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\Service Worker\ScriptCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\GPUCache\" -Recurse -Force -EA SilentlyContinue -Verbose
        Remove-Item -path "C:\Users\$($_.Name)\AppData\Local\BraveSoftware\Brave-Browser\User Data\Profile 2\Storage\ext\" -Recurse -Force -EA SilentlyContinue -Verbose
    }
    Write-Host -ForegroundColor yellow "Finalizado..."
    ""
    "-------------------"
    Write-Host -ForegroundColor Green "Todas as tarefas foram realizadas com SUCESSO!"
 ""
    Exit
} else {
    Write-Host -ForegroundColor Yellow "Sessao cancelada"
    ""
}
$TargetFolder = 'C:\users'
$FolderResultACT = @()
Get-ChildItem -force $TargetFolder -ErrorAction SilentlyContinue | Where-Object { $_ -is [io.directoryinfo] } | ForEach-Object {
    $len = 0
    Get-ChildItem -recurse -force $_.FullName -ErrorAction SilentlyContinue | ForEach-Object { $len += $_.length }
    $FolderName = $_.BaseName
    $FolderUNC = $_.FullName
    $FolderSizeGB = '{0:N2}' -f ($len / 1Gb)
    $FolderSizeMB = '{0:N2}' -f ($len / 1Mb)
    $FolderObject = New-Object PSObject
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "Nome da pasta" -value $FolderName
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "Tamanho(GB)" -value $FolderSizeGB
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "Tamanho(MB)" -value $FolderSizeMB
    Add-Member -inputObject $FolderObject -memberType NoteProperty -name "UNC" -value $FolderUNC
    $FolderResultACT += $FolderObject
}
    Write-Host -ForegroundColor Green "Aguarde, gerando uma nova volumetria "
    start-sleep -Second 30
    $FolderResultACT