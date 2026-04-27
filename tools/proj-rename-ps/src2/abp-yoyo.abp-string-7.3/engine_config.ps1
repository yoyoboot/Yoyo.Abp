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

function Assert-StringArrayProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [switch]$AllowEmpty
    )

    if (!($Config.ContainsKey($PropertyName))) {
        throw "Invalid migration config '$ConfigPath': missing required property '$PropertyName'."
    }

    $values = $Config[$PropertyName]
    if (-not (Test-IsJsonArrayLike -Value $values)) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must be an array."
    }

    if (!$AllowEmpty -and $values.Count -eq 0) {
        throw "Invalid migration config '$ConfigPath': property '$PropertyName' must not be empty."
    }

    foreach ($value in $values) {
        if (-not (Test-IsNonEmptyString -Value $value)) {
            throw "Invalid migration config '$ConfigPath': property '$PropertyName' must contain only non-empty strings."
        }
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

    Assert-StringArrayProperty -Config $Config -PropertyName $PropertyName -ConfigPath $ConfigPath
}

function Assert-OptionalStringArrayProperty {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (!($Config.ContainsKey($PropertyName))) {
        return
    }

    Assert-StringArrayProperty -Config $Config -PropertyName $PropertyName -ConfigPath $ConfigPath -AllowEmpty
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
        Assert-RequiredNonEmptyStringProperty -Config $generation -PropertyName 'profile' -ConfigPath $ConfigPath
        Assert-OptionalStringArrayProperty -Config $generation -PropertyName 'stageKeepProjects' -ConfigPath $ConfigPath
    }
}

function Assert-LibraryProfileConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'libraryProjects' -ConfigPath $ConfigPath
    Assert-RequiredNonEmptyStringArrayProperty -Config $Config -PropertyName 'packProjects' -ConfigPath $ConfigPath
}

function Assert-TestProfileConfig {
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

function Get-LibraryProfileByName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileName,

        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    $fileName = "library-profile-$ProfileName.json"
    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName $fileName -Validator {
        param($config, $path)
        Assert-LibraryProfileConfig -Config $config -ConfigPath $path
    })
}

function Get-TestProfileByName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileName,

        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    $fileName = "test-profile-$ProfileName.json"
    return (Read-MigrationJsonFile -ConfigRoot $ConfigRoot -FileName $fileName -Validator {
        param($config, $path)
        Assert-TestProfileConfig -Config $config -ConfigPath $path
    })
}

function Get-LibraryProfile33Compat {
    param(
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return (Get-LibraryProfileByName -ProfileName '33-compat' -ConfigRoot $ConfigRoot)
}

function Get-TestProfile33Compat {
    param(
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return (Get-TestProfileByName -ProfileName '33-compat' -ConfigRoot $ConfigRoot)
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

function Get-VersionFromCommonProps {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $commonPropsPath = Join-Path $RootPath 'common.props'
    if (!(Test-Path -LiteralPath $commonPropsPath)) {
        throw "Missing common.props under migration source root: $commonPropsPath"
    }

    [xml]$xml = Get-Content -LiteralPath $commonPropsPath -Encoding UTF8
    $versionNode = $xml.SelectSingleNode('//Version')
    if ($null -eq $versionNode -or [string]::IsNullOrWhiteSpace($versionNode.'#text')) {
        throw "common.props does not contain a Version node: $commonPropsPath"
    }

    return $versionNode.'#text'.Trim()
}

function Normalize-VersionTag {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    if ($Version.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Version
    }

    return 'v' + $Version
}

function Get-MigrationGenerationSelection {
    param(
        [string]$SourceRoot,
        [string]$Version,
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    if (-not (Test-IsNonEmptyString -Value $Version)) {
        if (-not (Test-IsNonEmptyString -Value $SourceRoot)) {
            throw 'Get-MigrationGenerationSelection requires either -Version or -SourceRoot.'
        }

        $Version = Get-VersionFromCommonProps -RootPath $SourceRoot
    }

    $matrix = Get-VersionGenerationMatrix -ConfigRoot $ConfigRoot
    $normalizedVersion = Normalize-VersionTag -Version $Version
    $matches = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($generation in @($matrix['generations'])) {
        $tagPrefixes = @($generation['tagPrefixes'])
        foreach ($tagPrefix in $tagPrefixes) {
            if (-not (Test-IsNonEmptyString -Value $tagPrefix)) {
                continue
            }

            $normalizedPrefix = Normalize-VersionTag -Version $tagPrefix
            if ($normalizedVersion.StartsWith($normalizedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $matches.Add(@{
                    generation = $generation
                    normalizedPrefix = $normalizedPrefix
                })
            }
        }
    }

    if ($matches.Count -eq 0) {
        throw "No generation mapping matched upstream version '$Version' using $(Join-Path $ConfigRoot 'version-generations.json')"
    }

    $maxPrefixLength = ($matches | ForEach-Object { $_['normalizedPrefix'].Length } | Measure-Object -Maximum).Maximum
    $bestMatches = @($matches | Where-Object { $_['normalizedPrefix'].Length -eq $maxPrefixLength })
    $bestGenerationNames = @(
        $bestMatches |
            ForEach-Object { $_['generation']['name'] } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    if ($bestGenerationNames.Count -gt 1) {
        $matchedPrefixes = @(
            $bestMatches |
                ForEach-Object { "{0} ({1})" -f $_['generation']['name'], $_['normalizedPrefix'] } |
                Sort-Object -Unique
        )

        throw "Ambiguous generation mapping matched upstream version '$Version' using $(Join-Path $ConfigRoot 'version-generations.json'). Longest matching prefixes: $($matchedPrefixes -join ', ')"
    }

    $selectedGeneration = $bestMatches[0]['generation']
    $profileName = if ($selectedGeneration.ContainsKey('profile') -and (Test-IsNonEmptyString -Value $selectedGeneration['profile'])) {
        $selectedGeneration['profile']
    }
    else {
        $matrix['defaultProfile']
    }

    $stageKeepProjects = if ($selectedGeneration.ContainsKey('stageKeepProjects')) {
        @($selectedGeneration['stageKeepProjects'])
    }
    else {
        @()
    }

    return @{
        version = $Version
        versionTag = $normalizedVersion
        generation = $selectedGeneration['name']
        targetFramework = $selectedGeneration['targetFramework']
        riskNotes = @($selectedGeneration['riskNotes'])
        profile = $profileName
        stageKeepProjects = @($stageKeepProjects)
    }
}

function Get-MigrationStageKeepProjects {
    param(
        [string]$SourceRoot,
        [string]$Version,
        [string]$ConfigRoot = (Get-MigrationConfigRoot)
    )

    return @((Get-MigrationGenerationSelection -SourceRoot $SourceRoot -Version $Version -ConfigRoot $ConfigRoot)['stageKeepProjects'])
}
