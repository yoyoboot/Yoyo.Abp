[CmdletBinding()]
param(
	[string]$CommonPropsPath = (Join-Path $PSScriptRoot 'common.props')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'tools\yoyo-abp-migration\YoyoAbpVersioning.ps1')

Write-Output (Get-CommonPropsVersion -CommonPropsPath $CommonPropsPath)
