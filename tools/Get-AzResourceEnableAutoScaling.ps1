# Connectar a sua conta do Azure   
Connect-AzAccount -DeviceCode

# Obter todas as assinaturas
$subscriptions = Get-AzSubscription

# Definir os tipos de recursos desejados
$resourceTypes = "Microsoft.Compute/virtualMachineScaleSets", "Microsoft.ContainerService/managedClusters", "Microsoft.Web/sites"

# Criar uma lista vazia para armazenar os resultados
$results = @()

# Para cada assinatura, listar os grupos de recursos e os recursos
foreach ($subscription in $subscriptions) {
    # Selecionar a assinatura atual
    Select-AzSubscription -SubscriptionId $subscription.Id

    # Listar os grupos de recursos
    $groups = Get-AzResourceGroup

    # Para cada grupo de recursos, listar os recursos que correspondem aos tipos desejados ou que têm a propriedade enableAutoScaling
    foreach ($group in $groups) {
        $resources = Get-AzResource -ResourceGroupName $group.ResourceGroupName | Where-Object { $resourceTypes -contains $_.ResourceType -or $_.Properties.enableAutoScaling -eq $true }
        foreach ($resource in $resources) {
            # Criar um objeto personalizado com as propriedades desejadas
            $result = [PSCustomObject]@{
                Assinatura           = $subscription.Name
                GrupoDeRecursos      = $group.ResourceGroupName
                NomeDoRecurso        = $resource.Name
                TipoDoRecurso        = $resource.ResourceType
                LocalizaçãoDoRecurso = $resource.Location
            }
            # Adicionar o objeto à lista de resultados
            $results += $result
        }
    }
}

# Verifique se o modulo ImportExcel está instalado e instale -o, se necessário
if (-not (Get-Module -Name ImportExcel -ListAvailable)) {

    $install = Read-Host -Prompt "O modulo ImportExcel nao esta instalado.Voce quer instala -lo agora? (S/N)"

    if ($install -eq "S") {

        Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber
        Import-Module -Name ImportExcel -Force
        Write-Host "O modulo ImportExcel foi instalado com sucesso."

    } else {

        Write-Host "O modulo ImportExcel e necessario para exportar os resultados para um arquivo do Excel. Por favor, instale-o e execute o script novamente."
        Exit
    }
}

# Exportar a lista de resultados para um arquivo xlsx
$results | Export-Excel -Path C:\Temp\RecursosScallingEnabled.xlsx -AutoSize -FreezeTopRow -BoldTopRow
