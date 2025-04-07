<#
----------------------------------------------------------------------
SCRIPT DE LIMPEZA DE CONTAS DE WINDOWS SERVER PARA MULTIPLOS DOMÍNIOS
----------------------------------------------------------------------

.PRÉ-REQUISITOS

Rodar os comandos abaixo para gerar a credencial de cada domínio e salvar em arquivo criptografado

$cred = Get-Credential
$cred | Export-Clixml -Path "C:\path\to\cred\domain1_cred.xml"

#>


# Lista de domínios, caminhos para os arquivos de credenciais e controladores de domínio

$domains = @{
    "domain1.com" = @{
        "CredentialPath" = "C:\path\to\domain1_cred.xml"
        "DomainController" = "dc.domain1.com"
    }
    "domain2.com" = @{
        "CredentialPath" = "C:\path\to\domain2_cred.xml"
        "DomainController" = "dc.domain2.com"
    }
    "domain3.com" = @{
        "CredentialPath" = "C:\path\to\domain3_cred.xml"
        "DomainController" = "dc.domain3.com"
    }
}

# Define o período de inatividade em dias

$daysInactive = 60
$inactiveDate = (Get-Date).AddDays(-$daysInactive)

# Importa as credenciais do arquivo

foreach ($domain in $domains.Keys) {
    $cred = Import-Clixml -Path $domains[$domain]["CredentialPath"]
    $domainController = $domains[$domain]["DomainController"]

    # Verifica se o controlador de domínio foi obtido corretamente
    if (-not [string]::IsNullOrEmpty($domainController)) {

        # Define o contexto do domínio
        $domainContext = "DC=" + ($domain -replace '\.', ',DC=')

        # Captura o hostname dos servidores inativos comparando LastLogonTimeStamp x PasswordLastSet e ignora os objectos duplicados
        $computers = Get-ADComputer -Server $domainController -Credential $cred -SearchBase $domainContext -Filter { (OperatingSystem -like "*Server*") } -Properties LastLogonTimestamp, PwdLastSet, OperatingSystem, DistinguishedName | Where-Object {
            $lastLogon = [datetime]::FromFileTime($_.LastLogonTimestamp)
            $pwdLastSet = [datetime]::FromFileTime($_.PwdLastSet)
            $mostRecent = if ($lastLogon -gt $pwdLastSet) { $lastLogon } else { $pwdLastSet }
            $mostRecent -lt $inactiveDate -and $_.OperatingSystem -like "*Windows*"
        } | Where-Object { $_.Name -NotLike "*CNF:*" }

        # Cria o modelo de processo de exclusão capturando os campos usando o foreach
        foreach ($computer in $computers) {

            # Captura todos os campos antes da exclusão
            $Name = $computer.Name
            $OS = $computer.OperatingSystem
            $OU = $computer.DistinguishedName.Split(',')[1].split('=')[1]
            $domainName = ($computer.DistinguishedName -split ',' -match '^DC=' -replace '^DC=', '') -join '.'
            $LastLogonTime = [datetime]::FromFileTime($computer.LastLogonTimestamp)
            $PwdLastSetTime = [datetime]::FromFileTime($computer.PwdLastSet)
            $mostRecent = if ($LastLogonTime -gt $PwdLastSetTime) { $LastLogonTime } else { $PwdLastSetTime }
            $namedel = $computer.Name + "*"

            # Realiza a exclusão da conta
            Remove-ADComputer -Identity $computer -Server $domainController -Credential $cred -Confirm:$False

            # Captura os campos após a exclusão para confirmar se foi deletado e data da execução
            $IsDeleted = (Get-ADObject -Filter "name -like '$namedel'" -Server $domainController -Credential $cred -IncludeDeletedObjects -Properties IsDeleted).Deleted
            $WhenDeleted = (Get-ADObject -Filter "name -like '$namedel'" -Server $domainController -Credential $cred -IncludeDeletedObjects -Properties WhenChanged).WhenChanged

            # Cria a estrutura para export do processo em CSV
            New-Object -TypeName PSCustomObject -Property @{
                Name = $Name
                OS = $OS
                Domain = $domainName
                LastLogonTimestamp = $LastLogonTime
                PwdLastSet = $PwdLastSetTime
                MostRecent = $mostRecent
                OU = $OU
                Deleted = $IsDeleted
                DateExclude = $WhenDeleted
            } | Export-Csv -Path C:\path\sanitizacao.csv -NoTypeInformation -Append
        }
    } else {
        Write-Host "Controlador de domínio não encontrado para $domain"
    }
}
