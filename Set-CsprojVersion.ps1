<#
.SYNOPSIS
    Set versions elements in Dotnet Core .CSPROJ files.
.DESCRIPTION
    Update value for version elements <Version>, <VersionPrefix>, <VersionSuffix> and <PackageVersion> in the specified .CSPROJ file.
    Individual segments of version can be updated explicitly or patch and revision segments can incremented or auto generated.
    NOTE: Version elements will only be updated if they exist in the project file (XML).
.PARAMETER path
    The path to the .csproj file to update (REQUIRED).
.PARAMETER major
    Define/override major segment (1st) of version. Otherwise will use existing.
.PARAMETER minor
    Define/override minor segment (2nd) of version. Otherwise will use existing if exists or 0 if not defined or existing.
.PARAMETER patch
    Define/override patch segment (3rd) of version. Otherwise will use existing if exists. To remove this segment use -1.
.PARAMETER revision
    Define/override revision segment (4th) of version. Otherwise will use existing if exists. To remove this segment use -1.
.PARAMETER prerelease
    Prerelease suffix - textual description of prerelease build state.
    e.g. alpha, beta, preview, prerelease, rc.1, preview3. 
    A leading hyphen is not required.
.PARAMETER incrementpatch
    Switch to auto increment patch segment if exists.
.PARAMETER incrementrevision
    Switch to auto increment revision segment if exists.
.PARAMETER autopatchandrevision
    Switch to auto generate patch and revision segments.
    Patch is generated as the month since 2015.
    Revision is generated as total minutes of current month.
.PARAMETER autorevision
    Switch to auto generate revision segment.
    Revision is generated as total minutes of current month. Max value: 44640.
.EXAMPLE
    Set-CsprojVersion.ps1 -path MyProject.csproj -autopatchandrevision
    <Version>1.5.0</Version> updated to <Version>1.5.7.28349</Version>
.EXAMPLE
    Set-CsprojVersion.ps1 -path MyProject.csproj -incrementrevision
    <Version>1.2.0.12</Version> updated to <Version>1.2.0.13</Version>
.EXAMPLE
    Set-CsprojVersion.ps1 -path MyProject.csproj -patch 2 -prerelease alpha
    <Version>2.6.1</Version> updated to <Version>2.6.2-alpha</Version>
.EXAMPLE
    Set-CsprojVersion.ps1 -path MyProject.csproj -prerelease -1 -incrementpatch -revision 0
    <Version>3.1.3.8-beta2</Version> updated to <Version>3.1.4.0</Version>
.EXAMPLE
    Set-CsprojVersion.ps1 -path MyProject.csproj -major 2 -minor 3 -build 1 -revision -1
    <Version>1.2.1.27126</Version> updated to <Version>2.3.1</Version> 
.NOTES
    Author: Michael Sivers
    Date:   29th July 2018
#>


param([string]$path="", [string]$major, [string]$minor, [string]$patch, [string]$revision, [string]$prerelease, [switch]$incrementpatch, [switch]$incrementrevision, [switch]$autopatchandrevision, [switch]$autorevision)


if ([string]::IsNullOrEmpty($path))
{
    Write-Error "Path parameter not provided."
    exit 1
}

$autoPatchValue = [int](Get-Date -UFormat %m)
$autoRevisionValue = (([int](Get-Date -UFormat %d) - 1) * 1440) + ([int](Get-Date -UFormat %H) * 60) + ([int](Get-Date -UFormat %M))

# Remove leading hyphen from prerelease param if provided
if (-Not [string]::IsNullOrEmpty($prerelease) -and $prerelease.StartsWith("-"))
{ 
    if ($prerelease -ne "-1") { $prerelease = $prerelease -replace "^-" }
}


function FormatVersion
{
    param( $elm ) # Version XML Element

    $elmContent = $elm.InnerText

    $hasMatch = $elmContent -match "[^-]*" # Match version prefix
    $vParts = if ($hasMatch) { $matches[0] -split '\.' }

    $hasMatch = $elmContent -match "-(.*)" # Match version suffix (prerelease)
    $vPrerelease = if ($hasMatch) { $matches[0] -replace "^-" }
    
    # Get existing segment values or set segments to null
    $majorSeg = if (-Not [string]::IsNullOrEmpty($vParts[0])) { $vParts[0] } else { $null }
    $minorSeg = if (-Not [string]::IsNullOrEmpty($vParts[1])) { "." + $vParts[1] } else { $null }
    $patchSeg = if (-Not [string]::IsNullOrEmpty($vParts[2])) { "." + $vParts[2] } else { $null }
    $revisionSeg = if (-Not [string]::IsNullOrEmpty($vParts[3])) { "." + $vParts[3] } else { $null }
    $prereleaseSeg = if (-Not [string]::IsNullOrEmpty($vPrerelease)) { "-" + $vPrerelease } else { $null }

    # Override segment with parameter if provided (or use default for major or minor)
    if (-Not [string]::IsNullOrEmpty($major)) { $majorSeg = $major } else { if ($majorSeg -eq $null) { $majorSeg = ".1" } }
    if (-Not [string]::IsNullOrEmpty($minor)) { $minorSeg = ".$minor" } else { if ($minorSeg -eq $null) { $minorSeg = ".0" } }
    if (-Not [string]::IsNullOrEmpty($patch)) { $patchSeg = ".$patch" }
    if (-Not [string]::IsNullOrEmpty($revision)) { $revisionSeg = ".$revision" }
    if (-Not [string]::IsNullOrEmpty($prerelease)) { $prereleaseSeg = "-$prerelease" }
    
    # Removals elements
    if ($patch -eq "-1") { $buildSeg = "" }
    if ($revision -eq "-1") { $revisionSeg = "" }
    if ($prerelease -eq "-1") { $prereleaseSeg = "" }

    # Auto increments
    if ($incrementpatch) { if ($patchSeg -ne $null) { $patchSeg = "." + ([int]($patchSeg -replace "^\.") + 1) } else { $patchSeg = ".0" } }
    if ($incrementrevision) { if ($revisionSeg -ne $null) { $revisionSeg = "." + ([int]($revisionSeg -replace "^\.") + 1) } else { $revisionSeg = ".0" } }

    # Auto generation
    if ($autorevision -eq $true) { $revisionSeg = ".$autoRevisionValue" }
    if ($autopatchandrevision -eq $true) { $patchSeg = ".$autoPatchValue"; $revisionSeq = ".$autoRevisionValue" }

    Switch ($elm.Name) {
        "VersionPrefix" { "$majorSeg$minorSeg$patchSeg$revisionSeg" }
        default { "$majorSeg$minorSeg$patchSeg$revisionSeg$prereleaseSeg" }
    }
}

$xml = New-Object XML
$xml.Load($path)

$version =  $xml.SelectSingleNode("//Version")
$versionPrefix =  $xml.SelectSingleNode("//VersionPrefix")
$versionSuffix =  $xml.SelectSingleNode("//VersionSuffix")
$packageVersion =  $xml.SelectSingleNode("//PackageVersion")

if (-Not [string]::IsNullOrEmpty($version))
{
    $version.InnerText = FormatVersion -elm $version
}

if (-Not [string]::IsNullOrEmpty($versionPrefix))
{
    $versionPrefix.InnerText = FormatVersion -elm $versionPrefix
}

if (-Not [string]::IsNullOrEmpty($versionSuffix))
{
    if (-Not [string]::IsNullOrEmpty($prerelease))
    {
        if ($prerelease -eq "-1") 
        { 
            $versionSuffix.InnerText = ""
        }
        else
        {
            $versionSuffix.InnerText = $prerelease
        }
    }
}

if (-Not [string]::IsNullOrEmpty($packageVersion))
{
    $packageVersion.InnerText = FormatVersion -elm $packageVersion
}

$xml.Save($path)