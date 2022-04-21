Function Get-ADGPOLink {
    <#

   .Synopsis

   Obter links de objetoS de politica de grupo

   .Description

   Este comando exibira os links para objetos de Diretiva de Grupo existentes.
   Voce pode filtrar links ativados ou desativados.
   O dominio de usuario padrao e consultado, embora voce possa especificar um dominio alternativo e/ou um controlador de dominio especifico.
   Nao ha provisao para credenciais alternativas.
   requer -versao 5.1
   requer -module GroupPolicy,ActiveDirectory
   O comando grava um objeto personalizado no pipeline. Existem visualizacoes de tabela personalizadas associadas que voce pode usar. Veja exemplos.

   .Parameter Name

   Insira um nome de GPO. Caracteres curinga sao permitidos. Este parametro tem um alias de gpo.

   .Parameter Server

   Especifique o nome de um controlador de dominio especifico a ser consultado.

   .Parameter Domain

   Insira o nome de um dominio do Active Directory.
   O padrao e o dominio do usuario atual.
   Suas credenciais devem ter permissao para consultar o dominio.
   Especifique o nome de dominio DNS, ou seja, empresa.com

   .Parameter Enabled

   Mostrar apenas links que estao habilitados.

   .Parameter Disabled

   Mostrar apenas links que estao desabilitados.

   .Example

   PS C:\> Get-ADGPOLink

   Target                                  DisplayName                       Enabled Enforced Order
   ------                                  -----------                       ------- -------- -----
   dc=rbcorporate,dc=tech                       Default Domain Policy             True    True         1
   dc=rbcorporate,dc=tech                       PKI AutoEnroll                    True    False        2
   ou=domain controllers,dc=rbcorporate,dc=tech Default Domain Controllers Policy True    False        1
   ou=it,dc=rbcorporate,dc=tech                 Demo 2                            True    False        1
   ou=dev,dc=rbcorporate,dc=tech                Demo 1                            True    False        1
   ou=dev,dc=rbcorporate,dc=tech                Demo 2                            False   False        2
   ou=sales,dc=rbcorporate,dc=tech              Demo 1                            True    False        1
   ...

   Se voce estiver executando no console, os valores False em Enabled serao exibidos em vermelho.  Os valores impostos verdadeiros serao exibidos em verde

   .Example

   PS C:\> Get-ADGPOLink -Disabled

   Target                             DisplayName Enabled Enforced Order
   ------                             ----------- ------- -------- -----
   ou=dev,dc=rbcorporate,dc=tech           Demo 2      False   False        2
   ou=foo\,bar demo,dc=rbcorporate,dc=tech SQL Ports      False   False        1

   Obter links de politica de grupo desabilitados.

   .Example

   PS C:\> Get-ADGPOLink SQL Ports | get-gpo

   DisplayName      : SQL Ports
   DomainName       : Rbcoporate.tech
   Owner            : rbcorporate\Domain Admins
   Id               : 7551c3d8-99fa-4bc6-85a2-bd650124f11a
   GpoStatus        : AllSettingsEnabled
   Description      :
   CreationTime     : 1/11/2021 2:34:37 PM
   ModificationTime : 1/11/2021 2:34:38 PM
   UserVersion      : AD Version: 0, SysVol Version: 0
   ComputerVersion  : AD Version: 0, SysVol Version: 0
   WmiFilter        :

   .Example

   PS C:\>  Get-ADGPOLink | Where TargetType -eq "domain"

   Target            DisplayName           Enabled Enforced Order
   ------            -----------           ------- -------- -----
   dc=rbcorporate,dc=tech Default Domain Policy True    True         1
   dc=rbcorporate,dc=tech PKI AutoEnroll        True    True         2

   Outros valores de TargetType possiveis sao OU e Site

   .Example

   PS C:\>  Get-ADGPOLink | sort Target | Format-Table -view link


      Target: dc=rbcorporate,dc=tech

   DisplayName                         Enabled    Enforced    Order
   -----------                         -------    --------    -----
   PKI AutoEnroll                      True       False           2
   Default Domain Policy               True       True            1


      Target: ou=dev,dc=rbcorporate,dc=tech

   DisplayName                         Enabled    Enforced    Order
   -----------                         -------    --------    -----
   Demo 1                              True       False           1
   Demo 2                              False      False           2
   ...

   .Example

   PS C:\> Get-ADGPOLink | Sort TargetType | Format-Table -view targetType

      TargetType: Domain

   Target                          DisplayName                  Enabled    Enforced     Order
   ------                          -----------                  -------    --------     -----
   dc=rbcorporate,dc=tech               PKI AutoEnroll               True       True             2
   dc=rbcorporate,dc=tech               Default Domain Policy        True       True             1


      TargetType: OU

   Target                            DisplayName                Enabled    Enforced     Order
   ------                            -----------                -------    --------     -----
   ou=accounting,dc=rbcorporate,dc=tech   Accounting-dev-test-foo    True       False            1
   ou=sales,dc=rbcorporate,dc=tech        Demo 1                     True       False            1
   ...

#>

    [cmdletbinding(DefaultParameterSetName = "All")]
    [outputtype("myGPOLink")]
    Param(
        [parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = "Insira o nome da GPO. Caracteres curinga sao permitidos")]
        [alias("gpo")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(HelpMessage = "Especifique o nome de um controlador de dominio especifico para consultar.")]
        [ValidateNotNullOrEmpty()]
        [string]$Server,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,
        [Parameter(ParameterSetName = "enabled")]
        [switch]$Enabled,
        [Parameter(ParameterSetName = "disabled")]
        [switch]$Disabled
    )
    Begin {
        Write-Verbose "Iniciando $($myinvocation.mycommand)"
        Write-Verbose "Executando como $($env:USERDOMAIN)\$($env:USERNAME) em $($env:Computername)"
        Write-Verbose "Usando a versao do PowerShell $($psversiontable.PSVersion)"
        Write-Verbose "Usando o modulo ActiveDirectory $((Get-Module ActiveDirectory).version)"
        Write-Verbose "Usando o modulo GroupPolicy $((Get-Module GroupPolicy).version)"
        Function Get-GPSiteLink {
            [cmdletbinding()]
            Param (
                [Parameter(Position = 0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
                [alias("Name")]
                [string[]]$SiteName = "Default-First-Site-Name",
                [Parameter(Position = 1)]
                [string]$Domain,
                [string]$Server
            )
            Begin {
                Write-Verbose "Iniciando $($myinvocation.mycommand)"
                $gpm = New-Object -ComObject "GPMGMT.GPM"
                $gpmConstants = $gpm.GetConstants()
            }
            Process {
                $getParams = @{Current = "LoggedonUser"; ErrorAction = "Stop" }
                if ($Server) {
                    $getParams.Add("Server", $Server)
                }
                if ( -Not $PSBoundParameters.ContainsKey("Domain")) {
                    Write-Verbose "Dominio de consulta"
                    Try {
                        $Domain = (Get-ADDomain @getParams).DNSRoot
                    } Catch {
                        Write-Warning "Falha ao consultar o dominio. $($_.exception.message)"
                        return
                    }
                }
                Try {
                    $Forest = (Get-ADForest @getParams).Name
                } Catch {
                    Write-Warning "Falha ao consultar a floresta. $($_.exception.message)"
                    return
                }
                $gpmDomain = $gpm.GetDomain($domain, $server, $gpmConstants.UseAnyDC)
                foreach ($item in $siteName) {
                    $SiteContainer = $gpm.GetSitesContainer($forest, $domain, $null, $gpmConstants.UseAnyDC)
                    Write-Verbose "Conectado ao conteiner do site em $($SiteContainer.domainController)"
                    Write-Verbose "Recebendo $item"
                    $site = $SiteContainer.GetSite($item)
                    Write-Verbose "Encontrado $($sites.count) site(s)"
                    if ($site) {
                        Write-Verbose "Obtendo links das GPOs do site"
                        $links = $Site.GetGPOLinks()
                        if ($links) {
                            Write-Verbose "Link(s) de GPO encontrados $($links.count)"
                            foreach ($link in $links) {
                                [pscustomobject]@{
                                    GpoId       = $link.GPOId -replace ("{|}", "")
                                    DisplayName = ($gpmDomain.GetGPO($link.GPOID)).DisplayName
                                    Enabled     = $link.Enabled
                                    Enforced    = $link.Enforced
                                    Target      = $link.som.path
                                    Order       = $link.somlinkorder
                                }
                            }
                        }
                    }
                }
            }
            End {
                Write-Verbose "Finalizando $($myinvocation.MyCommand)"
            }
        }
    }
    Process {
        Write-Verbose "Como usar esses parametros vinculados"
        $PSBoundParameters | Out-String | Write-Verbose
        $targets = [System.Collections.Generic.list[string]]::new()
        if ($Server) {
            $script:PSDefaultParameterValues["Get-AD*:Server"] = $server
            $script:PSDefaultParameterValues["Get-GP*:Server"] = $Server
        }
        if ($domain) {
            $script:PSDefaultParameterValues["Get-AD*:Domain"] = $domain
            $script:PSDefaultParameterValues["Get-ADDomain:Identity"] = $domain
            $script:PSDefaultParameterValues["Get-GP*:Domain"] = $domain
        }
        Try {
            Write-Verbose "Consultando o dominio"
            $mydomain = Get-ADDomain -ErrorAction Stop
            $targets.Add($mydomain.distinguishedname)
        } Catch {
            Write-Warning "Falha ao obter informacoes de dominio. $($_.exception.message)"
            Return
        }
        if ($targets) {
            Write-Verbose "Como consultar unidades organizacionais"
            Get-ADOrganizationalUnit -Filter * |
                ForEach-Object { $targets.add($_.Distinguishedname) }
            Write-Verbose "Getting GPO links from $($targets.count) targets"
            $links = [System.Collections.Generic.list[object]]::New()
            Try {
            ($Targets | Get-GPInheritance -ErrorAction Stop).gpolinks | ForEach-Object { $links.Add($_) }
            } Catch {
                Write-Warning "Falha ao obter heranca da GPO. Se especificar um dominio, certifique-se de usar o nome DNS. $($_.exception.message)"
                return
            }
            Write-Verbose "Sites de consulta"
            $getADO = @{
                LDAPFilter = "(Objectclass=site)"
                properties = "Name"
                SearchBase = (Get-ADRootDSE).ConfigurationNamingContext
            }
            $sites = (Get-ADObject @getADO).name
            if ($sites) {
                Write-Verbose "Processando $($sites.count) site(s)"
                $sites | Get-GPSiteLink | ForEach-Object { $links.add($_) }
            }
            if ($enabled) {
                Write-Verbose "Filtrando por politicas habilitadas"
                $links = $links.where( { $_.enabled })
            } elseif ($Disabled) {
                Write-Verbose "Filtrando por politicas desabilitadas"
                $links = $links.where( { -Not $_.enabled })
            }
            if ($Name) {
                Write-Verbose "Filtrando por nome da GPO como $name"
                $results = $links.where({ $_.displayname -like "$name" })
            } else {
                Write-Verbose "Exibindo TODOS os links das GPOs"
                $results = $links
            }
            if ($results) {
                $results.GetEnumerator().ForEach( { $_.psobject.TypeNames.insert(0, "myGPOLink") })
                $results
            } else {
                Write-Warning "Falha ao encontrar qualquer GPO usando um nome como $Name"
            }
        }
    }
    End {
        Write-Verbose "Final $($myinvocation.mycommand)"
    }
}