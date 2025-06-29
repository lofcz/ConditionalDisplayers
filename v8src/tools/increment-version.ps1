[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot
)

$packageXmlPath = Join-Path $ProjectRoot "src\package.xml"
$nuspecPath = Join-Path $ProjectRoot "src\ConditionalDisplayers.nuspec"

# Read the package.xml
try {
    [xml]$packageXml = Get-Content $packageXmlPath
} catch {
    Write-Error "Failed to read or parse $packageXmlPath"
    exit 1
}

# Get the version
$version = $packageXml.umbPackage.info.package.version

# Split, increment, and join
$versionParts = $version.Split('.')
if ($versionParts.Length -ne 3) {
    Write-Error "Version '$version' is not in a valid Major.Minor.Patch format."
    exit 1
}

$buildNumber = [int]$versionParts[2] + 1
$versionParts[2] = $buildNumber.ToString()
$newVersion = $versionParts -join '.'

# Set the new version in package.xml
$packageXml.umbPackage.info.package.version = $newVersion
$packageXml.Save($packageXmlPath)
Write-Verbose "Updated version in $packageXmlPath to $newVersion"

# Set the new version in nuspec
try {
    [xml]$nuspecXml = Get-Content $nuspecPath
} catch {
    Write-Error "Failed to read or parse $nuspecPath"
    exit 1
}
$nuspecXml.package.metadata.version = $newVersion
$nuspecXml.Save($nuspecPath)
Write-Verbose "Updated version in $nuspecPath to $newVersion"

# Return the new version
Write-Output $newVersion 