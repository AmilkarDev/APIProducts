param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$SqlServerName,

    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,

    [Parameter(Mandatory = $true)]
    [string]$WebAppName
)

$ErrorActionPreference = "Stop"

$principalId = az webapp identity show `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --query principalId `
    --output tsv

if ([string]::IsNullOrWhiteSpace($principalId)) {
    throw "The Web App managed identity could not be found."
}

$sidBytes = ([Guid]$principalId).ToByteArray()
$sid = "0x" + (($sidBytes | ForEach-Object { $_.ToString("X2") }) -join "")

$accessToken = az account get-access-token `
    --resource "https://database.windows.net/" `
    --query accessToken `
    --output tsv

Write-Output "::add-mask::$accessToken"

$query = @"
IF DATABASE_PRINCIPAL_ID(N'$WebAppName') IS NULL
BEGIN
    CREATE USER [$WebAppName] WITH SID = $sid, TYPE = E;
END;

IF IS_ROLEMEMBER(N'db_datareader', N'$WebAppName') <> 1
BEGIN
    ALTER ROLE db_datareader ADD MEMBER [$WebAppName];
END;

IF IS_ROLEMEMBER(N'db_datawriter', N'$WebAppName') <> 1
BEGIN
    ALTER ROLE db_datawriter ADD MEMBER [$WebAppName];
END;
"@

Invoke-Sqlcmd `
    -ServerInstance "$SqlServerName.database.windows.net" `
    -Database $DatabaseName `
    -AccessToken $accessToken `
    -Encrypt Mandatory `
    -Query $query
