################## VM-DC01-INTUNE NOVA ####################

# Desabilitar firewall e Defender

netsh advfirewall set allprofiles state off
Set-MpPreference -DisableRealtimeMonitoring $True

# Alterar Fuso horário

Set-TimeZone -Id 'E. South America Standard Time'

#Aguardar Reinicializacao

# Remover adaptadores ocultos
$Devs = Get-PnpDevice -Class net |
    Where-Object Status -eq Unknown |
    Select-Object FriendlyName, InstanceId

foreach ($Dev in $Devs) {
    Write-Host "Removendo $($Dev.FriendlyName)" -ForegroundColor Cyan
    $RemoveKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Dev.InstanceId)"
    Get-Item $RemoveKey |
        Select-Object -ExpandProperty Property |
        ForEach-Object { Remove-ItemProperty -Path $RemoveKey -Name $_ -Verbose }
}
Write-Host "Finalizado. Por favor reinicie!" -ForegroundColor Green

# Verificar nome do adaptador e index para atribuir o ip e dns
$IntAlias = (Get-NetIPAddress | Select-Object InterfaceAlias).InterfaceAlias[0]
$IntIndex = (Get-NetIPAddress | Select-Object InterfaceIndex).InterfaceIndex[0]

#Definir IP,Mascara, Gateway e DNS da VM-DC02
$IPadd = "192.168.10.5"
$Mask = "255.255.255.0"
$Gw = "192.168.10.1"
$DnsP = "192.168.10.4"
$DnsS = "168.63.129.16"

# Atribuir IP e DNS estatico para adaptador encontrado.

netsh interface ipv4 set address name="$IntAlias" static $IPadd $Mask $Gw
$dnsParams = @{
    InterfaceIndex  = $IntIndex
    ServerAddresses = ("$DnsP", "$DnsS")
}
Set-DnsClientServerAddress @dnsParams
Clear-DnsClientCache -Verbose

# Verificar se foi atribuido

Get-NetIPConfiguration -InterfaceAlias $IntAlias -Detailed

#Instalar a função de Serviços de Domínio Active Directory


#### AGUARDAR REBOOT ####

# Criar pastas temporarias

New-Item -Path C:\ -Name 'Temp' -ItemType Directory -Force -Verbose
New-Item -Path C:\ -Name 'EventLogs' -ItemType Directory -Force -Verbose
New-Item -Path C:\Temp\ -Name 'Reports' -ItemType Directory -Force -Verbose

# Configurando WinRM

winrm quickconfig -quiet -force

# Alterar Policita de execucao no powershell

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false

# Instalador Provedor Nuget

Install-PackageProvider -Name nuget -Scope AllUsers -MinimumVersion 2.8.5.201 -Force -Confirm:$false

# Verifica politica

Get-ExecutionPolicy -Scope LocalMachine
Get-ExecutionPolicy -Scope CurrentUser
