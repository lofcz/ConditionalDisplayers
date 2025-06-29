param([string] $packageId = "ConditionalDisplayers", [string]$packageDirectory = "..", [string]$buildConfiguration = "Release")

$scriptDir = $PSScriptRoot
$targetDirectory = Join-Path $scriptDir $packageDirectory
$buildConfiguration = "Release"

$workingPackageFilePath = Join-Path $targetDirectory "package-v8.xml"

Write-Host "Reading package file: $workingPackageFilePath" -ForegroundColor Yellow

if (!(Test-Path $workingPackageFilePath)) {
    Write-Host "Package file not found: $workingPackageFilePath" -ForegroundColor Red
    exit 1
}

$workingPackageFile = [xml](Get-Content $workingPackageFilePath)

$xpathForFiles = "//file"
$xpathForName = "//info/package/name"
$xpathForVersion = "//info/package/version"

$fileNodes = $workingPackageFile.SelectNodes($xpathForFiles)
$nameNode = $workingPackageFile.SelectSingleNode($xpathForName)
$versionNode = $workingPackageFile.SelectSingleNode($xpathForVersion)

$packageName = $nameNode.InnerText

$filepaths = @($workingPackageFilePath)
$version = ""

Write-Host "Processing files..." -ForegroundColor Yellow

foreach ($fileNode in $fileNodes) {
    $nameNode = $fileNode["orgName"]
    $pathNode = $fileNode["orgPath"]
	
    $name = $nameNode.InnerText
    $path = $pathNode.InnerText.Replace("/", "\").Replace("\bin", ("\bin\" + $buildConfiguration))
    $filePath = Join-Path $targetDirectory ($path + "\" + $name)
	
    Write-Host "Checking file: $filePath" -ForegroundColor Gray
	
    if (Test-Path $filePath) {
        $filepaths += $filePath
        Write-Host "Added file: $filePath" -ForegroundColor Green
    } else {
        Write-Host "File not found: $filePath" -ForegroundColor Red
    }
	
    if ($filePath.Contains($packageId + ".dll") -and [string]::IsNullOrWhiteSpace($version)) {
        try {
            $fileStream = ([System.IO.FileInfo] (Get-Item $filePath)).OpenRead();
            $assemblyBytes = new-object byte[] $fileStream.Length
            $fileStream.Read($assemblyBytes, 0, $fileStream.Length);
            $fileStream.Close();

            $assemblyLoaded = [System.Reflection.Assembly]::Load($assemblyBytes);
            $version = $assemblyLoaded.GetName().Version
            $semVersion = -join ($version.Major, ".", $version.Minor, ".", $version.Build)
            Write-Host "Version from assembly: $semVersion" -ForegroundColor Green
        } catch {
            Write-Host "Could not read version from assembly: $($_.Exception.Message)" -ForegroundColor Yellow
            $semVersion = "3.0.1"
        }
    }
}

if ([string]::IsNullOrWhiteSpace($semVersion)) {
    $semVersion = "3.0.1"
}

$versionNode.InnerText = $semVersion
$workingPackageFile.Save((Join-Path $targetDirectory "package-v8.xml"))

$outputFileName = ($packageId + "-V8-" + $semVersion.Replace(".", "") + ".zip")
$outputPath = Join-Path $targetDirectory $outputFileName

Write-Host "Creating package: $outputFileName" -ForegroundColor Green
Write-Host "Output path: $outputPath" -ForegroundColor Green

try {
    Compress-Archive -LiteralPath $filepaths -CompressionLevel Optimal -DestinationPath $outputPath -Force
    Write-Host "Package created successfully: $outputPath" -ForegroundColor Green
} catch {
    Write-Host "Error creating package: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 