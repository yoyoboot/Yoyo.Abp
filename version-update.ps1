[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$Version,

	[string]$CommonPropsPath = (Join-Path $PSScriptRoot 'common.props')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'tools\yoyo-abp-migration\YoyoAbpVersioning.ps1')

Set-CommonPropsVersion -CommonPropsPath $CommonPropsPath -Version $Version
Write-Output (Get-CommonPropsVersion -CommonPropsPath $CommonPropsPath)