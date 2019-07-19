<#
.SYNOPSIS
    Add an Install Behavior to a Configuration Manager Deployment Type
.DESCRIPTION
    Cmdlet missing for Install Behavior tab for deployment types. The following code takes a file name and display name and adds them to the 
    chosen deployment type. Function only changes the first deployment type (if there's more than one.)

.PARAMETER SiteCode
    Configuration manager site code. e.g. CM1
.PARAMETER ProviderMachineName
    SMS Provider machine name. e.g. server.contoso.com
.PARAMETER CMApplicationName
    Configuration manager application to add Install Behavior
.PARAMETER ProcessDisplayName
    Display Name for Install Behavior. e.g. Google Chrome
.PARAMETER FileName
    Executable File name. e.g. chrome.exe

.INPUTS
    None
.OUTPUTS
    None

.NOTES
  Version:        1.0
  Author:         Nick L
  Creation Date:  19 July 2019
  Purpose/Change: Initial script development

  TODO: 1. Need to look at clearing all behavior types
        2. Allow for list of behavior types to add


.EXAMPLE
    Add-InstallBehavior -SiteCode CM1 -ProviderMachineName "server.contoso.com" -CMApplicationName "Adobe Flash Player 32.0.0.223 NPAPI" -ProcessDisplayName "Mozilla Firefox" -FileName "firefox.exe
#>


function Add-InstallBehavior {
    param (
        [Parameter(Mandatory)]
        [string]$SiteCode,
        [Parameter(Mandatory)]
        [string]$ProviderMachineName,
        [Parameter(Mandatory)]
        [string]$CMApplicationName,
        [Parameter(Mandatory)]
        [string]$ProcessDisplayName,
        [Parameter(Mandatory)]
        [string]$FileName
    )

    $initParams = @{}
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }

    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    Set-Location "$($SiteCode):\" @initParams

    $CurrentApplication = Get-CMApplication -Name $CMApplicationName

    $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($CurrentApplication.SDMPackageXML, $true)
    $DeploymentType = $ApplicationXML.DeploymentTypes[0]

    $PDN = New-Object -TypeName "Microsoft.ConfigurationManagement.ApplicationManagement.ProcessDisplayName"
    $PDN.DisplayName = $ProcessDisplayName
    $PDN.IsChanged = $false
    $PDN.Language = ""

    #$DeploymentType.Installer.InstallProcessDetection.ProcessList.clear()
    $ProcessList = New-Object -TypeName "Microsoft.ConfigurationManagement.ApplicationManagement.ProcessInformation"
    $ProcessList.Name = $FileName
    $ProcessList.DisplayInfo.add($PDN)
    $DeploymentType.Installer.InstallProcessDetection.ProcessList.add($ProcessList)

    $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ApplicationXML, $true)
    # Update WMI object
    Write-Output "Attempting to update SDMPackageXML"
    $CurrentApplication.SDMPackageXML = $UpdatedXML
    $CurrentApplication.Put()
}


