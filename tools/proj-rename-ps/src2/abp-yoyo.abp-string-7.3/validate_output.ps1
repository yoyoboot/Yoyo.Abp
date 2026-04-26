Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RelativePathText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetRelativePath(
        [System.IO.Path]::GetFullPath($RootPath),
        [System.IO.Path]::GetFullPath($Path)
    )
}

function Throw-ValidationFailure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Summary,

        [string[]]$Examples = @()
    )

    $message = "Validation failed [$Category]: $Summary"

    if ($Examples -and $Examples.Count -gt 0) {
        $message += [Environment]::NewLine
        $message += 'Examples:'
        $message += [Environment]::NewLine
        $message += (($Examples | Select-Object -First 8 | ForEach-Object { " - $_" }) -join [Environment]::NewLine)
    }

    throw $message
}

function Get-SetDifference {
    param(
        [string[]]$ReferenceItems,
        [string[]]$CandidateItems
    )

    $candidateSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($candidateItem in $CandidateItems) {
        if (![string]::IsNullOrWhiteSpace($candidateItem)) {
            [void]$candidateSet.Add($candidateItem)
        }
    }

    $missingItems = New-Object System.Collections.Generic.List[string]
    foreach ($referenceItem in $ReferenceItems) {
        if (![string]::IsNullOrWhiteSpace($referenceItem) -and -not $candidateSet.Contains($referenceItem)) {
            $missingItems.Add($referenceItem)
        }
    }

    return [string[]]($missingItems.ToArray())
}

function Get-CsprojFiles {
    param(
        [string[]]$Roots
    )

    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($root in $Roots) {
        if (!(Test-Path -LiteralPath $root)) {
            continue
        }

        foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.csproj') {
            $files.Add($file)
        }
    }

    return [System.IO.FileInfo[]]($files.ToArray())
}

function Get-PackProjectNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackScriptPath
    )

    if (!(Test-Path -LiteralPath $PackScriptPath)) {
        Throw-ValidationFailure -Category 'PackageSurface' -Summary "Generated nupkg/pack.ps1 was not found: $PackScriptPath"
    }

    $projectNames = New-Object System.Collections.Generic.List[string]
    $insideProjectList = $false

    foreach ($line in Get-Content -LiteralPath $PackScriptPath -Encoding UTF8) {
        if (-not $insideProjectList) {
            if ($line -match '^\s*\$projects\s*=\s*@?\(\s*$') {
                $insideProjectList = $true
            }

            continue
        }

        if ($line -match '^\s*\)\s*$') {
            break
        }

        $match = [regex]::Match($line, '"([^"]+)"')
        if ($match.Success) {
            $projectNames.Add($match.Groups[1].Value.Trim())
        }
    }

    if ($projectNames.Count -eq 0) {
        Throw-ValidationFailure -Category 'PackageSurface' -Summary "Unable to extract project list from generated pack script: $PackScriptPath"
    }

    return [string[]]($projectNames.ToArray())
}

function Assert-SolutionHasNoStaleProjectReferences {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src
    )

    $solutionPath = Join-Path $Src 'Abp.sln'
    if (!(Test-Path -LiteralPath $solutionPath)) {
        Throw-ValidationFailure -Category 'SolutionStaleReference' -Summary "Generated solution file was not found: $solutionPath"
    }

    $solutionContent = Get-Content -LiteralPath $solutionPath -Raw -Encoding UTF8
    $projectMatches = [regex]::Matches($solutionContent, 'Project\(".*?"\)\s*=\s*".*?",\s*"([^"]+\.csproj)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $missingProjectPaths = New-Object System.Collections.Generic.List[string]
    foreach ($projectMatch in $projectMatches) {
        $relativeProjectPath = $projectMatch.Groups[1].Value -replace '[\\/]', [System.IO.Path]::DirectorySeparatorChar
        $projectPath = Join-Path $Src $relativeProjectPath

        if (!(Test-Path -LiteralPath $projectPath)) {
            $missingProjectPaths.Add($projectMatch.Groups[1].Value)
        }
    }

    if ($missingProjectPaths.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'SolutionStaleReference' `
            -Summary "Generated Abp.sln still contains stale project references ($($missingProjectPaths.Count) missing). This usually means legacy projects were removed from disk but left in the solution." `
            -Examples ($missingProjectPaths | Sort-Object -Unique)
    }
}

function Assert-PackageIdentity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src
    )

    $csprojFiles = Get-CsprojFiles -Roots @(Join-Path $Src 'src')
    $invalidIdentities = New-Object System.Collections.Generic.List[string]

    foreach ($csprojFile in $csprojFiles) {
        $content = Get-Content -LiteralPath $csprojFile.FullName -Raw -Encoding UTF8

        foreach ($packageIdMatch in [regex]::Matches($content, '<PackageId>\s*([^<]+?)\s*</PackageId>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $packageId = $packageIdMatch.Groups[1].Value.Trim()
            if ($packageId.StartsWith('Abp', [System.StringComparison]::OrdinalIgnoreCase) -and -not $packageId.StartsWith('Yoyo.Abp', [System.StringComparison]::OrdinalIgnoreCase)) {
                $invalidIdentities.Add("$(Get-RelativePathText -RootPath $Src -Path $csprojFile.FullName) => PackageId=$packageId")
            }
        }

        foreach ($assemblyNameMatch in [regex]::Matches($content, '<AssemblyName>\s*([^<]+?)\s*</AssemblyName>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $assemblyName = $assemblyNameMatch.Groups[1].Value.Trim()
            if ($assemblyName.StartsWith('Abp', [System.StringComparison]::OrdinalIgnoreCase) -and -not $assemblyName.StartsWith('Yoyo.Abp', [System.StringComparison]::OrdinalIgnoreCase)) {
                $invalidIdentities.Add("$(Get-RelativePathText -RootPath $Src -Path $csprojFile.FullName) => AssemblyName=$assemblyName")
            }
        }
    }

    if ($invalidIdentities.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'PackageIdentity' `
            -Summary 'Generated src/*.csproj still exposes legacy Abp package identities. Expected PackageId/AssemblyName values to be renamed to Yoyo.Abp.*.' `
            -Examples ($invalidIdentities | Sort-Object -Unique)
    }
}

function Assert-TargetFrameworkCompatibility {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src
    )

    $csprojFiles = Get-CsprojFiles -Roots @(
        (Join-Path $Src 'src'),
        (Join-Path $Src 'test')
    )
    $rootCompatibilityFiles = @(
        Get-ChildItem -LiteralPath $Src -File | Where-Object { $_.Extension -in '.props', '.targets' }
    )
    $filesToInspect = @($csprojFiles) + @($rootCompatibilityFiles)

    $legacyFrameworkHits = New-Object System.Collections.Generic.List[string]
    $frameworkPattern = 'Microsoft\.NETFramework\.ReferenceAssemblies|<TargetFrameworkIdentifier>\s*\.NETFramework\s*</TargetFrameworkIdentifier>|TargetFrameworkIdentifier[^\r\n>]*\.NETFramework|<TargetFrameworkVersion>\s*v4(\.\d+)*\s*</TargetFrameworkVersion>|\bnet4x\b|\bnet4\d+\b|portable-net45\+win8\+wp8\+wpa81'

    foreach ($fileToInspect in $filesToInspect) {
        $content = Get-Content -LiteralPath $fileToInspect.FullName -Raw -Encoding UTF8
        $matches = [regex]::Matches($content, $frameworkPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($matches.Count -eq 0) {
            continue
        }

        $matchedFrameworks = @($matches | ForEach-Object { $_.Value } | Sort-Object -Unique)
        $legacyFrameworkHits.Add("$(Get-RelativePathText -RootPath $Src -Path $fileToInspect.FullName) => $($matchedFrameworks -join ', ')")
    }

    if ($legacyFrameworkHits.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'TargetFrameworkCompatibility' `
            -Summary 'Generated project/build files still reference removed .NET Framework / portable target frameworks. The 7.3 engine should fail before restore/build if compatibility cleanup regresses.' `
            -Examples ($legacyFrameworkHits | Sort-Object -Unique)
    }
}

function Assert-PackageSurface {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedLibraryProjectNames,

        [Parameter(Mandatory = $true)]
        [string[]]$PackProjectNames
    )

    $ExpectedLibraryProjectNames = @($ExpectedLibraryProjectNames)
    $PackProjectNames = @($PackProjectNames)

    $expectedCount = $ExpectedLibraryProjectNames.Count
    if ($expectedCount -ne 33) {
        Throw-ValidationFailure -Category 'PackageSurface' -Summary "Expected library surface drifted inside run.ps1. This validator is designed for 33 packages, but received $expectedCount."
    }

    $srcRoot = Join-Path $Src 'src'
    if (!(Test-Path -LiteralPath $srcRoot)) {
        Throw-ValidationFailure -Category 'PackageSurface' -Summary "Generated src directory was not found: $srcRoot"
    }

    $srcProjectNames = @(
        Get-ChildItem -LiteralPath $srcRoot -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ($_.Name + '.csproj')) } |
            ForEach-Object { $_.Name } |
            Sort-Object -Unique
    )

    $missingSrcProjects = @(Get-SetDifference -ReferenceItems $ExpectedLibraryProjectNames -CandidateItems $srcProjectNames)
    $extraSrcProjects = @(Get-SetDifference -ReferenceItems $srcProjectNames -CandidateItems $ExpectedLibraryProjectNames)
    $missingPackProjects = @(Get-SetDifference -ReferenceItems $ExpectedLibraryProjectNames -CandidateItems $PackProjectNames)
    $extraPackProjects = @(Get-SetDifference -ReferenceItems $PackProjectNames -CandidateItems $ExpectedLibraryProjectNames)

    if (
        $srcProjectNames.Count -ne $expectedCount -or
        $PackProjectNames.Count -ne $expectedCount -or
        $missingSrcProjects.Count -gt 0 -or
        $extraSrcProjects.Count -gt 0 -or
        $missingPackProjects.Count -gt 0 -or
        $extraPackProjects.Count -gt 0
    ) {
        $examples = New-Object System.Collections.Generic.List[string]
        foreach ($item in $missingSrcProjects) {
            $examples.Add("missing src project: $item")
        }
        foreach ($item in $extraSrcProjects) {
            $examples.Add("unexpected src project: $item")
        }
        foreach ($item in $missingPackProjects) {
            $examples.Add("missing pack entry: $item")
        }
        foreach ($item in $extraPackProjects) {
            $examples.Add("unexpected pack entry: $item")
        }

        if ($examples.Count -eq 0) {
            $examples.Add("expected package count: $expectedCount")
            $examples.Add("actual src project count: $($srcProjectNames.Count)")
            $examples.Add("actual pack project count: $($PackProjectNames.Count)")
        }

        Throw-ValidationFailure `
            -Category 'PackageSurface' `
            -Summary "Generated package surface no longer matches the expected 33-library baseline. Expected=$expectedCount, src=$($srcProjectNames.Count), pack=$($PackProjectNames.Count)." `
            -Examples @($examples)
    }
}

function Assert-LegacyPackageExclusions {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$PackProjectNames,

        [Parameter(Mandatory = $true)]
        [hashtable]$LegacyExclusionConfig
    )

    $legacyExactNames = @($LegacyExclusionConfig['exactProjectNames'])
    $legacyTokenPatterns = @($LegacyExclusionConfig['tokenPatterns'])

    $legacyProjects = New-Object System.Collections.Generic.List[string]
    foreach ($projectName in $PackProjectNames) {
        if ($legacyExactNames -contains $projectName) {
            $legacyProjects.Add($projectName)
            continue
        }

        foreach ($pattern in $legacyTokenPatterns) {
            if ($projectName -match $pattern) {
                $legacyProjects.Add($projectName)
                break
            }
        }
    }

    if ($legacyProjects.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'LegacyPackageExclusion' `
            -Summary 'Generated nupkg/pack.ps1 still contains legacy package lines that are explicitly excluded from the first-wave 33-package surface.' `
            -Examples ($legacyProjects | Sort-Object -Unique)
    }
}

function Assert-FileDoesNotContain {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ForbiddenTexts,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $fullPath = Join-Path $Src $RelativePath
    if (!(Test-Path -LiteralPath $fullPath)) {
        Throw-ValidationFailure -Category 'HighRiskRegression' -Summary "$Description file was not generated: $RelativePath"
    }

    $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    $matches = New-Object System.Collections.Generic.List[string]
    foreach ($forbiddenText in $ForbiddenTexts) {
        if ($content.Contains($forbiddenText)) {
            $matches.Add("$RelativePath => $forbiddenText")
        }
    }

    if ($matches.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'HighRiskRegression' `
            -Summary "$Description regressed back into the generated output." `
            -Examples @($matches)
    }
}

function Assert-FileContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedTexts,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $fullPath = Join-Path $Src $RelativePath
    if (!(Test-Path -LiteralPath $fullPath)) {
        Throw-ValidationFailure -Category 'HighRiskRegression' -Summary "$Description file was not generated: $RelativePath"
    }

    $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    $missingMatches = New-Object System.Collections.Generic.List[string]
    foreach ($expectedText in $ExpectedTexts) {
        if (-not $content.Contains($expectedText)) {
            $missingMatches.Add("$RelativePath => missing: $expectedText")
        }
    }

    if ($missingMatches.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'HighRiskRegression' `
            -Summary "$Description did not converge to the expected generated baseline." `
            -Examples @($missingMatches)
    }
}

function Assert-RootMetadataFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src
    )

    $requiredRootFiles = @(
        'LICENSE.md'
    )

    $missingRootFiles = New-Object System.Collections.Generic.List[string]
    foreach ($requiredRootFile in $requiredRootFiles) {
        if (!(Test-Path -LiteralPath (Join-Path $Src $requiredRootFile))) {
            $missingRootFiles.Add($requiredRootFile)
        }
    }

    if ($missingRootFiles.Count -gt 0) {
        Throw-ValidationFailure `
            -Category 'RootMetadata' `
            -Summary 'Generated output root is missing required pack/build metadata files.' `
            -Examples @($missingRootFiles)
    }
}

function Assert-KnownRegressionGuards {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src
    )

    Assert-FileDoesNotContain `
        -Src $Src `
        -RelativePath 'src\Abp.AutoMapper\AutoMapper\AutoMapExtensions.cs' `
        -ForbiddenTexts @(
            'TTranslationPrimaryKey',
            'IEntity<TTranslationPrimaryKey>'
        ) `
        -Description 'AutoMapExtensions multi-lingual generic baseline'

    Assert-FileContains `
        -Src $Src `
        -RelativePath 'test\Abp.ZeroCore.SampleApp\AbpZeroCoreSampleAppModule.cs' `
        -ExpectedTexts @(
            'CreateMultiLingualMap<Office,string, OfficeTranslation, OfficeListDto>'
        ) `
        -Description 'Office multilingual map rewrite'

    Assert-FileDoesNotContain `
        -Src $Src `
        -RelativePath 'test\Abp.ZeroCore.SampleApp\AbpZeroCoreSampleAppModule.cs' `
        -ForbiddenTexts @(
            'CreateMultiLingualMap<Office,int, OfficeTranslation, OfficeListDto>',
            'CreateMultiLingualMap<Office, int, OfficeTranslation, long, OfficeListDto>'
        ) `
        -Description 'Office multilingual map rewrite'

    Assert-FileContains `
        -Src $Src `
        -RelativePath 'test\Abp.ZeroCore.SampleApp\Application\Shop\IOfficeAppService.cs' `
        -ExpectedTexts @(
            'Repository<OfficeTranslation, string>'
        ) `
        -Description 'Office translation repository key rewrite'

    Assert-FileDoesNotContain `
        -Src $Src `
        -RelativePath 'test\Abp.ZeroCore.SampleApp\Application\Shop\IOfficeAppService.cs' `
        -ForbiddenTexts @(
            'Repository<OfficeTranslation, long>'
        ) `
        -Description 'Office translation repository key rewrite'

    Assert-FileContains `
        -Src $Src `
        -RelativePath 'test\Abp.ZeroCore.SampleApp\Core\Shop\OfficeTranslation.cs' `
        -ExpectedTexts @(
            'IEntityTranslation<Office, string>',
            'public string CoreId { get; set; }'
        ) `
        -Description 'Office translation CoreId rewrite'

    Assert-FileDoesNotContain `
        -Src $Src `
        -RelativePath 'test\Abp.ZeroCore.SampleApp\Core\Shop\OfficeTranslation.cs' `
        -ForbiddenTexts @(
            'IEntityTranslation<Office>',
            'public int CoreId { get; set; }'
        ) `
        -Description 'Office translation CoreId rewrite'
}

function Assert-MigrationOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Src,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedLibraryProjectNames,

        [Parameter(Mandatory = $true)]
        [hashtable]$LegacyExclusionConfig
    )

    if (!(Test-Path -LiteralPath $Src)) {
        Throw-ValidationFailure -Category 'OutputRoot' -Summary "Generated output root was not found: $Src"
    }

    Write-Host 'Validate migration output: solution references'
    Assert-SolutionHasNoStaleProjectReferences -Src $Src

    Write-Host 'Validate migration output: package identity'
    Assert-PackageIdentity -Src $Src

    Write-Host 'Validate migration output: target frameworks'
    Assert-TargetFrameworkCompatibility -Src $Src

    Write-Host 'Validate migration output: root metadata'
    Assert-RootMetadataFiles -Src $Src

    $packScriptPath = Join-Path $Src 'nupkg\pack.ps1'
    $packProjectNames = Get-PackProjectNames -PackScriptPath $packScriptPath

    Write-Host 'Validate migration output: package surface'
    Assert-PackageSurface -Src $Src -ExpectedLibraryProjectNames $ExpectedLibraryProjectNames -PackProjectNames $packProjectNames

    Write-Host 'Validate migration output: legacy package exclusions'
    Assert-LegacyPackageExclusions -PackProjectNames $packProjectNames -LegacyExclusionConfig $LegacyExclusionConfig

    Write-Host 'Validate migration output: known high-risk regressions'
    Assert-KnownRegressionGuards -Src $Src

    Write-Host 'Validation passed: generated migration output matches the current 7.3 baseline checks.' -ForegroundColor Green
}
