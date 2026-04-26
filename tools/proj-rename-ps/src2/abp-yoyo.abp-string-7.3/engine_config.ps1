Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsNonEmptyString {
    param(
        [object]$Value
    )

    return $Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value)
}

function Test-IsJsonArrayLike {
    param(
        [object]$Value
    )

    return $null -ne $Value -and $Value -is [System.Collections.IList] -and $Value -isnot [string]
}

function Assert-MigrationConfigRootObject {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if ($Config -isnot [hashtable]) {
        throw "Invalid migration config '$ConfigPath': root JSON value must be an object."
    }
}

function Assert-RequiredNonEmptyStringProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "Invalid migration config '$ConfigPath': missing required property '$PropertyName'."
    }

    if (-not (Test-IsNonEmptyString -Value $Config[$PropertyName])) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must be a non-empty string."
    }
}

function Assert-RequiredNonEmptyStringArrayProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "Invalid migration config '$ConfigPath': missing required property '$PropertyName'."
    }

    $values = $Config[$PropertyName]
    if (-not (Test-IsJsonArrayLike -Value $values)) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must be an array."
    }

    if ($values.Count -eq 0) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must not be empty."
    }

    foreach ($value in $values) {
        if (-not (Test-IsNonEmptyString -Value $value)) {
            throw "Invalid migration config '$ConfigPath': property '$PropertyName' must contain only non-empty strings."
        }
    }
}

function Assert-RequiredGenerationArray {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "Invalid migration config '$ConfigPath': missing required property '$PropertyName'."
    }

    $generations = $Config[$PropertyName]
    if (-not (Test-IsJsonArrayLike -Value $generations)) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must be an array."
    }

    if ($generations.Count -eq 0) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must not be empty."
    }

    for ($index = 0; $index -lt $generations.Count; $index++) {
        $generation = $generations[$index]
        if ($generation -isnot [hashtable]) {
            throw "Invalid migration config '$ConfigPath': property '$PropertyName' entry [$index] must be an object."
        }

        Assert-RequiredNonEmptyStringProperty -Config $generation -PropertyName 'name' -ConfigPath $ConfigPath
        Assert-RequiredNonEmptyStringArrayProperty -Config $generation -PropertyName 'tagPrefixes' -ConfigPath $ConfigPath
        Assert-RequiredNonEmptyStringProperty -Config $generation -PropertyName 'targetFramework' -ConfigPath $ConfigPath
    }
}

function Assert-LibraryProfile33CompatConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'libraryProjects' -ConfigPath $ConfigPath
    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'packProjects' -ConfigPath $ConfigPath
}

function Assert-TestProfile33CompatConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'testProjects' -ConfigPath $ConfigPath
}

function Assert-LegacyPackageExclusionsConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'exactProjectNames' -ConfigPath $ConfigPath
    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'tokenPatterns' -ConfigPath $ConfigPath
}

function Assert-VersionGenerationMatrixConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    Assert-RequiredNonEmptyStringProperty -Config $Config -PropertyName 'defaultProfile' -ConfigPath $ConfigPath
    Assert-RequiredGenerationArray -Config $Config -PropertyName 'generations' -ConfigPath $ConfigPath
}

function Get-MigrationConfigRoot {
    param(
        [string]$ScriptRoot = $PSScriptRoot
    )

    return (Join-Path $ScriptRoot 'config')
}

function Read-MigrationJsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigRoot,

        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [scriptblock]$Validator = $null
    )

    $path = Join-Path $ConfigRoot $FileName
    if (!(Test-Path -LiteralPath $path)) {
        throw "Missing migration config file: $path"
    }

    try {
        $config = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    }
    catch {
        throw "Failed to parse migration config JSON: $path. $($_.Exception.Message)"
    }

    Assert-MigrationConfigRootObject -Config $config -ConfigPath $path

    if ($null -ne $Validator) {
        & $Validator $config $path
    }

    return $config
}

function Get-LibraryProfile33Compat {
    param(
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'library-profile-33-compat.json' -Validator {
        param($config, $path)
        Assert-LibraryProfile33CompatConfig -Config $config -ConfigPath $path
    })
}

function Get-TestProfile33Compat {
    param(
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'test-profile-33-compat.json' -Validator {
        param($config, $path)
        Assert-TestProfile33CompatConfig -Config $config -ConfigPath $path
    })
}

function Get-VersionGenerationMatrix {
    param(
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'version-generations.json' -Validator {
        param($config, $path)
        Assert-VersionGenerationMatrixConfig -Config $config -ConfigPath $path
    })
}

function Get-LegacyPackageExclusions {
    param(
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName 'legacy-package-exclusions.json' -Validator {
        param($config, $path)
        Assert-LegacyPackageExclusionsConfig -Config $config -ConfigPath $path
    })
}
